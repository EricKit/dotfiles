#!/bin/zsh
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
ZSH_PATH="$(command -v zsh || echo /bin/zsh)"

# ---------------- OS detect ----------------
case "$OSTYPE" in
  darwin*) IS_MAC=1 ;;
  linux*)  IS_LINUX=1 ;;
  *) echo "Unsupported OS: $OSTYPE" >&2; exit 1 ;;
esac

# ---------- 0) Minimal bootstrap: package manager + base tools ----------
if [[ -n "${IS_MAC:-}" ]]; then
  # Install Homebrew if missing
  if ! command -v brew >/dev/null 2>&1; then
    echo "• Installing Homebrew…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add Homebrew to PATH for this session (Apple Silicon & Intel)
    [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
    [[ -x /usr/local/bin/brew   ]] && eval "$(/usr/local/bin/brew shellenv)"
  fi
  echo "• Installing base packages (mac)…"
  brew install zsh git curl vim fzf
elif [[ -n "${IS_LINUX:-}" ]]; then
  # Ensure apt exists (Ubuntu/Debian)
  if ! command -v apt >/dev/null 2>&1; then
    echo "This script expects apt (Ubuntu/Debian)." >&2; exit 1
  fi
  echo "• Installing base packages (apt)…"
  export DEBIAN_FRONTEND=noninteractive
  sudo apt update
  sudo apt install -y zsh git curl vim fzf ca-certificates
fi

# ---------- 1) Make zsh the default login shell ----------
if [[ "${SHELL:-}" != "$ZSH_PATH" ]]; then
  if [[ -n "${IS_LINUX:-}" ]] && ! grep -q "$ZSH_PATH" /etc/shells 2>/dev/null; then
    echo "• Adding $ZSH_PATH to /etc/shells (sudo)…"
    echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
  fi
  echo "• Changing login shell to zsh…"
  chsh -s "$ZSH_PATH" || echo "  (chsh may need logout/login or sudo)"
fi

# ---------- 2) UNSAFE: remove old dotfiles (as requested) ----------
echo "• Removing old dotfiles (unsafe)…"
rm -f "$HOME/.gitconfig" \
      "$HOME/.gitignore_global" \
      "$HOME/.vimrc" \
      "$HOME/.zshrc" \
      "$HOME/.dircolors" \
      "$HOME/.tmux.conf"

# ---------- 3) Link new dotfiles ----------
echo "• Linking new dotfiles…"
mkdir -p "$HOME/.vim/colors" "$HOME/.vim/autoload"
ln -snf "$DOTFILES/dots/home/gitconfig"         "$HOME/.gitconfig"
ln -snf "$DOTFILES/dots/home/gitignore_global"  "$HOME/.gitignore_global"
ln -snf "$DOTFILES/dots/home/vimrc"             "$HOME/.vimrc"
ln -snf "$DOTFILES/dots/home/zshrc"             "$HOME/.zshrc"
ln -snf "$DOTFILES/dots/home/dircolors"         "$HOME/.dircolors"
ln -snf "$DOTFILES/dots/home/tmux"              "$HOME/.tmux.conf"

# Optional extra color scheme (if present in repo)
if [[ -f "$DOTFILES/colors/gruvbox.vim" ]]; then
  ln -snf "$DOTFILES/colors/gruvbox.vim" "$HOME/.vim/colors/gruvbox.vim"
fi

# ---------- 4) Private git identity: prompt + create ~/.gitconfig.user ----------
if [[ ! -f "$HOME/.gitconfig.user" ]]; then
  echo "• Setting up your Git identity (~/.gitconfig.user)"
  read -r "?Enter your full name: " GIT_NAME
  read -r "?Enter your email address: " GIT_EMAIL

  cat > "$HOME/.gitconfig.user" <<EOF
[user]
    name = $GIT_NAME
    email = $GIT_EMAIL
EOF

  # macOS: also include SourceTree difftool/mergetool
  if [[ -n "${IS_MAC:-}" ]]; then
    cat >> "$HOME/.gitconfig.user" <<'EOF'

[difftool "sourcetree"]
    cmd = opendiff "$LOCAL" "$REMOTE"
    path = 

[mergetool "sourcetree"]
    cmd = /Applications/SourceTree.app/Contents/Resources/opendiff-w.sh "$LOCAL" "$REMOTE" -ancestor "$BASE" -merge "$MERGED"
    trustExitCode = true
EOF
  fi
  echo "→ Created ~/.gitconfig.user"
fi

# ---------- 5) Install Oh My Zsh (unattended; keep our .zshrc) ----------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "• Installing Oh My Zsh…"
  export RUNZSH=no CHSH=no KEEP_ZSHRC=yes
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# ---------- 6) OMZ plugins & theme ----------
echo "• Ensuring OMZ plugins/theme…"
clone_or_update() {
  local repo="$1" dest="$2"
  if [[ -d "$dest/.git" ]]; then
    git -C "$dest" pull --ff-only || true
  else
    rm -rf "$dest"
    git clone --depth=1 "$repo" "$dest"
  fi
}
clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git \
  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone_or_update https://github.com/zsh-users/zsh-autosuggestions \
  "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_or_update https://github.com/romkatv/powerlevel10k.git \
  "$ZSH_CUSTOM/themes/powerlevel10k"

# ---------- 7) vim-plug + plugin install ----------
echo "• Installing vim-plug and Vim plugins…"
curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
if command -v vim >/dev/null 2>&1; then
  vim +PlugInstall +qall || true
fi

# ---------- 8) OS-aware essentials (call your functions from .zshrc) ----------
echo "• Installing essentials for this OS…"
if [[ -n "${IS_MAC:-}" ]]; then
  # fzf keybindings (avoid touching rc files)
  if [[ -x "/opt/homebrew/opt/fzf/install" ]]; then
    /opt/homebrew/opt/fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish || true
  fi
  # Ensure brew in PATH for this session (post-install shells)
  [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)" || true
  [[ -x /usr/local/bin/brew   ]] && eval "$(/usr/local/bin/brew shellenv)"   || true
  # Run your brew-essentials if defined
  zsh -i -c 'source ~/.zshrc >/dev/null 2>&1; command -v brew >/dev/null && type brew-essentials >/dev/null && brew-essentials || true'
elif [[ -n "${IS_LINUX:-}" ]]; then
  # Nice-to-have: credential helper on Debian/Ubuntu
  sudo apt install -y git-credential-libsecret || true
  # Run your apt-essentials if defined
  zsh -i -c 'source ~/.zshrc >/dev/null 2>&1; type apt-essentials >/dev/null && apt-essentials || true'
fi

echo "✅ All done. Open a new terminal or run: exec zsh"