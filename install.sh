#!/bin/bash

DISTRO="$1"

case "$DISTRO"
  "osx")
    source "$(dirname "$0")/macos.sh"
    install_for_mac
    ;;
esac

install_for_mac(){
  initial_setup
  install_brew
  install_tools
  install_git
  install_rbenv
  install_rubies
  install_config
  install_neovim
  install_tmux
  install_docker_toolbox
  install_tools
}
