#!/bin/bash
# Hide VM detection from Windows guest
# Modifies VM configuration to prevent Windows from detecting virtualization
# Useful for anti-cheat software and certain applications that refuse to run in VMs

set -e

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_NC='\033[0m'

# Check for VM name argument
if [ -z "$1" ]; then
    echo -e "${COLOR_RED}Error: VM name required${COLOR_NC}"
    echo
    echo "Usage: $0 <vm-name> [--system] [--undo]"
    echo
    echo "Options:"
    echo "  --system    Use system libvirt connection (requires sudo)"
    echo "  --undo      Remove VM detection hiding (restore default)"
    echo "  (default)   Use user session connection"
    echo
    echo "Available VMs (user session):"
    virsh --connect qemu:///session list --all 2>/dev/null || echo "  None found or not running"
    echo
    echo "Available VMs (system, requires sudo):"
    sudo virsh --connect qemu:///system list --all 2>/dev/null || echo "  None found or permission denied"
    exit 1
fi

VM_NAME="$1"
VIRSH_CONNECT="qemu:///session"
UNDO_MODE=false

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --system)
            if [ "$EUID" -ne 0 ]; then
                echo -e "${COLOR_RED}Error: --system requires root privileges${COLOR_NC}"
                echo "Usage: sudo $0 <vm-name> --system"
                exit 1
            fi
            VIRSH_CONNECT="qemu:///system"
            ;;
        --undo)
            UNDO_MODE=true
            ;;
    esac
done

# Set virsh command based on connection
if [ "$VIRSH_CONNECT" = "qemu:///system" ]; then
    VIRSH="virsh --connect qemu:///system"
else
    VIRSH="virsh --connect qemu:///session"
fi

echo "Using connection: $VIRSH_CONNECT"
echo

# Check if VM exists
if ! ${VIRSH} dominfo "$VM_NAME" > /dev/null 2>&1; then
    echo -e "${COLOR_RED}Error: VM '$VM_NAME' not found on $VIRSH_CONNECT${COLOR_NC}"
    echo
    echo "Available VMs:"
    ${VIRSH} list --all
    exit 1
fi

echo "=== Hide VM Detection for: $VM_NAME ==="
echo

# Check current VM state
vm_state=$(${VIRSH} domstate "$VM_NAME")
if [ "$vm_state" = "running" ]; then
    echo -e "${COLOR_YELLOW}Warning: VM is currently running${COLOR_NC}"
    echo "The VM must be shut down to modify configuration."
    echo
    read -p "Shut down VM now? (y/n): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Shutting down VM..."
        ${VIRSH} shutdown "$VM_NAME"
        echo "Waiting for shutdown..."
        sleep 5

        # Wait up to 30 seconds for shutdown
        for i in {1..6}; do
            vm_state=$(${VIRSH} domstate "$VM_NAME")
            if [ "$vm_state" != "running" ]; then
                break
            fi
            sleep 5
        done
    else
        echo "Please shut down the VM and run this script again."
        exit 1
    fi
fi

# Backup current VM configuration
echo "Creating backup of VM configuration..."
BACKUP_FILE="$VM_NAME-backup-$(date +%Y%m%d-%H%M%S).xml"
${VIRSH} dumpxml "$VM_NAME" > "$BACKUP_FILE"
echo -e "${COLOR_GREEN}Backup saved: $BACKUP_FILE${COLOR_NC}"
echo

# Get current XML
TEMP_XML=$(mktemp)
${VIRSH} dumpxml "$VM_NAME" > "$TEMP_XML"

if [ "$UNDO_MODE" = true ]; then
    echo "=== Restoring Default VM Detection Settings ==="
    echo
    echo "This will:"
    echo "  - Remove hypervisor hiding features"
    echo "  - Remove custom SMBIOS information"
    echo "  - Keep host-passthrough CPU mode"
    echo
    read -p "Restore default settings? (y/n): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        rm -f "$TEMP_XML"
        exit 0
    fi

    # Remove kvm hidden state if present
    if grep -q "kvm" "$TEMP_XML" && grep -q "hidden" "$TEMP_XML"; then
        echo "Removing KVM hidden state..."
        sed -i '/<kvm>/,/<\/kvm>/d' "$TEMP_XML"
    fi

    # Remove custom SMBIOS if present
    if grep -q "<sysinfo" "$TEMP_XML"; then
        echo "Removing custom SMBIOS information..."
        sed -i '/<sysinfo/,/<\/sysinfo>/d' "$TEMP_XML"
    fi

    # Remove os sysinfo reference
    sed -i '/<smbios mode/d' "$TEMP_XML"

    echo
    echo -e "${COLOR_GREEN}Default settings restored${COLOR_NC}"

