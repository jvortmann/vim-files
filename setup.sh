#!/bin/bash

./symlink.sh
echo "Installing Plugins"
echo

vim -c "PlugInstall | qa" && \
  echo "Press anything to continue" && read && \
  vim
