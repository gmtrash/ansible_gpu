# Ansible Usage Guide

Complete guide for using these Ansible playbooks to deploy your Ubuntu + SD Forge ROCm setup.

## Table of Contents

1. [First Time Setup](#first-time-setup)
2. [Basic Usage](#basic-usage)
3. [Configuration](#configuration)
4. [Running Playbooks](#running-playbooks)
5. [Common Scenarios](#common-scenarios)
6. [Troubleshooting](#troubleshooting)

## First Time Setup

### On a Fresh Ubuntu Install

1. **Install Ansible and Git:**
   ```bash
   sudo apt update
   sudo apt install -y ansible git
   ```

2. **Clone the repository:**
   ```bash
   cd ~
   git clone <your-repo-url>
   cd sd-webui-forge-classic/ansible
   ```

3. **Review configuration:**
   ```bash
   # Edit variables to match your preferences
   vim group_vars/localhost.yml

   # At minimum, update:
   # - username (should be your username)
   # - git_user_email (your actual email)
   ```

4. **Run quick start:**
   ```bash
   ./quick-start.sh
   ```

### On Your Existing System (Export Current Config)

If you want to capture your current configuration:

```bash
cd ansible
./export-current-config.sh

# Review the exported config
cat group_vars/localhost.yml.exported

# Copy relevant parts to your actual config
vim group_vars/localhost.yml
```

## Basic Usage

### Full System Deployment

Deploy everything (base packages, ROCm, conda, SD Forge, desktop prefs):

```bash
ansible-playbook main.yml --ask-become-pass
```

### Dry Run (Check Mode)

See what would change without making changes:

```bash
ansible-playbook main.yml --check --ask-become-pass
```

### Partial Deployment with Tags

Install only specific components:

```bash
# Only ROCm
ansible-playbook main.yml --tags rocm --ask-become-pass

# ROCm + SD Forge
ansible-playbook main.yml --tags "rocm,forge" --ask-become-pass

# Everything except desktop preferences
ansible-playbook main.yml --skip-tags desktop --ask-become-pass
```

## Configuration

### Main Configuration File

All settings are in `group_vars/localhost.yml`:

```yaml
# User settings
username: aubreybailey         # Your Ubuntu username
git_user_name: "Your Name"
git_user_email: "you@example.com"

# ROCm settings
rocm_version: "6.2"           # ROCm version to install
gpu_architecture: "gfx1036"   # Your GPU architecture

# Forge settings
forge_install_dir: "{{ home_dir }}/llm/sd-webui-forge-classic"
forge_conda_env: "forge-rocm"

# Optional: shared models
# shared_models_dir: "/mnt/data/ai-models"
```

### Important Variables

**ROCm Configuration:**
- `rocm_version`: ROCm version (6.2, 6.1, etc.)
- `gpu_architecture`: Your GPU's gfx target (gfx1036, gfx1030, etc.)
- `hsa_override_gfx`: HSA override for newer GPUs

**Forge Configuration:**
- `forge_install_dir`: Where to install SD Forge
- `forge_conda_env`: Name of conda environment
- `forge_gpu_mode`: Performance profile (integrated, dedicated-low, dedicated-high)
- `forge_commandline_args`: WebUI launch arguments

**Desktop Preferences:**
- `configure_desktop`: Enable/disable desktop customizations
- `custom_bash_aliases`: List of bash aliases to add
- `custom_bash_exports`: Environment variables to export

## Running Playbooks

### Available Tags

| Tag | Description | Use Case |
|-----|-------------|----------|
| `base` | Base system packages | Fresh install or missing packages |
| `rocm` | AMD ROCm installation | GPU driver setup |
| `conda` | Conda/Miniforge | Python environment management |
| `forge` | SD Forge ROCm | Install/update Stable Diffusion |
| `desktop` | Desktop preferences | Dotfiles, aliases, configs |

### Common Commands

**Install everything:**
```bash
ansible-playbook main.yml --ask-become-pass
```

**Install only SD Forge (assumes ROCm/conda exist):**
```bash
ansible-playbook main.yml --tags forge --ask-become-pass
```

**Update SD Forge to latest:**
```bash
ansible-playbook main.yml --tags forge --ask-become-pass
```

**Reinstall ROCm:**
```bash
# First, manually remove ROCm:
sudo apt remove --purge rocm-*
sudo apt autoremove

# Then reinstall via Ansible:
ansible-playbook main.yml --tags rocm --ask-become-pass
```

**Apply desktop preferences only:**
```bash
ansible-playbook main.yml --tags desktop
```

## Common Scenarios

### Scenario 1: Fresh Ubuntu Install

You've just installed Ubuntu and want everything set up:

```bash
# 1. Install Ansible
sudo apt update && sudo apt install -y ansible git

# 2. Clone repo
git clone <your-repo-url> ~/sd-webui-forge-classic
cd ~/sd-webui-forge-classic/ansible

# 3. Edit config (update email, username, etc.)
vim group_vars/localhost.yml

# 4. Run full deployment
./quick-start.sh
# Choose option 1 (Full deployment)

# 5. Reboot
sudo reboot

# 6. After reboot, verify
rocm-smi --showproductname
conda activate forge-rocm
cd ~/llm/sd-webui-forge-classic
./launch-rocm.sh
```

### Scenario 2: Update Existing Installation

You've already deployed once and want to update:

```bash
cd ~/sd-webui-forge-classic/ansible

# Pull latest changes
git pull

# Update SD Forge only
ansible-playbook main.yml --tags forge --ask-become-pass
```

### Scenario 3: Just Install ROCm

You only want ROCm, not SD Forge:

```bash
ansible-playbook main.yml --tags "base,rocm" --ask-become-pass
sudo reboot
```

### Scenario 4: Apply Only Your Dotfiles

You've updated your preferences and want to sync them:

```bash
# Edit your preferences
vim group_vars/localhost.yml

# Apply only desktop preferences (no sudo needed)
ansible-playbook main.yml --tags desktop
```

### Scenario 5: Use Shared Model Directory

You have models in `/mnt/data/ai-models` and want Forge to use them:

```yaml
# In group_vars/localhost.yml:
shared_models_dir: "/mnt/data/ai-models"
shared_models_types:
  - Stable-diffusion
  - Lora
  - VAE
  - ControlNet
```

```bash
# Apply Forge role to create symlinks
ansible-playbook main.yml --tags forge --ask-become-pass
```

## Troubleshooting

### "Failed to connect to localhost"

**Problem:** Ansible can't connect to localhost.

**Solution:**
```bash
# Check /etc/hosts
cat /etc/hosts | grep localhost

# If missing, add it:
echo "127.0.0.1 localhost" | sudo tee -a /etc/hosts
```

### "Permission denied" or sudo errors

**Problem:** Playbook fails with permission errors.

**Solution:**
```bash
# Run with --ask-become-pass to enter sudo password
ansible-playbook main.yml --ask-become-pass

# Or ensure your user has passwordless sudo:
echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USER
sudo chmod 0440 /etc/sudoers.d/$USER
```

### ROCm not detected after installation

**Problem:** `rocm-smi` command not found after playbook runs.

**Solution:**
```bash
# Source the environment
source /etc/profile.d/rocm.sh

# Or reboot (recommended)
sudo reboot

# Verify
rocm-smi --version
```

### Conda environment creation fails

**Problem:** Forge conda environment fails to create.

**Solution:**
```bash
# Ensure environment-forge-rocm.yml exists
ls -la ~/llm/sd-webui-forge-classic/environment-forge-rocm.yml

# Manually create if needed
conda env create -f ~/llm/sd-webui-forge-classic/environment-forge-rocm.yml

# Or remove and recreate
conda env remove -n forge-rocm
ansible-playbook main.yml --tags conda,forge --ask-become-pass
```

### PyTorch doesn't detect ROCm

**Problem:** `torch.cuda.is_available()` returns False.

**Solution:**
```bash
# Check ROCm is working
rocm-smi

# Reinstall PyTorch in conda environment
conda activate forge-rocm
pip install --force-reinstall torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/rocm6.2

# Verify
python -c "import torch; print(torch.cuda.is_available())"
```

### Want to skip certain roles

**Problem:** Want to run playbook but skip some parts.

**Solution:**
```bash
# Skip desktop preferences
ansible-playbook main.yml --skip-tags desktop --ask-become-pass

# Skip ROCm (if already installed)
ansible-playbook main.yml --skip-tags rocm --ask-become-pass
```

## Advanced Usage

### Testing in a VM

Before running on your main system, test in a VM:

```bash
# Using Vagrant
vagrant init ubuntu/jammy64
vagrant up
vagrant ssh

# Inside VM, run deployment
cd /vagrant/ansible
ansible-playbook main.yml --ask-become-pass
```

### Custom Roles

Add your own roles:

```bash
# Create a new role
ansible-galaxy init roles/my-custom-role

# Edit the role's tasks
vim roles/my-custom-role/tasks/main.yml

# Add to main.yml
# - import_role:
#     name: my-custom-role
#   tags: custom
```

### Encrypting Sensitive Data

Use Ansible Vault for sensitive data:

```bash
# Create encrypted secrets file
ansible-vault create group_vars/secrets.yml

# Add to .gitignore
echo "group_vars/secrets.yml" >> .gitignore

# Run playbook with vault
ansible-playbook main.yml --ask-vault-pass
```

## Verification Commands

After deployment, verify everything works:

```bash
# System info
lsb_release -a
uname -r

# ROCm
rocm-smi --showproductname
rocminfo | grep "Name:"

# Conda
conda --version
conda env list

# SD Forge environment
conda activate forge-rocm
python -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'ROCm: {torch.cuda.is_available()}')"

# Launch Forge
cd ~/llm/sd-webui-forge-classic
./launch-rocm.sh
```

## Getting Help

1. **Check logs:** Look at ansible output for specific errors
2. **Dry run:** Use `--check` to see what would change
3. **Verbose mode:** Add `-v`, `-vv`, or `-vvv` for more details
4. **Deployment log:** Check `~/.ansible-deployment-log`
5. **Individual roles:** Test roles individually with tags

## Further Reading

- Main README: `README.md`
- ROCm Setup: `../ROCM_SETUP.md`
- Ansible Docs: https://docs.ansible.com/