else
    echo "=== VM Detection Hiding Configuration ==="
    echo
    echo "Choose hiding level:"
    echo
    echo "  1) BASIC - Hide KVM, spoof SMBIOS (keeps Hyper-V features)"
    echo "     - Task Manager will still show 'Virtual Processor'"
    echo "     - Better performance (Hyper-V enlightenments enabled)"
    echo "     - Good for most games and applications"
    echo
    echo "  2) AGGRESSIVE - Disable all Hyper-V features"
    echo "     - Task Manager shows normal processor"
    echo "     - Harder to detect, but may reduce VM performance"
    echo "     - Best for anti-cheat and strict VM detection"
    echo
    echo "  3) BALANCED - Hide vendor_id, keep performance features"
    echo "     - Hides Hyper-V vendor string"
    echo "     - Keeps most performance features"
    echo "     - Good compromise"
    echo
    read -p "Select mode (1/2/3): " -r MODE_CHOICE

    if [[ ! $MODE_CHOICE =~ ^[123]$ ]]; then
        echo "Invalid choice. Aborted."
        rm -f "$TEMP_XML"
        exit 0
    fi

    # 1. Add KVM hidden state (hide from guest)
    echo
    echo "1. Adding KVM hidden state..."

    # Check if kvm features already exist
    if grep -q "<kvm>" "$TEMP_XML"; then
        echo "  KVM features already present, updating..."
        # Check if hidden already exists
        if grep -q "hidden" "$TEMP_XML"; then
            sed -i 's/<hidden state=.*\/>/<hidden state="on"\/>/' "$TEMP_XML"
        else
            # Add hidden within existing kvm block
            sed -i '/<kvm>/a\    <hidden state="on"/>' "$TEMP_XML"
        fi
    else
        # Add entire kvm block after hyperv features
        if grep -q "<hyperv" "$TEMP_XML"; then
            sed -i '/<\/hyperv>/a\    <kvm>\n      <hidden state="on"/>\n    </kvm>' "$TEMP_XML"
        else
            # Add after features opening tag
            sed -i '/<features>/a\    <kvm>\n      <hidden state="on"/>\n    </kvm>' "$TEMP_XML"
        fi
    fi
    echo -e "  ${COLOR_GREEN}✓ KVM hidden state enabled${COLOR_NC}"

    # 1.5. Handle Hyper-V features based on mode
    echo
    if [ "$MODE_CHOICE" = "2" ]; then
        echo "1.5. Removing Hyper-V enlightenments (AGGRESSIVE mode)..."
        # Remove entire hyperv block
        sed -i '/<hyperv/,/<\/hyperv>/d' "$TEMP_XML"

        # Remove hypervclock timer (dead giveaway of Hyper-V)
        sed -i '/<timer name=.hypervclock./d' "$TEMP_XML"

        echo -e "  ${COLOR_GREEN}✓ Hyper-V features removed${COLOR_NC}"
        echo -e "  ${COLOR_GREEN}✓ Hyper-V clock timer removed${COLOR_NC}"
        echo -e "  ${COLOR_YELLOW}⚠ VM performance may be reduced${COLOR_NC}"
    elif [ "$MODE_CHOICE" = "3" ]; then
        echo "1.5. Adding Hyper-V vendor_id hiding (BALANCED mode)..."
        # Add vendor_id spoof to hyperv section
        if grep -q "<hyperv" "$TEMP_XML"; then
            # Check if vendor_id already exists
            if grep -q "vendor_id" "$TEMP_XML"; then
                sed -i 's/<vendor_id.*/<vendor_id state="on" value="AuthenticAMD"\/>/' "$TEMP_XML"
            else
                # Add vendor_id after opening hyperv tag
                sed -i '/<hyperv mode/a\      <vendor_id state="on" value="AuthenticAMD"\/>' "$TEMP_XML"
            fi
            echo -e "  ${COLOR_GREEN}✓ Hyper-V vendor_id spoofed to AuthenticAMD${COLOR_NC}"
            echo -e "  ${COLOR_GREEN}✓ Performance features retained${COLOR_NC}"
        fi
    else
        echo "1.5. Keeping Hyper-V enlightenments (BASIC mode)..."
        echo -e "  ${COLOR_GREEN}✓ Performance features retained${COLOR_NC}"
        echo -e "  ${COLOR_YELLOW}⚠ Task Manager may still show 'Virtual Processor'${COLOR_NC}"
    fi

    # 2. Add SMBIOS spoofing
    echo
    echo "2. Adding SMBIOS spoofing..."

    # Generate random serial numbers and UUIDs for authenticity
    RANDOM_SERIAL=$(head -c 12 /dev/urandom | base64 | tr -dc 'A-Z0-9' | head -c 12)
    RANDOM_VERSION="1.$((RANDOM % 10)).$((RANDOM % 100))"

    # Extract existing VM UUID to avoid mismatch
    EXISTING_UUID=$(grep -oP '<uuid>\K[^<]+' "$TEMP_XML")

    # Create SMBIOS section
    SYSINFO_XML="  <sysinfo type='smbios'>
    <bios>
      <entry name='vendor'>American Megatrends Inc.</entry>
      <entry name='version'>$RANDOM_VERSION</entry>
      <entry name='date'>$(date +%m/%d/%Y)</entry>
    </bios>
    <system>
      <entry name='manufacturer'>ASUS</entry>
      <entry name='product'>ROG STRIX X670E-E GAMING WIFI</entry>
      <entry name='version'>Rev 1.xx</entry>
      <entry name='serial'>$RANDOM_SERIAL</entry>
      <entry name='uuid'>$EXISTING_UUID</entry>
      <entry name='family'>ROG</entry>
    </system>
    <baseBoard>
      <entry name='manufacturer'>ASUS</entry>
      <entry name='product'>ROG STRIX X670E-E GAMING WIFI</entry>
      <entry name='version'>Rev 1.xx</entry>
      <entry name='serial'>$RANDOM_SERIAL</entry>
    </baseBoard>
    <chassis>
      <entry name='manufacturer'>ASUS</entry>
      <entry name='version'>Default string</entry>
      <entry name='serial'>$RANDOM_SERIAL</entry>
      <entry name='asset'>Default string</entry>
      <entry name='sku'>Default string</entry>
    </chassis>
  </sysinfo>"

    # Remove existing sysinfo if present
    if grep -q "<sysinfo" "$TEMP_XML"; then
        echo "  Removing existing SMBIOS info..."
        sed -i '/<sysinfo/,/<\/sysinfo>/d' "$TEMP_XML"
    fi

    # Add sysinfo after domain opening tag
    awk -v sysinfo="$SYSINFO_XML" '/<domain/ {print; print sysinfo; next} 1' "$TEMP_XML" > "${TEMP_XML}.tmp"
    mv "${TEMP_XML}.tmp" "$TEMP_XML"

    # Add smbios mode to os section if not present
    if ! grep -q "smbios mode" "$TEMP_XML"; then
        sed -i '/<os /a\    <smbios mode="sysinfo"/>' "$TEMP_XML"
    fi

    echo -e "  ${COLOR_GREEN}✓ SMBIOS spoofing configured${COLOR_NC}"
    echo "    - Manufacturer: ASUS"
    echo "    - Product: ROG STRIX X670E-E GAMING WIFI"
    echo "    - Serial: $RANDOM_SERIAL"

    # 2.5. Add CPU feature hiding
    echo
    echo "2.5. Adding advanced CPU feature hiding..."

    # Add qemu:commandline namespace if not present
    if ! grep -q "xmlns:qemu" "$TEMP_XML"; then
        # Use awk to add the namespace attribute to the domain tag
        awk '
        /<domain type=/ && !done {
            sub(/>/, " xmlns:qemu=\"http://libvirt.org/schemas/domain/qemu/1.0\">")
            done=1
        }
        {print}
        ' "$TEMP_XML" > "${TEMP_XML}.tmp"
        mv "${TEMP_XML}.tmp" "$TEMP_XML"
    fi

    # Remove existing qemu:commandline if present
    if grep -q "<qemu:commandline>" "$TEMP_XML"; then
        sed -i '/<qemu:commandline>/,/<\/qemu:commandline>/d' "$TEMP_XML"
    fi

    # Add CPU args to hide KVM leaf and set vendor_id
    # Insert qemu:commandline before closing </domain> tag
    awk '
    /<\/domain>/ && !done {
        print "  <qemu:commandline>"
        print "    <qemu:arg value=\"-cpu\"/>"
        print "    <qemu:arg value=\"host,kvm=off,hv_vendor_id=AuthenticAMD,hv_time\"/>"
        print "  </qemu:commandline>"
        done=1
    }
    {print}
    ' "$TEMP_XML" > "${TEMP_XML}.tmp"
    mv "${TEMP_XML}.tmp" "$TEMP_XML"

    echo -e "  ${COLOR_GREEN}✓ CPU args added (kvm=off, vendor_id=AuthenticAMD)${COLOR_NC}"

    # 3. Add CPU feature to hide hypervisor bit
    echo
    echo "3. Hiding hypervisor CPUID bit..."

    # Check if CPU definition has features
    if grep -q "<cpu mode='host-passthrough'" "$TEMP_XML"; then
        # Check if it's a self-closing tag
        if grep -q "<cpu mode='host-passthrough'.*\/>" "$TEMP_XML"; then
            # Convert self-closing tag to open tag and add feature
            sed -i "s|<cpu mode='host-passthrough' check='none' migratable='on'/>|<cpu mode='host-passthrough' check='none' migratable='on'>\n    <feature policy='disable' name='hypervisor'/>\n  </cpu>|" "$TEMP_XML"
            echo -e "  ${COLOR_GREEN}✓ CPU hypervisor bit disabled${COLOR_NC}"
        else
            # CPU tag already has content, add feature if not present
            if ! grep -q "feature.*hypervisor" "$TEMP_XML"; then
                sed -i "/<cpu mode='host-passthrough'/a\    <feature policy='disable' name='hypervisor'/>" "$TEMP_XML"
                echo -e "  ${COLOR_GREEN}✓ CPU hypervisor bit disabled${COLOR_NC}"
            else
                echo -e "  ${COLOR_GREEN}✓ CPU hypervisor bit already disabled${COLOR_NC}"
            fi
        fi
    else
        echo -e "  ${COLOR_YELLOW}⚠ CPU mode is not host-passthrough${COLOR_NC}"
    fi

    echo -e "  ${COLOR_GREEN}✓ CPU mode: host-passthrough${COLOR_NC}"

    echo
    echo -e "${COLOR_GREEN}VM detection hiding configured${COLOR_NC}"
