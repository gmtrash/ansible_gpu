# Ansible Deployment System - Complete Summary

## 🎉 What You've Got

A complete, production-ready Ansible deployment system for your Ubuntu desktop + SD Forge ROCm setup!

### 📦 Complete File Structure

```
ansible/
├── 📘 Documentation
│   ├── GETTING-STARTED.md          # Start here - quick getting started guide
│   ├── QUICKREF.md                 # One-page command reference
│   ├── README.md                   # Complete documentation
│   ├── USAGE.md                    # Detailed usage scenarios
│   └── SUMMARY.md                  # This file
│
├── 🎯 Main Playbooks
│   ├── main.yml                    # Main deployment playbook
│   ├── test.yml                    # Test and verify system
│   ├── update.yml                  # Quick update SD Forge
│   ├── backup.yml                  # Backup configs and dotfiles
│   └── install-systemd-service.yml # Install systemd service (optional)
│
├── 🛠️ Helper Scripts
│   ├── quick-start.sh              # Interactive deployment wizard
│   ├── export-current-config.sh    # Export current system config
│   └── validate-config.sh          # Validate configuration
│
├── ⚙️ Configuration
│   ├── ansible.cfg                 # Ansible settings
│   ├── inventory.ini               # Host inventory (localhost)
│   └── group_vars/
│       └── localhost.yml           # ⭐ MAIN CONFIG - Edit this!
│
├── 🎭 Roles (5 total)
│   ├── base-system/               # System packages & setup
│   ├── rocm/                      # AMD ROCm GPU drivers
│   ├── conda/                     # Conda/Miniforge
│   ├── forge-rocm/                # SD Forge installation
│   └── desktop-preferences/       # Dotfiles & customization
│
├── 📋 Templates
│   └── templates/
│       └── forge-webui.service.j2  # Systemd service template
│
└── .gitignore                     # Git ignore rules
```

## 🚀 Quick Start (3 Commands)

```bash
# 1. Configure
cd ~/llm/sd-webui-forge-classic/ansible
vim group_vars/localhost.yml  # Update username, email

# 2. Deploy
./quick-start.sh

# 3. Reboot and enjoy!
sudo reboot
```

## 📚 Documentation Guide

| Document | When to Use |
|----------|-------------|
| **GETTING-STARTED.md** | 📍 **START HERE** - First time setup |
| **QUICKREF.md** | Quick command reference |
| **README.md** | Learn the system architecture |
| **USAGE.md** | Detailed how-to guide |
| **SUMMARY.md** | This overview (you are here) |

## 🎯 Main Playbooks Explained

### 1. `main.yml` - Full Deployment

**What it does:**
- Installs base system packages
- Installs and configures AMD ROCm
- Installs Conda/Miniforge
- Installs SD Forge ROCm
- Applies your desktop preferences

**Usage:**
```bash
# Full deployment
ansible-playbook main.yml --ask-become-pass

# Dry run (no changes)
ansible-playbook main.yml --check --ask-become-pass

# Specific components only
ansible-playbook main.yml --tags rocm --ask-become-pass
```

**Available tags:**
- `base` - Base system packages
- `rocm` - AMD ROCm
- `conda` - Conda installation
- `forge` - SD Forge
- `desktop` - Desktop preferences

### 2. `test.yml` - System Verification

**What it does:**
- Checks if components are installed
- Verifies ROCm GPU detection
- Tests PyTorch ROCm
- Displays configuration summary

**Usage:**
```bash
ansible-playbook test.yml
```

No sudo needed, safe to run anytime!

### 3. `update.yml` - Quick Update

**What it does:**
- Updates SD Forge to latest
- Updates conda environment
- Re-applies ROCm patches

**Usage:**
```bash
ansible-playbook update.yml
```

Perfect for keeping Forge up to date!

### 4. `backup.yml` - Backup Configs

