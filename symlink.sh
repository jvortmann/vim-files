#!/bin/bash

echo "Setting symlinks for default configurations"
ln -sfhv $(pwd) ~/.vim
ln -sfhv ~/.vim/vimrc ~/.vimrc
ln -sfhv ~/.vim/gvimrc ~/.gvimrc

echo "Setting symlinks for NVim"
ln -sfhv ~/.vim ~/.nvim
ln -sfhv ~/.nvim/vimrc ~/.nvimrc
