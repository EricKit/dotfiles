#!/bin/zsh

# Change shell for current user to zsh
if [ ! "$SHELL" = "/bin/zsh" ]; then
  chsh -s /bin/zsh
fi

# remove old dot files
rm ~/.gitconfig
rm ~/.gitignore_global
rm ~/.vimrc
rm ~/.zshrc

# link new dot files
ln ~/.dotfiles/dots/home/gitconfig               ~/.gitconfig
ln ~/.dotfiles/dots/home/gitignore_global        ~/.gitignore_global
ln ~/.dotfiles/dots/home/vimrc                   ~/.vimrc
ln ~/.dotfiles/dots/home/zshrc                   ~/.zshrc

mkdir ~/.vim/colors
ln ~/.dotfiles/colors/gruvbox.vim                ~/.vim/colors/gruvbox.vim

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install custom plugins
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

#Add Plug to .vim
`curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim`