#!/bin/bash
# Validate Ansible configuration before deployment
# This checks for common configuration issues

set -e

echo "=========================================="
echo "Validating Ansible Configuration"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

# Check if we're in the right directory
if [ ! -f "main.yml" ]; then
    echo -e "${RED}✗ Error: main.yml not found. Run this from the ansible/ directory.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Directory check passed${NC}"

# Check if Ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo -e "${RED}✗ Error: ansible-playbook not found.${NC}"
    echo "  Install with: sudo apt install ansible"
    ((ERRORS++))
else
    echo -e "${GREEN}✓ Ansible is installed: $(ansible --version | head -1)${NC}"
fi

# Check if configuration file exists
if [ ! -f "group_vars/localhost.yml" ]; then
    echo -e "${RED}✗ Error: group_vars/localhost.yml not found.${NC}"
    ((ERRORS++))
else
    echo -e "${GREEN}✓ Configuration file exists${NC}"
fi

# Validate YAML syntax
echo ""
echo "Checking YAML syntax..."
for file in main.yml test.yml backup.yml update.yml group_vars/localhost.yml; do
    if [ -f "$file" ]; then
        if ansible-playbook "$file" --syntax-check &> /dev/null; then
            echo -e "${GREEN}✓ $file${NC}"
        else
            echo -e "${RED}✗ $file (syntax error)${NC}"
            ((ERRORS++))
        fi
    fi
done

# Check for role directories
echo ""
echo "Checking roles..."
for role in base-system rocm conda forge-rocm desktop-preferences; do
    if [ -d "roles/$role/tasks" ]; then
        if [ -f "roles/$role/tasks/main.yml" ]; then
            echo -e "${GREEN}✓ roles/$role${NC}"
        else
            echo -e "${YELLOW}⚠ roles/$role exists but missing tasks/main.yml${NC}"
            ((WARNINGS++))
        fi
    else
        echo -e "${RED}✗ roles/$role not found${NC}"
        ((ERRORS++))
    fi
done

# Check configuration values
echo ""
echo "Checking configuration values..."

# Extract username from config
USERNAME=$(grep "^username:" group_vars/localhost.yml | awk '{print $2}' | tr -d '"')
if [ -z "$USERNAME" ]; then
    echo -e "${YELLOW}⚠ Username not set in configuration${NC}"
    ((WARNINGS++))
elif [ "$USERNAME" = "aubreybailey" ]; then
    echo -e "${YELLOW}⚠ Username is still 'aubreybailey' - you may want to change this${NC}"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓ Username configured: $USERNAME${NC}"
fi

# Check email
EMAIL=$(grep "^git_user_email:" group_vars/localhost.yml | awk '{print $2}' | tr -d '"')
if [ -z "$EMAIL" ]; then
    echo -e "${YELLOW}⚠ Git email not set${NC}"
    ((WARNINGS++))
elif [[ "$EMAIL" == *"example.com"* ]]; then
    echo -e "${YELLOW}⚠ Git email contains 'example.com' - please update with your real email${NC}"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓ Git email configured: $EMAIL${NC}"
fi

# Check permissions
echo ""
echo "Checking file permissions..."
for script in quick-start.sh export-current-config.sh validate-config.sh; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            echo -e "${GREEN}✓ $script is executable${NC}"
        else
            echo -e "${YELLOW}⚠ $script is not executable (run: chmod +x $script)${NC}"
            ((WARNINGS++))
        fi
    fi
done

# Summary
echo ""
echo "=========================================="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ Validation Passed!${NC}"
    echo "=========================================="
    echo ""
    echo "Your configuration looks good!"
    echo ""
    echo "Next steps:"
    echo "  1. Review: vim group_vars/localhost.yml"
    echo "  2. Test: ansible-playbook test.yml"
    echo "  3. Dry run: ansible-playbook main.yml --check --ask-become-pass"
    echo "  4. Deploy: ./quick-start.sh"
    echo ""
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Validation Passed with Warnings${NC}"
    echo "=========================================="
    echo ""
    echo "Warnings: $WARNINGS"
    echo ""
    echo "You can proceed, but consider addressing the warnings above."
    echo ""
    exit 0
else
    echo -e "${RED}✗ Validation Failed${NC}"
    echo "=========================================="
    echo ""
    echo "Errors: $ERRORS"
    echo "Warnings: $WARNINGS"
    echo ""
    echo "Please fix the errors above before deploying."
    echo ""
    exit 1
fi