**What it does:**
- Backs up dotfiles (.bashrc, .vimrc, etc.)
- Backs up Forge configs
- Exports conda environment
- Creates timestamped archive

**Usage:**
```bash
ansible-playbook backup.yml
```

### 5. `install-systemd-service.yml` - Auto-Start (Optional)

**What it does:**
- Installs systemd service for Forge
- Enables auto-start on boot
- Provides service management commands

**Usage:**
```bash
ansible-playbook install-systemd-service.yml --ask-become-pass
```

## 🎭 Roles Explained

### Role 1: `base-system`
**Purpose:** Install system packages and prepare environment

**What it installs:**
- Build tools (gcc, make, cmake)
- Python development packages
- Utilities (htop, vim, git, etc.)
- Creates necessary directories
- Adds user to `video` and `render` groups

### Role 2: `rocm`
**Purpose:** Install and configure AMD ROCm

**What it does:**
- Adds ROCm repositories
- Installs ROCm packages
- Configures environment variables
- Detects GPU architecture
- Sets up ROCm PATH

**After this role:** You can use `rocm-smi`

### Role 3: `conda`
**Purpose:** Install Conda/Miniforge

**What it does:**
- Downloads and installs Miniforge
- Initializes conda for bash
- Configures auto-activation settings
- Updates to latest version

**After this role:** You can use `conda`

### Role 4: `forge-rocm`
**Purpose:** Install SD Forge with ROCm support

**What it does:**
- Clones Forge repository
- Creates `forge-rocm` conda environment
- Applies ROCm patches
- Creates launch scripts
- Sets up model directories
- Creates desktop launcher

**After this role:** You can launch Forge with `forge-launch`

### Role 5: `desktop-preferences`
**Purpose:** Apply your personal configurations

**What it does:**
- Configures git (name, email)
- Adds custom bash aliases
- Sets environment variables
- Creates vim/tmux configs
- Adds utility scripts to ~/bin

**Customizable via:** `group_vars/localhost.yml`

## ⚙️ Configuration Guide

### Main Configuration File

**Location:** `group_vars/localhost.yml`

**Key sections:**

```yaml
# 1. User Configuration (REQUIRED)
username: aubreybailey                    # ← Change this
git_user_name: "Your Name"               # ← Change this
git_user_email: "you@example.com"        # ← Change this

# 2. ROCm Configuration
rocm_version: "6.2"
gpu_architecture: "gfx1036"              # Auto-detected if blank

# 3. Forge Settings
forge_install_dir: "~/llm/sd-webui-forge-classic"
forge_conda_env: "forge-rocm"
forge_gpu_mode: "integrated"             # or "dedicated-low", "dedicated-high"

# 4. Optional: Shared Models
# shared_models_dir: "/mnt/data/ai-models"

# 5. Desktop Customization
custom_bash_aliases:
  - alias gpu='rocm-smi'
  - alias forge='cd ~/llm/sd-webui-forge-classic'
```

## 🛠️ Helper Scripts

### `quick-start.sh` - Interactive Wizard

**Purpose:** Guided deployment for beginners

**Features:**
- Checks prerequisites
- Interactive menu
- Options for full/partial deployment
- Helpful prompts and confirmations

**Usage:**
```bash
./quick-start.sh
```

### `export-current-config.sh` - Export Config

**Purpose:** Capture your current system configuration

**What it exports:**
- Current username and home directory
- Installed ROCm version
- GPU architecture
- Conda installation path
- Git configuration

**Usage:**
```bash
./export-current-config.sh
cat group_vars/localhost.yml.exported
```

### `validate-config.sh` - Validation

**Purpose:** Check configuration before deploying

**What it checks:**
- Ansible installation
- YAML syntax
- Role directories
- Configuration values
- File permissions

**Usage:**
```bash
./validate-config.sh
```

## 🎯 Common Workflows

### Workflow 1: Fresh Ubuntu Install

