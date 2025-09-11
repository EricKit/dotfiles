# Dotfiles

Personal dotfiles for macOS, Ubuntu, and Debian.  
This repo manages shell, editor, tmux, Git, and colors in a consistent way across machines.

---

## Features

- **Shell (`.zshrc`)**

  - Oh-My-Zsh with a minimal plugin set
  - Powerlevel10k theme
  - Cross-platform helpers (`brew-essentials` on macOS, `apt-essentials` on Linux)
  - Support for `fzf`, `zoxide`, `nvm`, and GNU `ls` colors (`dircolors`)

- **Vim (`.vimrc`)**

  - Plugin management via [vim-plug](https://github.com/junegunn/vim-plug)
  - Gruvbox theme
  - CoC for LSP + completion
  - Prettier integration for web files

- **Tmux (`.tmux.conf`)**

  - Mouse support
  - Vim-style pane navigation and splits
  - Vi copy mode with clipboard integration (macOS/Linux)

- **Git (`.gitconfig`)**

  - Safe, modern defaults (`main` branch, prune, rerere, zdiff3 conflicts)
  - Includes a private identity file (`~/.gitconfig.user`) so your name/email stay outside this repo

- **Colors (`.dircolors`)**
  - Tuned for dark themes
  - Clearer directory/symlink colors
  - Extended file type coverage (media, code, configs)

---

## Installation

⚠️ **Warning:** `install.sh` is _unsafe_ by design. It will remove existing dotfiles (`~/.zshrc`, `~/.vimrc`, etc.) and replace them with symlinks to this repo.

```bash
git clone https://github.com/erickit/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```
