#!/bin/bash

install_for_mac(){
  initial_setup
  install_brew
  install_util
  install_git
  install_rbenv
  install_rubies
  install_config
  install_neovim
  install_tmux
  install_virtualbox
  install_docker_toolbox
  install_tools
}

DISTRO="$1"

if [[ "$0" =~ "-bash" ]]; then
  echo "You need to run this script via 'bash'."
else
  case "$DISTRO" in
    osx)
      source "$(dirname "$0")/macos.sh"
      install_for_mac
      ;;
  esac
fi