```bash
# 1. Install prerequisites
sudo apt update && sudo apt install -y ansible git

# 2. Clone repository
git clone <repo-url> ~/sd-webui-forge-classic
cd ~/sd-webui-forge-classic/ansible

# 3. Configure
vim group_vars/localhost.yml

# 4. Deploy
./quick-start.sh

# 5. Reboot
sudo reboot

# 6. Launch
forge-launch
```

### Workflow 2: Update Everything

```bash
cd ~/sd-webui-forge-classic/ansible
git pull
ansible-playbook main.yml --ask-become-pass
```

### Workflow 3: Update Only SD Forge

```bash
cd ~/sd-webui-forge-classic/ansible
ansible-playbook update.yml
```

### Workflow 4: Backup Before Changes

```bash
cd ~/sd-webui-forge-classic/ansible
ansible-playbook backup.yml
# Then make changes
ansible-playbook main.yml --ask-become-pass
```

### Workflow 5: Test Configuration

```bash
cd ~/sd-webui-forge-classic/ansible
ansible-playbook test.yml
```

## 📦 What Gets Installed

### System Packages
- build-essential, gcc, g++, make, cmake
- Python 3.11 development packages
- Git, curl, wget, vim, htop, tmux
- And more (customizable)

### ROCm
- ROCm 6.2+ core packages
- rocm-smi, rocminfo
- HIP runtime
- GPU drivers

### Conda
- Miniforge3 (conda-forge by default)
- Configured and initialized

### SD Forge
- Latest Classic branch
- Forge-rocm conda environment
- PyTorch 2.5.1+rocm6.2
- All dependencies from environment-forge-rocm.yml
- ROCm patches applied

### Desktop Configs
- Custom bash aliases and exports
- Git configuration
- Vim and tmux configs
- Utility scripts in ~/bin

## 🎮 Commands Added to Your Shell

After deployment, these commands are available:

```bash
# Aliases from desktop-preferences role
ll                  # Detailed file listing
gpu                 # Run rocm-smi
forge               # cd to forge and activate conda
forge-launch        # Launch Forge WebUI
rocm-check          # Check ROCm status and GPU
torch-check         # Verify PyTorch ROCm
gpu-monitor         # Watch GPU usage in real-time
conda-info          # List conda environments
```

## 🔍 Verification Commands

After deployment, verify everything works:

```bash
# 1. Check OS and kernel
lsb_release -a
uname -r

# 2. Verify ROCm
rocm-smi --showproductname
rocminfo | grep "Name:"

# 3. Check conda
conda --version
conda env list

# 4. Test PyTorch ROCm
conda activate forge-rocm
python -c "import torch; print(f'PyTorch {torch.__version__}'); print(f'ROCm: {torch.cuda.is_available()}')"

# 5. Check deployment log
cat ~/.ansible-deployment-log

# 6. Launch Forge
forge-launch
```

## 🎨 Customization Examples

### Add More System Packages

```yaml
# In group_vars/localhost.yml:
additional_apt_packages:
  - neofetch
  - ffmpeg
  - imagemagick
  - your-package-here
```

### Add Custom Bash Aliases

```yaml
custom_bash_aliases:
  - alias upd='sudo apt update && sudo apt upgrade'
  - alias ports='netstat -tulanp'
  - alias myalias='your command here'
```

### Set Environment Variables

```yaml
custom_bash_exports:
  - export EDITOR=vim
  - export MY_VAR=value
```

### Use Shared Model Directory

```yaml
shared_models_dir: "/mnt/data/ai-models"
shared_models_types:
  - Stable-diffusion
  - Lora
  - VAE
  - ControlNet
  - ESRGAN
```

## 🔄 Update and Maintenance

### Keep Forge Updated

```bash
# Quick update
ansible-playbook update.yml

# Or full re-deployment
ansible-playbook main.yml --tags forge --ask-become-pass
```

### Backup Before Changes

