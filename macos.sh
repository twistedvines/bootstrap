#!/bin/bash

source "$(dirname "$0")/util.sh"

SCRIPT_DIR="$(script_dir)"

TAPS=("homebrew/services" "homebrew/versions" "homebrew/cask")
BREW_UTIL_PACKAGES=(bash-completion curl netcat iterm2)
BREW_PACKAGES=(vagrant packer atom postman)

SEED_DIRS=("$HOME/.bash_profile.d" "$HOME/dev")

RUBIES=("2.4.1")

initial_setup() {
  for dir in "${SEED_DIRS[@]}"; do
    status_echo "creating directory $dir..."
    [ -d "$dir" ] || mkdir "$dir"
  done
}

install_brew() {
  status_echo "installing brew..."
  [ -z "$(which brew)" ] && \
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install | ruby
  [ -n "$(which brew)" ] && return 0
  for tap in "$TAPS"; do
    status_echo "tapping $tap..."
    brew tap "$tap"
  done
  status_echo "updating brew..."
  brew update
}

install_util(){
  batch_install "$BREW_UTIL_PACKAGES"
}

# install brew-git
  # configure autocompletion
install_git() {
  brew install git
  cp "$(dirname "$0")/.bash_profile.d/git_autocompletion" \
    "$HOME/.bash_profile.d/"
  if ![ "$(grep "git_autocompletion" "$HOME/.bash_profile")" ]; then
    echo "source $HOME/.bash_profile.d/git_autocompletion" >> \
      "$HOME/.bash_profile"
  fi
}

install_rbenv() {
  brew install rbenv && eval "$(rbenv init -)"
}

install_rubies() {
  for ruby in "$RUBIES"; do
    status_echo "installing ruby $ruby..."
    rbenv install "$ruby" && \
      rbenv rehash
    rbenv local "$ruby"
    gem install bundler
    status_echo "finished installing $ruby."
  done
}

install_config() {
  git clone https://github.com/twistedvines/.config "$HOME/dev/.config"
  git submodule update "$HOME/dev/.config"
  ln -s "$HOME/dev/.config" "$HOME/.config"
}

# install neovim
  # clone-down my vim settings
install_neovim() {
  brew install neovim
  git clone https://github.com/twistedvines/.vim "$HOME/dev/.vim"
  ln -s "$HOME/dev/.vim" "$HOME/.vim"
  ln -s "$HOME/.vim/.vimrc" "$HOME/.vimrc"
}

# install tmux
install_tmux() {
  brew install tmux
}

# install docker-toolbox
  # fetch the docker-machine.plist from github
install_docker_toolbox() {
  status_echo "installing docker-toolbox..."
  brew cask install docker-toolbox
  if ! [ "$(docker-machine ls | grep default)" ]; then
    status_echo "creating boot2docker VM 'default'..."
    docker-machine create --driver "virtualbox" --virtualbox-cpu-count "2" \
      --virtualbox-disk-size "30000" --virtualbox-memory "6144" default
  else
    status_echo "default boot2docker VM already resides on this system."
  fi
  status_echo "configuring launchctl..."
  cp "${SCRIPT_DIR}/files/com.docker.machine.default.plist" \
    "$HOME/Library/LaunchAgents"
  if ! [[ "$TERM" =~ "screen" ]]; then
    launchctl load "$HOME/Library/LaunchAgents/com.docker.machine.default.plist"
  else
    warning_echo "could not load docker agent plist file: " \
      "this script is being run from a terminal multiplexer!"
  fi
  status_echo "done."
}

install_tools(){
  batch_install "${BREW_PACKAGES[@]}"
}

# helper functions

batch_install(){
  local packages=$@
  for pkg in ${packages[@]}; do
    install_via_brew "$pkg"
    local result="$?"
    [ $result -eq 1 ] && install_via_brew "$pkg" "cask"
  done
}

install_via_brew(){
  local package="$1"
  shift
  local args="$@"

  status_echo "attempting to install $package using brew $args..."
  local brew_install=$(2>&1 brew install "$args" "$package")

  if [ "$(echo "$brew_install" | grep "No available formula")" ]; then
    error_echo "Could not find package $package in brew repos."
    return 1
  elif [ "$(echo "$brew_install" | grep "already installed")" ]; then
    warning_echo "Package $package has already been installed."
    return 2
  else
    error_echo "Fatal error occured!"
    return 127
  fi
}
