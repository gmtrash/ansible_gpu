# Getting Started with Your Ansible Deployment

Welcome! This Ansible setup will automatically configure your Ubuntu desktop with ROCm and Stable Diffusion WebUI Forge Classic.

## What You've Got

A complete Ansible-based deployment system that can:

✅ Install and configure AMD ROCm for GPU acceleration
✅ Set up Conda/Miniforge with Python environments
✅ Install Stable Diffusion WebUI Forge Classic (ROCm edition)
✅ Apply your personal desktop preferences (dotfiles, aliases, etc.)
✅ Be re-run safely to update or fix configuration
✅ Deploy on a fresh Ubuntu install with one command

## 🚀 Quick Start (3 Steps)

### Step 1: Edit Your Configuration

```bash
cd ~/llm/sd-webui-forge-classic/ansible
vim group_vars/localhost.yml
```

**At minimum, update these:**
- `username`: Your Ubuntu username
- `git_user_email`: Your email address

### Step 2: Run the Deployment

```bash
./quick-start.sh
```

Choose option 1 (Full deployment) and enter your sudo password when prompted.

### Step 3: Reboot and Launch

```bash
sudo reboot

# After reboot:
forge-launch
# Or manually:
# conda activate forge-rocm
# cd ~/llm/sd-webui-forge-classic
# ./webui-user-rocm.sh
```

Access the WebUI at: http://localhost:7860

## 📚 Documentation Overview

| File | Purpose | When to Read |
|------|---------|--------------|
| **GETTING-STARTED.md** | This file - start here | First time |
| **QUICKREF.md** | One-page cheat sheet | Quick reference |
| **README.md** | Complete documentation | Learning the system |
| **USAGE.md** | Detailed usage guide | When you need help |

## 🎯 Common Use Cases

### Use Case 1: Fresh Ubuntu Install

**Goal:** Set up everything from scratch on a new Ubuntu installation.

```bash
# Install Ansible
sudo apt update && sudo apt install -y ansible git

# Clone this repository
git clone <your-repo-url> ~/sd-webui-forge-classic
cd ~/sd-webui-forge-classic/ansible

# Configure
vim group_vars/localhost.yml  # Update username, email

# Deploy
./quick-start.sh  # Choose option 1

# Reboot
sudo reboot

# Verify and launch
rocm-smi --showproductname
forge-launch
```

### Use Case 2: Update Existing Setup

**Goal:** Update SD Forge or apply configuration changes.

```bash
cd ~/sd-webui-forge-classic/ansible

# Pull latest changes
git pull

# Update Forge only (fast)
ansible-playbook main.yml --tags forge --ask-become-pass

# Or update everything
ansible-playbook main.yml --ask-become-pass
```

### Use Case 3: Capture Current Configuration

**Goal:** Export your current system settings to Ansible variables.

```bash
cd ~/sd-webui-forge-classic/ansible

# Export current config
./export-current-config.sh

# Review exported config
cat group_vars/localhost.yml.exported

# Copy relevant parts to your config
vim group_vars/localhost.yml
```

### Use Case 4: Deploy Only Specific Components

**Goal:** Install just ROCm, or just SD Forge, etc.

```bash
# Install only ROCm
ansible-playbook main.yml --tags rocm --ask-become-pass

# Install only SD Forge (assumes ROCm/conda exist)
ansible-playbook main.yml --tags forge --ask-become-pass

# Update desktop preferences only
ansible-playbook main.yml --tags desktop
```

## 🧪 Testing Before You Deploy

Always test before making changes to your system:

```bash
# Dry run - shows what would change
ansible-playbook main.yml --check --ask-become-pass

# Verify current configuration
ansible-playbook test.yml
```

## 📋 What Gets Installed

### Base System (`base` role)
- Build tools (gcc, make, cmake)
- Python development packages
- Utilities (htop, vim, git, curl, etc.)
- User added to `video` and `render` groups

### ROCm (`rocm` role)
- AMD ROCm 6.2+ repositories
- ROCm core packages (hip, rocm-smi, rocminfo)
- GPU driver configuration
- ROCm environment variables

### Conda (`conda` role)
- Miniforge or Miniconda
- Configured in ~/.bashrc
- Updated to latest version

### SD Forge ROCm (`forge` role)
- Clones/updates repository
- Creates `forge-rocm` conda environment
- Applies ROCm patches
- Sets up launch scripts
- Creates model directories
- Configures for your GPU

### Desktop Preferences (`desktop` role)
- Git configuration
- Custom bash aliases
- Environment variables
- Vim/tmux configuration
- Utility scripts

## 🔧 Customization Guide

### Adding System Packages

Edit `group_vars/localhost.yml`:

```yaml
additional_apt_packages:
  - htop
  - vim
  - tmux
  - your-package-here
  - another-package
```