```bash
ansible-playbook backup.yml
```

### Revert to Previous Version

```bash
# Restore from backup
cd ~/ansible-backups
ls  # Find your backup
tar -xzf backup-YYYYMMDD-HHMMSS.tar.gz
# Copy files back manually as needed
```

## 🐛 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Permission denied | Add `--ask-become-pass` |
| YAML syntax error | Run `validate-config.sh` |
| ROCm not detected | Reboot after ROCm installation |
| Conda not found | Source conda: `source ~/miniforge3/etc/profile.d/conda.sh` |
| PyTorch no GPU | Check `rocm-smi` works first |

### Getting Help

1. **Read the docs:** Check USAGE.md for detailed scenarios
2. **Test first:** Run `ansible-playbook test.yml`
3. **Validate:** Run `./validate-config.sh`
4. **Dry run:** Use `--check` flag
5. **Verbose:** Add `-v`, `-vv`, or `-vvv` for details

## 🎓 Learning Resources

### Ansible Basics

- **Playbook:** YAML file defining tasks
- **Role:** Reusable group of tasks
- **Task:** Single operation (install package, copy file, etc.)
- **Tag:** Label to run specific parts
- **Idempotent:** Safe to run multiple times

### Useful Ansible Commands

```bash
# Check syntax
ansible-playbook main.yml --syntax-check

# Dry run
ansible-playbook main.yml --check

# Run specific tags
ansible-playbook main.yml --tags "rocm,forge"

# Skip tags
ansible-playbook main.yml --skip-tags desktop

# Verbose output
ansible-playbook main.yml -vvv
```

## 📊 System Requirements

### Minimum

- Ubuntu 22.04+
- AMD GPU with ROCm support
- 16GB RAM (for integrated graphics)
- 50GB free disk space

### Recommended

- Ubuntu 24.04 LTS
- AMD RX 6000/7000 series or Ryzen APU
- 32GB RAM
- 100GB SSD

## 🏆 Success Criteria

After successful deployment:

✅ `rocm-smi --showproductname` shows your GPU
✅ `conda activate forge-rocm` works
✅ `torch.cuda.is_available()` returns True
✅ `forge-launch` starts the WebUI
✅ WebUI accessible at http://localhost:7860
✅ Can generate images successfully

## 🎯 Next Steps

1. ✅ **Review configuration:** `vim group_vars/localhost.yml`
2. ✅ **Validate setup:** `./validate-config.sh`
3. ✅ **Test dry run:** `ansible-playbook main.yml --check`
4. ✅ **Deploy:** `./quick-start.sh`
5. ✅ **Reboot:** `sudo reboot`
6. ✅ **Verify:** `ansible-playbook test.yml`
7. ✅ **Launch:** `forge-launch`
8. ✅ **Generate:** Create your first image!

## 🌟 Key Benefits

### For You

- 🚀 **One-command deployment** from fresh Ubuntu
- 🔄 **Reproducible** - deploy on multiple machines
- 📦 **Version controlled** - track all your configs in git
- 🛡️ **Idempotent** - safe to re-run anytime
- 🎯 **Modular** - install only what you need
- 🔧 **Customizable** - easily add your own configs

### For Future You

- 💾 **Backup configs** with one command
- 🔄 **Update easily** with playbooks
- 📝 **Document** your setup automatically
- 🚀 **Redeploy** after system reinstall
- 🔀 **Share** with other machines
- 🎓 **Learn** infrastructure as code

## 🎉 Congratulations!

You now have a professional-grade deployment system for your SD Forge setup!

**Start deploying:**
```bash
cd ~/llm/sd-webui-forge-classic/ansible
./quick-start.sh
```

**Questions?** Check the documentation:
- Quick start: GETTING-STARTED.md
- Commands: QUICKREF.md
- Detailed guide: USAGE.md
- Architecture: README.md

---

**Happy deploying! 🚀**
