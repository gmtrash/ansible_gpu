# Ansible Deployment for Ubuntu Desktop + Stable Diffusion Forge ROCm

This directory contains Ansible playbooks to automatically configure a fresh Ubuntu installation with your preferred setup, including ROCm and Stable Diffusion WebUI Forge Classic.

## Quick Start

### 1. Install Ansible on Fresh Ubuntu

```bash
sudo apt update
sudo apt install -y ansible git
```

### 2. Clone this repository

```bash
git clone <your-repo-url>
cd sd-webui-forge-classic/ansible
```

### 3. Configure your settings

Edit `group_vars/localhost.yml` to customize:
- User preferences
- Model directories
- ROCm settings
- Optional applications

### 4. Run the playbook

```bash
# Dry run (check mode)
ansible-playbook main.yml --check

# Actually apply
ansible-playbook main.yml

# Or run specific parts:
ansible-playbook main.yml --tags "rocm"
ansible-playbook main.yml --tags "forge"
```

## Playbook Structure

```
ansible/
├── README.md                    # This file
├── main.yml                     # Main playbook
├── group_vars/
│   └── localhost.yml            # Configuration variables
├── roles/
│   ├── base-system/             # Basic system packages
│   ├── rocm/                    # AMD ROCm installation
│   ├── conda/                   # Miniconda/Miniforge setup
│   ├── forge-rocm/              # SD WebUI Forge Classic
│   └── desktop-preferences/     # Optional: desktop configs
└── files/
    ├── bashrc_additions         # Shell customizations
    └── conda_init.sh            # Conda initialization
```

## What Gets Installed

### Base System (`base-system` role)
- Build essentials (gcc, make, cmake)
- Git, curl, wget
- Python 3.11 build dependencies
- System utilities (htop, vim, etc.)

### ROCm (`rocm` role)
- AMD ROCm 6.2+ repositories
- ROCm core packages
- rocm-smi and development tools
- GPU architecture detection and configuration

### Conda (`conda` role)
- Miniforge (conda-forge by default)
- Configured in ~/.bashrc
- Auto-activation setup (optional)

### SD Forge ROCm (`forge-rocm` role)
- Clones/updates SD WebUI Forge Classic repository
- Creates `forge-rocm` conda environment
- Applies ROCm patches
- Configures launch scripts
- Optionally sets up model directories

### Desktop Preferences (`desktop-preferences` role, optional)
- Custom .bashrc additions
- Git configuration
- Other dotfiles

## Available Tags

Run specific parts of the playbook using tags:

```bash
# Install only ROCm
ansible-playbook main.yml --tags rocm

# Install only SD Forge
ansible-playbook main.yml --tags forge

# Install system packages + ROCm
ansible-playbook main.yml --tags "base,rocm"

# Skip desktop preferences
ansible-playbook main.yml --skip-tags desktop
```

**All available tags:**
- `base` - Base system packages
- `rocm` - AMD ROCm installation
- `conda` - Conda/Miniforge setup
- `forge` - SD WebUI Forge Classic
- `desktop` - Desktop preferences and dotfiles

## Customization

### Variables (`group_vars/localhost.yml`)

```yaml
# User settings
username: aubreybailey
home_dir: "/home/{{ username }}"

# ROCm settings
rocm_version: "6.2"
gpu_architecture: "gfx1036"  # Auto-detected if not set

# Forge settings
forge_install_dir: "{{ home_dir }}/llm/sd-webui-forge-classic"
forge_models_dir: "{{ forge_install_dir }}/models"
forge_conda_env: "forge-rocm"

# Optional: shared model directory
# shared_models_dir: "/mnt/data/ai-models"
```

### Adding Your Own Tasks

Create new roles in `roles/` or add tasks to existing roles:

```bash
# Create a new role
ansible-galaxy init roles/my-custom-role

# Edit main.yml to include it:
# - import_role:
#     name: my-custom-role
```

## Idempotency

All tasks are idempotent - you can run the playbook multiple times safely:
- Packages only install if missing
- Config files only update if changed
- Conda environments only create if missing
- ROCm only installs if not present

## Testing

Test in a VM before running on your main system:

```bash
# Use Vagrant or a fresh Ubuntu VM
vagrant init ubuntu/jammy64
vagrant up
vagrant ssh

# Inside VM:
git clone <repo>
cd ansible
ansible-playbook main.yml
```

## Troubleshooting

### "Failed to connect to localhost"
```bash
# Ensure localhost is in /etc/hosts
echo "127.0.0.1 localhost" | sudo tee -a /etc/hosts
```

### "Permission denied"
```bash
# Run with --ask-become-pass
ansible-playbook main.yml --ask-become-pass
```

### ROCm installation fails
```bash
# Manually verify ROCm repository
sudo apt update
apt-cache search rocm

# Check Ubuntu version compatibility
lsb_release -a
```

## Export Your Current Configuration

To capture your current system state, use the included export script:

```bash
./export-current-config.sh
```

This will update `group_vars/localhost.yml` with your current settings.

## Further Reading

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html)
- [ROCm Installation Guide](https://rocmdocs.amd.com/en/latest/deploy/linux/quick_start.html)