### Adding Bash Aliases

```yaml
custom_bash_aliases:
  - alias myalias='my command'
  - alias ll='ls -alF'
  - alias forge='cd ~/llm/sd-webui-forge-classic && conda activate forge-rocm'
```

### Using Shared Model Directory

If you have models elsewhere and want to symlink them:

```yaml
shared_models_dir: "/mnt/data/ai-models"
shared_models_types:
  - Stable-diffusion
  - Lora
  - VAE
  - ControlNet
```

### Adjusting Forge Settings

```yaml
# GPU performance mode
forge_gpu_mode: "integrated"  # or "dedicated-low", "dedicated-high"

# Launch arguments
forge_commandline_args: >-
  --cuda-malloc
  --pin-shared-memory
  --persistent-patches
  --attention-pytorch
  --medvram
```

## 🛠️ Troubleshooting

### Installation Fails

```bash
# Run with verbose output
ansible-playbook main.yml -vvv --ask-become-pass

# Check specific role
ansible-playbook main.yml --tags rocm -vvv --ask-become-pass
```

### ROCm Not Working

```bash
# Verify ROCm installation
rocm-smi --showproductname

# Check environment variables
source /etc/profile.d/rocm.sh
echo $ROCM_HOME

# Reboot (often needed after first ROCm install)
sudo reboot
```

### PyTorch Not Detecting GPU

```bash
# Activate environment
conda activate forge-rocm

# Check PyTorch
python -c "import torch; print(torch.__version__); print(torch.cuda.is_available())"

# Reinstall if needed
pip install --force-reinstall torch torchvision torchaudio \
    --extra-index-url https://download.pytorch.org/whl/rocm6.2
```

### Deployment Takes Too Long

```bash
# Skip checks after first successful run
# Edit group_vars/localhost.yml:
upgrade_system: false  # Don't upgrade all packages

# Or use tags to install only what you need
ansible-playbook main.yml --tags forge --ask-become-pass
```

## 📖 Learning Ansible

New to Ansible? Here's what you need to know:

**Playbook:** A YAML file that defines what to do (like `main.yml`)

**Role:** A reusable collection of tasks (like `rocm`, `forge-rocm`)

**Tasks:** Individual steps (like "install package", "copy file")

**Tags:** Labels to run specific parts (like `--tags rocm`)

**Idempotent:** Safe to run multiple times - only changes what's needed

**Example task:**
```yaml
- name: Install htop
  apt:
    name: htop
    state: present
```

## 🎓 Next Steps

1. ✅ **Deploy your system** (see Quick Start above)
2. 📝 **Customize** `group_vars/localhost.yml` with your preferences
3. 🧪 **Test changes** with `--check` before applying
4. 📚 **Read USAGE.md** for detailed scenarios
5. 🔖 **Bookmark QUICKREF.md** for common commands
6. 🚀 **Extend** by adding your own roles (see examples below)

## 🌟 Extending This Setup

Want to add more applications? Easy!

### Example: Add Jupyter Lab

1. Create variables in `group_vars/localhost.yml`:
```yaml
install_jupyter: true
jupyter_port: 8888
```

2. Create a new role:
```bash
mkdir -p roles/jupyter/tasks
```

3. Add tasks in `roles/jupyter/tasks/main.yml`:
```yaml
---
- name: Install Jupyter in forge environment
  shell: |
    source {{ conda_install_dir }}/etc/profile.d/conda.sh
    conda activate {{ forge_conda_env }}
    pip install jupyterlab
  when: install_jupyter | default(false)
```

4. Add to `main.yml`:
```yaml
- name: Import Jupyter role
  import_role:
    name: jupyter
  tags: jupyter
  when: install_jupyter | default(false)
```

5. Deploy:
```bash
ansible-playbook main.yml --tags jupyter
```

## 📞 Getting Help

1. **Check the logs:** Ansible shows detailed output
2. **Test first:** Use `ansible-playbook test.yml`
3. **Read docs:** See USAGE.md for comprehensive guide
4. **Verify manually:** Test commands individually
5. **Start fresh:** Remove and reinstall if needed

## 🎉 Success!

Once deployed, you'll have:

- ✅ ROCm-accelerated GPU ready to go
- ✅ SD Forge installed and configured
- ✅ Custom shell environment with useful aliases
- ✅ Reproducible setup you can redeploy anytime
- ✅ Easy updates with `ansible-playbook main.yml --tags forge`

**Launch your WebUI:**
```bash
forge-launch
# Access at http://localhost:7860
```

**Verify everything:**
```bash
rocm-check      # Check GPU
conda-info      # Check environments
torch-check     # Check PyTorch ROCm
```

---

**Ready to deploy?** Start with the Quick Start section above! 🚀
