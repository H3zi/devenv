#!/bin/bash
set -euo pipefail

# Use sudo if available and not root, otherwise run directly
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
elif command -v sudo &> /dev/null; then
    SUDO="sudo"
else
    echo "Error: This script requires root privileges. Please run as root or install sudo."
    exit 1
fi

# Get current user reliably
CURRENT_USER="${USER:-$(whoami)}"

show_help() {
    echo "Usage: $0 [options...]"
    echo ""
    echo "Options:"
    echo "  all       Install everything"
    echo "  zsh       Install zsh + oh-my-zsh + plugins"
    echo "  github    Install GitHub CLI"
    echo "  awscli    Install AWS CLI v2"
    echo "  uv        Install uv (Python package manager)"
    echo "  claude    Install Claude CLI"
    echo "  nvme      Mount NVMe instance store"
    echo ""
    echo "Example: $0 zsh github claude"
}

install_base() {
    $SUDO apt update
    $SUDO apt install -y curl git unzip
}

install_zsh() {
    echo "Installing zsh..."
    $SUDO apt install -y zsh

    # Install oh-my-zsh (unattended)
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    # Install plugins
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

    # Update plugins in .zshrc
    sed -i 's/^plugins=(git)$/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

    # Change default shell to zsh
    $SUDO chsh -s "$(which zsh)" "$CURRENT_USER"
    echo "zsh installed!"
}

install_github() {
    echo "Installing GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | $SUDO dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    $SUDO chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | $SUDO tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    $SUDO apt update
    $SUDO apt install -y gh
    echo "GitHub CLI installed!"
}

install_awscli() {
    echo "Installing AWS CLI..."
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        AWS_CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
    elif [ "$ARCH" = "aarch64" ]; then
        AWS_CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"
    else
        echo "Unsupported architecture: $ARCH"
        return 1
    fi
    curl -fsSL "$AWS_CLI_URL" -o /tmp/awscliv2.zip
    unzip -q /tmp/awscliv2.zip -d /tmp
    $SUDO /tmp/aws/install
    rm -rf /tmp/awscliv2.zip /tmp/aws
    echo "AWS CLI installed!"
}

install_uv() {
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    echo "uv installed!"
}

install_claude() {
    echo "Installing Claude CLI..."
    curl -fsSL https://claude.ai/install.sh | bash
    echo "Claude CLI installed!"
}

mount_nvme() {
    echo "Checking for NVMe volumes..."
    $SUDO apt install -y jq
    DEVICE=$(
      lsblk -J \
      | jq -r '
          .blockdevices[]
          | select(.type=="disk" and (.name|startswith("nvme")))
          | select(
              (has("children")|not)
              or ([.children[].mountpoints[]] | all(. == null))
            )
          | .name
        ' | head -n1
    )

    if [ -n "$DEVICE" ]; then
        echo "Found unmounted NVMe device: /dev/$DEVICE"
        $SUDO mkfs.ext4 "/dev/$DEVICE"
        $SUDO mkdir -p /mnt
        $SUDO mount "/dev/$DEVICE" /mnt
        $SUDO chown "$CURRENT_USER:$CURRENT_USER" /mnt
        echo "Mounted /dev/$DEVICE at /mnt"
    else
        echo "No unmounted NVMe device found, skipping"
    fi
}

# Show help if no arguments
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

# Parse arguments
INSTALL_ZSH=false
INSTALL_GITHUB=false
INSTALL_AWSCLI=false
INSTALL_UV=false
INSTALL_CLAUDE=false
MOUNT_NVME=false

for arg in "$@"; do
    case $arg in
        all)
            INSTALL_ZSH=true
            INSTALL_GITHUB=true
            INSTALL_AWSCLI=true
            INSTALL_UV=true
            INSTALL_CLAUDE=true
            MOUNT_NVME=true
            ;;
        zsh)       INSTALL_ZSH=true ;;
        github)    INSTALL_GITHUB=true ;;
        awscli)    INSTALL_AWSCLI=true ;;
        uv)        INSTALL_UV=true ;;
        claude)    INSTALL_CLAUDE=true ;;
        nvme)      MOUNT_NVME=true ;;
        -h|--help) show_help; exit 0 ;;
        *)         echo "Unknown option: $arg"; show_help; exit 1 ;;
    esac
done

# Install base packages
install_base

# Run selected installations
if [ "$INSTALL_ZSH" = true ]; then install_zsh; fi
if [ "$INSTALL_GITHUB" = true ]; then install_github; fi
if [ "$INSTALL_AWSCLI" = true ]; then install_awscli; fi
if [ "$INSTALL_UV" = true ]; then install_uv; fi
if [ "$INSTALL_CLAUDE" = true ]; then install_claude; fi
if [ "$MOUNT_NVME" = true ]; then mount_nvme; fi

# Summary
echo ""
echo "========================================"
echo "Installation complete!"
echo "========================================"
echo ""
echo "Installed:"
if [ "$INSTALL_ZSH" = true ]; then echo "  - zsh + oh-my-zsh + plugins"; fi
if [ "$INSTALL_GITHUB" = true ]; then echo "  - GitHub CLI"; fi
if [ "$INSTALL_AWSCLI" = true ]; then echo "  - AWS CLI v2"; fi
if [ "$INSTALL_UV" = true ]; then echo "  - uv"; fi
if [ "$INSTALL_CLAUDE" = true ]; then echo "  - Claude CLI"; fi
if [ "$MOUNT_NVME" = true ]; then echo "  - NVMe volume mounted at /mnt"; fi
echo ""
echo "Next steps:"
if [ "$INSTALL_ZSH" = true ]; then echo "  - Run 'exec zsh' or restart terminal to use zsh"; fi
if [ "$INSTALL_GITHUB" = true ]; then echo "  - Run 'gh auth login' to authenticate with GitHub"; fi
if [ "$INSTALL_AWSCLI" = true ]; then echo "  - Run 'aws configure' to set up AWS credentials"; fi
if [ "$INSTALL_CLAUDE" = true ]; then echo "  - Run 'claude' to authenticate and start using Claude CLI"; fi
echo ""
