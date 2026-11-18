#!/bin/bash

./symlink.sh
echo "Installing Plugins"
echo

nvim --headless "+Lazy! restore" +qa && \
  echo "Press anything to continue" && read && \
  nvim
