#!/bin/bash

echo "Symlink default configurations"
ln -sfhv $(pwd) ~/.vim
ln -sfhv ~/.vim/vimrc ~/.vimrc
ln -sfhv ~/.vim/gvimrc ~/.gvimrc
echo

echo "Symlink NVim configuration"
ln -sfhv ~/.vim ~/.config/nvim
ln -sfhv ~/.vim/vimrc ~/.config/nvim/init.vim
echo