fi

# Apply changes
echo
echo "Applying configuration changes..."
${VIRSH} define "$TEMP_XML"
echo -e "${COLOR_GREEN}✓ Configuration applied${COLOR_NC}"

# Cleanup
rm -f "$TEMP_XML"

echo
echo "=== Configuration Complete ==="
echo
echo -e "${COLOR_GREEN}VM detection hiding has been applied to: $VM_NAME${COLOR_NC}"
echo

if [ "$UNDO_MODE" != true ]; then
    case $MODE_CHOICE in
        1)
            echo "Mode: BASIC (Hyper-V enabled)"
            echo "  1. KVM signature hidden from guest"
            echo "  2. SMBIOS spoofed to look like ASUS motherboard"
            echo "  3. Hyper-V enlightenments ENABLED (better performance)"
            echo
            echo -e "${COLOR_YELLOW}Note: Task Manager will still show 'Virtual Processor'${COLOR_NC}"
            ;;
        2)
            echo "Mode: AGGRESSIVE (Hyper-V disabled)"
            echo "  1. KVM signature hidden from guest"
            echo "  2. SMBIOS spoofed to look like ASUS motherboard"
            echo "  3. Hyper-V enlightenments DISABLED (harder to detect)"
            echo
            echo -e "${COLOR_GREEN}Note: Task Manager should show normal processor${COLOR_NC}"
            ;;
        3)
            echo "Mode: BALANCED (Hyper-V vendor_id hidden)"
            echo "  1. KVM signature hidden from guest"
            echo "  2. SMBIOS spoofed to look like ASUS motherboard"
            echo "  3. Hyper-V vendor_id spoofed to AuthenticAMD"
            echo "  4. Hyper-V performance features retained"
            echo
            echo -e "${COLOR_BLUE}Note: Good balance between performance and detection${COLOR_NC}"
            ;;
    esac
fi
echo
echo "Next steps:"
echo "  1. Start the VM: virsh start $VM_NAME"
echo "     Or use virt-manager GUI"
echo
echo "  2. In Windows, verify changes:"
echo "     - Open System Information (msinfo32)"
echo "     - Check System Manufacturer/Model"
echo "     - Run: wmic bios get manufacturer,version"
echo
echo "  3. Test detection tools:"
echo "     - Pafish (detects VMs): github.com/a0rtega/pafish"
echo "     - Check CPUID: download CPUID or CPU-Z"
echo
echo "To undo these changes:"
echo "  $0 $VM_NAME --undo"
echo
echo "Backup saved at: $BACKUP_FILE"
echo "To restore: virsh define $BACKUP_FILE"
echo
