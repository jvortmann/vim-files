#!/bin/bash

echo; echo ">> Removing existing configs"
rm -r ~/.vim

echo; echo ">> Symlink default configurations"
ln -sfhv $(pwd) ~/.vim
ln -sfhv ~/.vim/vimrc ~/.vimrc
ln -sfhv ~/.vim/gvimrc ~/.gvimrc

echo; echo ">> Creating ~/.config"
mkdir -p ~/.config

echo; echo ">> Symlink NVim configuration"
ln -sfhv $(pwd) ~/.config/nvim
ln -sfhv ~/.config/nvim/vimrc ~/.config/nvim/init.vim

echo
