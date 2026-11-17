#!/bin/bash

./symlink.sh
echo "Installing Plugins"
echo

nvim -c "PlugInstall | qa" && \
  echo "Press anything to continue" && read && \
  nvim
