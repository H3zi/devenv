# VM Setup Script

Automated setup script for new Ubuntu/Debian VMs with selective installation.

## Usage

```bash
./install.sh [options...]
```

**Remote:**
```bash
curl -fsSL https://raw.githubusercontent.com/H3zi/devenv/main/install.sh | bash -s -- [options...]
```

## Options

| Option   | Description                              |
|----------|------------------------------------------|
| `all`    | Install everything                       |
| `zsh`    | zsh + oh-my-zsh + plugins                |
| `github` | GitHub CLI                               |
| `awscli` | AWS CLI v2 (x86_64/arm64)                |
| `uv`     | uv (Python package manager)              |
| `claude` | Claude CLI                               |
| `nvme`   | Mount NVMe instance store at `/mnt`      |

## Examples

```bash
# Install everything
curl -fsSL https://raw.githubusercontent.com/H3zi/devenv/main/install.sh | bash -s -- all

# Install only zsh and claude
curl -fsSL https://raw.githubusercontent.com/H3zi/devenv/main/install.sh | bash -s -- zsh claude

# Install dev tools
curl -fsSL https://raw.githubusercontent.com/H3zi/devenv/main/install.sh | bash -s -- zsh github awscli uv claude
```

## Requirements

- Ubuntu/Debian-based system
- sudo privileges
- Internet connection
