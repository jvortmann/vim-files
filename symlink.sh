#!/bin/bash

echo; echo ">> Removing existing configs"
rm -r ~/.vim

echo; echo ">> Symlink default configurations"
ln -sfnv "$(pwd)" ~/.vim

echo; echo ">> Creating ~/.config"
mkdir -p ~/.config

echo; echo ">> Symlink NVim configuration"
ln -sfnv "$(pwd)" ~/.config/nvim

echo
