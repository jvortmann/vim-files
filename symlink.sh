#!/bin/bash

echo "Setting symlinks for default configurations"
ln -sfhv $(pwd) ~/.vim
ln -sfhv ~/.vim/vimrc ~/.vimrc
ln -sfhv ~/.vim/gvimrc ~/.gvimrc
