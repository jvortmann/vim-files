#!/bin/bash

echo "Installing Plugins"
vim -c "PlugInstall | qa"

echo "Installing Fonts to ~/Library/Fonts"
cp extra/fonts/SourceCodePro/*.otf ~/Library/Fonts
