#!/bin/bash

echo; echo ">> Removing existing configs"
rm -r ~/.vim

echo; echo ">> Symlink default configurations"
ln -sfnv "$(pwd)" ~/.vim
ln -sfnv ~/.vim/vimrc ~/.vimrc
ln -sfnv ~/.vim/gvimrc ~/.gvimrc

echo; echo ">> Creating ~/.config"
mkdir -p ~/.config

echo; echo ">> Symlink NVim configuration"
ln -sfnv "$(pwd)" ~/.config/nvim
ln -sfnv ~/.config/nvim/vimrc ~/.config/nvim/init.vim

echo
