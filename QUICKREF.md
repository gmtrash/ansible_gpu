# Ansible Quick Reference Card

## One-Page Cheat Sheet for Common Tasks

### Initial Setup (Fresh Ubuntu)

```bash
# Install Ansible
sudo apt update && sudo apt install -y ansible git

# Clone repository
git clone <repo-url> ~/sd-webui-forge-classic
cd ~/sd-webui-forge-classic/ansible

# Edit configuration
vim group_vars/localhost.yml  # Update username, email, preferences

# Deploy everything
./quick-start.sh
# OR
ansible-playbook main.yml --ask-become-pass

# Reboot
sudo reboot
```

### Common Commands

| Task | Command |
|------|---------|
| **Full deployment** | `ansible-playbook main.yml --ask-become-pass` |
| **Dry run (no changes)** | `ansible-playbook main.yml --check --ask-become-pass` |
| **Test configuration** | `ansible-playbook test.yml` |
| **Install ROCm only** | `ansible-playbook main.yml --tags rocm --ask-become-pass` |
| **Install Forge only** | `ansible-playbook main.yml --tags forge --ask-become-pass` |
| **Update Forge** | `ansible-playbook main.yml --tags forge --ask-become-pass` |
| **Desktop preferences** | `ansible-playbook main.yml --tags desktop` |
| **Skip desktop setup** | `ansible-playbook main.yml --skip-tags desktop --ask-become-pass` |
| **Verbose output** | `ansible-playbook main.yml -vvv --ask-become-pass` |

### Available Tags

| Tag | What it Does |
|-----|--------------|
| `base` | Base system packages, build tools |
| `rocm` | AMD ROCm GPU drivers |
| `conda` | Conda/Miniforge installation |
| `forge` | SD Forge ROCm setup |
| `desktop` | Dotfiles, aliases, preferences |

### File Structure

```
ansible/
├── main.yml                          # Main playbook
├── test.yml                          # Test/verification playbook
├── quick-start.sh                    # Interactive setup script
├── export-current-config.sh          # Export current system config
├── ansible.cfg                       # Ansible configuration
├── inventory.ini                     # Inventory file
├── group_vars/
│   └── localhost.yml                 # EDIT THIS: Your configuration
├── roles/
│   ├── base-system/tasks/main.yml    # System packages
│   ├── rocm/tasks/main.yml           # ROCm installation
│   ├── conda/tasks/main.yml          # Conda setup
│   ├── forge-rocm/tasks/main.yml     # SD Forge
│   └── desktop-preferences/tasks/main.yml  # Personal configs
├── README.md                         # Full documentation
├── USAGE.md                          # Comprehensive usage guide
└── QUICKREF.md                       # This file
```

### Key Configuration Variables

Edit `group_vars/localhost.yml`:

```yaml
# Must change:
username: aubreybailey          # Your username
git_user_email: you@example.com # Your email

# Optionally change:
rocm_version: "6.2"
gpu_architecture: "gfx1036"
forge_install_dir: "{{ home_dir }}/llm/sd-webui-forge-classic"
shared_models_dir: "/path/to/shared/models"  # Optional
```

### Verification Commands

After deployment:

```bash
# Check ROCm
rocm-smi --showproductname

# Check conda
conda --version
conda env list

# Check Forge environment
conda activate forge-rocm
python -c "import torch; print(torch.cuda.is_available())"

# Launch Forge
forge-launch
# OR
cd ~/llm/sd-webui-forge-classic && ./launch-rocm.sh
```

### Troubleshooting Quick Fixes

| Problem | Quick Fix |
|---------|-----------|
| Permission denied | Add `--ask-become-pass` |
| ROCm not found after install | `source /etc/profile.d/rocm.sh` or reboot |
| Conda not found | `source ~/miniforge3/etc/profile.d/conda.sh` |
| PyTorch no ROCm | Reinstall: `pip install --force-reinstall torch --extra-index-url https://download.pytorch.org/whl/rocm6.2` |
| Want to undo | Remove packages: `sudo apt remove rocm-*` |

### Aliases Added to Your Shell

After deployment, these aliases are available:

```bash
ll              # Detailed list
gpu             # rocm-smi
forge           # cd to forge directory and activate conda env
forge-launch    # Launch Forge WebUI
rocm-check      # Check ROCm status
torch-check     # Verify PyTorch ROCm
gpu-monitor     # Watch GPU usage
```

### Customization Examples

**Add packages:**
```yaml
# In group_vars/localhost.yml:
additional_apt_packages:
  - htop
  - vim
  - your-package-here
```

**Add bash aliases:**
```yaml
custom_bash_aliases:
  - alias myalias='my command'
```

**Use shared models:**
```yaml
shared_models_dir: "/mnt/data/ai-models"
shared_models_types:
  - Stable-diffusion
  - Lora
```

### Quick Deployment Workflow

1. **Edit config** → `vim group_vars/localhost.yml`
2. **Test** → `ansible-playbook test.yml`
3. **Dry run** → `ansible-playbook main.yml --check --ask-become-pass`
4. **Deploy** → `ansible-playbook main.yml --ask-become-pass`
5. **Reboot** → `sudo reboot`
6. **Verify** → `rocm-smi && conda activate forge-rocm`
7. **Launch** → `forge-launch`

### Getting Help

- **Full docs:** `README.md`
- **Usage guide:** `USAGE.md`
- **Test system:** `ansible-playbook test.yml`
- **Ansible help:** `ansible-playbook --help`

### Example: Fresh Install

```bash
# On a brand new Ubuntu installation:

# 1. Install Ansible
sudo apt update
sudo apt install -y ansible git

# 2. Get the playbooks
git clone <your-repo> ~/sd-webui-forge-classic
cd ~/sd-webui-forge-classic/ansible

# 3. Configure
vim group_vars/localhost.yml
# Update: username, git_user_email

# 4. Deploy
./quick-start.sh
# Choose option 1 (Full deployment)
# Enter sudo password when prompted

# 5. Reboot
sudo reboot

# 6. Done!
forge-launch
```

### Example: Update Only Forge

```bash
# Already deployed, just want to update SD Forge:

cd ~/sd-webui-forge-classic/ansible
git pull  # Get latest playbook changes
ansible-playbook main.yml --tags forge --ask-become-pass
```

---

**Remember:** Always do a dry run first with `--check` if you're unsure!
