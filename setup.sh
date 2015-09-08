#!/bin/bash

./symlink.sh
echo "Installing Plugins"
vim -c "PlugInstall | qa" && vim
