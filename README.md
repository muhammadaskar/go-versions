# 🐹 Go Version Manager

A simple and efficient **shell script** to manage multiple Go versions on **Ubuntu/Linux** systems.  
Perfect for developers who need to switch between different Go versions — especially when using **GoLand IDE**.  

---

## ✨ Features

- 📦 **Multiple Version Management** — Install and manage multiple Go versions side-by-side  
- 🔄 **Easy Switching** — Switch between Go versions with a single command  
- 🚀 **GoLand Optimized** — Seamless integration with JetBrains GoLand  
- 🛠️ **Lightweight** — No dependencies, pure Bash script  
- 🔧 **Auto Configuration** — Automatically sets up environment variables  
- 📋 **Version Listing** — View all installed versions with the active one highlighted  

---

## ⚡ Quick Start

### 1️⃣ Clone or Download

```bash
# Clone the repository
git clone https://github.com/muhammadaskar/go-versions.git
cd ~/go-versions
```

### 2️⃣ Make Script Executable
```bash
chmod +x go-version-manager.sh
```

### 3️⃣ Install Your First Go Version
```bash
./go-version-manager.sh download 1.21.0
```

⚙️ Configuration
🔧 Automatic Bashrc Configuration
When you install your first version, the script automatically configures your ~/.bashrc:
```bash
# ===== GO CONFIGURATION =====
export GOROOT="$HOME/go-versions/current"
export GOPATH="$HOME/go"
export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"
# ===== END GO CONFIGURATION =====
```

Reload your shell:
```bash
source ~/.bashrc
```

💬 Shell Compatibility

✅ bash (default on most Linux systems)
✅ zsh (add to ~/.zshrc instead)

🧩 Usage
📥 Download and Install Go Versions
```bash
./go-version-manager.sh download 1.18.10
./go-version-manager.sh download 1.19.13
./go-version-manager.sh download 1.20.14
./go-version-manager.sh download 1.21.0
./go-version-manager.sh download 1.22.0
./go-version-manager.sh download 1.23.0
```

🔀 Switch Between Versions
```bash
./go-version-manager.sh switch 1.18.10
./go-version-manager.sh switch 1.21.0
./go-version-manager.sh switch 1.23.0
```

🧰 Manage Versions
```bash
# List all installed versions (active version highlighted)
./go-version-manager.sh list

# Show current active version
./go-version-manager.sh current

# Remove a specific version
./go-version-manager.sh remove 1.18.10

# Install all default versions
./go-version-manager.sh default

# Remove all versions (clean slate)
./go-version-manager.sh clean
```

🆘 Help Commands
```bash
./go-version-manager.sh help
./go-version-manager.sh --help
./go-version-manager.sh -h
```

💻 GoLand IDE Configuration
🧱 Setting Up Multiple GOROOTs

1. Open GoLand Settings
    → File → Settings (or GoLand → Preferences on macOS)

2. Navigate to Go → GOROOT

3. Click ➕ Add Specific GOROOT

4. Add each version:
| Name       | Path                                        |
| ---------- | ------------------------------------------- |
| Go 1.18.10 | `/home/your-username/go-versions/go1.18.10` |
| Go 1.19.13 | `/home/your-username/go-versions/go1.19.13` |
| Go 1.20.14 | `/home/your-username/go-versions/go1.20.14` |
| Go 1.21.0  | `/home/your-username/go-versions/go1.21.0`  |
| Go 1.23.0  | `/home/your-username/go-versions/go1.23.0`  |


5. For each project:
- Go to File → Settings → Go → GOROOT
- Select the appropriate Go version for that project
- Click Apply and OK


📁 Directory Structure
After installation, your go-versions directory will look like this:
go-versions/
├── go1.18.10/             # Go 1.18.10 installation
├── go1.19.13/             # Go 1.19.13 installation
├── go1.20.14/             # Go 1.20.14 installation
├── go1.21.0/              # Go 1.21.0 installation
├── go1.23.0/              # Go 1.23.0 installation
├── current -> go1.23.0    # Symlink to active version
├── go-version-manager.sh  # Main management script
├── .gitignore
└── README.md

🧼 Clean Installation
If you want to start fresh:
```bash
./go-version-manager.sh clean
./go-version-manager.sh download 1.21.0
./go-version-manager.sh switch 1.21.0
```

🧠 Author
Muhammad Askar
💼 GitHub Profile
📫 Contributions and feedback are welcome!