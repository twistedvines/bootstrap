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
  install_node_packages
}

install_for_arch() {
  initial_setup
  install_util
  install_git
  install_yaourt
  install_config
  install_vim
  install_neovim
  install_tmux
  install_rbenv
  install_rubies
  install_docker
  install_exa
  install_fonts
  install_other_packages
}

DISTRO="$1"

if [[ "$0" =~ "-bash" ]]; then
  echo "You need to run this script via 'bash'."
else
  source "$(dirname "$0")/.env"
  case "$DISTRO" in
    osx)
      source "$(dirname "$0")/macos.sh"
      install_for_mac
      ;;
    arch)
      source "$(dirname "$0")/arch.sh"
      install_for_arch
      ;;
  esac
fi
