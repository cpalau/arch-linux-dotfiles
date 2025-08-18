# Arch Linux Dotfiles Setup

My comprehensive, modular setup system for Arch Linux installation and configuration management.

## 🚀 Features

- **Automated WiFi Setup**: I've created scripts that connect to WiFi networks using configuration files
- **Archinstall Integration**: I use JSON configuration for consistent installations
- **Modular Architecture**: I've designed separate scripts for different setup phases
- **Dotfiles Management**: I've built automated deployment of configuration files
- **Package Management**: I've organized installation of essential and optional packages
- **Service Configuration**: I've automated setup of system services

## 📁 Project Structure

```
arch-linux/
├── setup                           # My main entry point script
├── config/
│   ├── setup_passwords.env        # My WiFi and other credentials (create manually)
│   ├── archinstall.json           # My archinstall configuration (to be created)
│   ├── user.env                   # My user preferences (to be created)
│   └── packages.txt               # My additional package lists (to be created)
├── scripts/
│   ├── 00-pre-install.sh          # My WiFi setup + archinstall execution ✅
│   ├── 01-post-install.sh         # My post-installation configuration (to be created)
│   ├── 02-packages.sh             # My package installation (to be created)
│   ├── 03-dotfiles.sh             # My dotfiles deployment (to be created)
│   ├── 04-services.sh             # My system services setup (to be created)
│   └── utils/
│       ├── colors.sh              # My color definitions ✅
│       ├── logging.sh             # My logging functions ✅
│       └── helpers.sh             # My common helper functions ✅
├── dotfiles/
│   ├── .bashrc                    # My bash configuration (to be created)
│   ├── .vimrc                     # My vim configuration (to be created)
│   ├── .gitconfig                 # My git configuration (to be created)
│   └── .config/                   # My application configurations (to be created)
├── packages/
│   ├── base.txt                   # My essential packages (to be created)
│   ├── development.txt            # My development tools (to be created)
│   ├── desktop.txt                # My desktop environment packages (to be created)
│   └── optional.txt               # My optional packages (to be created)
└── README.md                      # This documentation ✅
```

## 🛠️ Setup Process

### Phase 1: Pre-installation (From Arch Linux Live USB)

1. **Boot Arch Linux Live USB**
2. **Copy my dotfiles from USB**:
   ```bash
   # Mount your USB drive (replace sdX1 with your USB device)
   mount /dev/sdX1 /mnt
   # Copy the entire dotfiles directory
   cp -r /mnt/arch-linux /root/
   cd /root/arch-linux
   # Make setup script executable
   chmod +x setup
   ```
3. **Configure my WiFi credentials**:
   ```bash
   # Edit the existing configuration file
   echo "WIFI_SSID=your_network_name" > config/setup_passwords.env
   echo "WIFI_PASSWORD=your_password" >> config/setup_passwords.env
   ```
4. **Run my pre-installation setup** (handles WiFi connection and system preparation):
   ```bash
   ./setup pre-install
   ```

This will:
- Configure Spanish keyboard layout
- Connect to my WiFi network
- Update package sources
- Install git and wget
- Execute archinstall (when I configure it)

### Phase 2: Post-installation (From Installed System)

After rebooting into the new Arch Linux system:

```bash
./setup post-install
```

This will:
- Configure my system settings
- Install my additional packages
- Deploy my dotfiles
- Setup my system services

### Full Setup (Complete Process)

For my complete automated setup:

```bash
./setup full
```

## ⚙️ Configuration Files

### WiFi Configuration (`config/setup_passwords.env`)
```bash
WIFI_SSID=your_network_name
WIFI_PASSWORD=your_password
```

### Archinstall Configuration (`config/archinstall.json`)
I create my archinstall configuration file. Example structure:
```json
{
    "bootloader": "grub-install",
    "hostname": "archlinux",
    "kernels": ["linux"],
    "locale_config": {
        "kb_layout": "es"
    },
    "mirror_config": {
        "mirror_regions": {
            "Spain": ["https://..."]
        }
    }
}
```

## 📦 Package Categories

- **base.txt**: My essential system packages
- **development.txt**: My development tools (git, vim, nodejs, etc.)
- **desktop.txt**: My desktop environment packages
- **optional.txt**: My additional optional software

## 🔧 Available Commands

```bash
./setup pre-install    # Run my pre-installation setup
./setup post-install   # Run my post-installation setup
./setup full           # Run my complete setup process
./setup --help         # Show help information
./setup --version      # Show version information
```

## 🎯 Development Roadmap

### Completed ✅
- [x] Project structure
- [x] WiFi setup automation
- [x] Utility functions (logging, colors, helpers)
- [x] Main setup script with argument handling

### To Do 📋
- [ ] Archinstall JSON configuration
- [ ] Post-installation system configuration
- [ ] Package installation scripts
- [ ] Dotfiles management
- [ ] Service configuration
- [ ] User environment setup

## 🤝 Contributing

1. Create your feature branch
2. Follow my existing code structure
3. Test your changes
4. Submit a pull request

## 📝 Notes

- I run `./setup pre-install` from the Arch Linux live USB environment
- I run `./setup post-install` from the installed Arch Linux system
- Make sure to configure `config/setup_passwords.env` before running pre-install
- My system uses modular scripts for easy maintenance and customization

## 🔒 Security

- My WiFi credentials are stored locally and never transmitted
- Temporary password files are automatically cleaned up
- All my scripts include error handling and validation

---

**Version**: 1.0.0  
**License**: MIT  
**Author**: Cristian Palau