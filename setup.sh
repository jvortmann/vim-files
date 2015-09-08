#!/bin/bash

echo "Installing Plugins"
vim -c "PlugInstall | qa" && vim
