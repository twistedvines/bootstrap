#!/bin/bash

source "$(dirname "$0")/util.sh"

SCRIPT_DIR="$(script_dir)"

TAPS=(
  "homebrew/services" "homebrew/versions" "homebrew/cask"
  "brona/iproute2mac"
)

BREW_UTIL_PACKAGES=(bash-completion curl netcat iterm2 iproute2mac jq)
BREW_PACKAGES=(vagrant packer atom postman firefox google-chrome alfred)

SEED_DIRS=("$HOME/.bash_profile.d" "$HOME/dev/config")

RUBIES=("2.4.1")

initial_setup() {
  for dir in "${SEED_DIRS[@]}"; do
    status_echo "creating directory $dir..."
    [ -d "$dir" ] || mkdir "$dir"
  done
}

install_brew() {
  status_echo "installing brew..."
  if [ -z "$(which brew)" ]; then
    local script="$(2>&1 curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    local install_result="$(echo "$script" | 2>&1 ruby)"
  fi

  [ -n "$(which brew)" ] && return 0
  for tap in "$TAPS"; do
    status_echo "tapping $tap..."
    local tap_result="$(2>&1 brew tap "$tap")"
  done
  status_echo "updating brew..."
  local update_result="$(2>&1 brew update)"
}

install_util(){
  batch_install "$BREW_UTIL_PACKAGES"
}

install_git() {
  install_via_brew git

  add_bash_profile_fragment 'git_autocompletion'
}

install_rbenv() {
  install_via_brew rbenv && eval "$(rbenv init -)"
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
  git clone https://github.com/twistedvines/.config "$HOME/dev/config/.config"
  cd "$HOME/dev/config/.config"
  git submodule init && git submodule update
  ln -s "$HOME/dev/config/.config" "$HOME/.config"
}

# install neovim
# clone-down my vim settings
install_neovim() {
  install_via_brew neovim
  git clone https://github.com/twistedvines/.vim "$HOME/dev/config/.vim"
  [ -h "$HOME/.vim" ] || ln -s "$HOME/dev/config/.vim" "$HOME/.vim"
  [ -h "$HOME/.vimrc" ] || ln -s "$HOME/dev/config/.vim/.vimrc" "$HOME/.vimrc"

  if [ -d "$HOME/.config/nvim" ]; then
    for vim_conf_dir in "autoload" "colors" "plugged"; do
      [ -h "$HOME/.config/nvim/$vim_conf_dir" ] || ln -s "$HOME/.vim/$vim_conf_dir" "$HOME/.config/nvim/$vim_conf_dir"
    done
  fi

  local plugin_install="$(/usr/local/bin/nvim +PlugInstall +qall)"
}

# install tmux
install_tmux() {
  install_via_brew tmux
}

install_virtualbox() {
  install_via_brew virtualbox
}

# install docker-toolbox
  # fetch the docker-machine.plist from github
install_docker_toolbox() {
  status_echo "installing docker-toolbox..."
  install_via_brew docker-toolbox cask
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
  add_bash_profile_fragment 'docker-machine-env'
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

  local cmd="brew $args install $package"

  status_echo "Attempting to install $package using brew $args..."
  local brew_install=$(2>&1 $cmd)
  local brew_install_exit_status=$?

  if [ "$(echo "$brew_install" | grep "No available formula")" ]; then
    error_echo "Could not find package $package in brew repos."
    return 1
  elif [ "$(echo "$brew_install" | grep "already installed")" ]; then
    warning_echo "Package $package has already been installed."
    return 2
  elif [ "$(echo "$brew_install" | grep "already an App")" ]; then
    warning_echo "Package $package has already been installed, but not by brew" \
      " - check your Applications directory."
    return 3
  elif [ $brew_install_exit_status -eq 0 ]; then
    status_echo "Package '$package' installed successfully."
    return 0
  else
    error_echo "Fatal error occured!"
    error_echo "dump: ${brew_install}"
    return 127
  fi
}

add_bash_profile_fragment(){
  local fragment="$1"
  cp "${SCRIPT_DIR}/.bash_profile.d/$fragment" "$HOME/.bash_profile.d/$fragment"
  if ! [ "$(grep "$fragment" "$HOME/.bash_profile")" ]; then
    echo "source \${HOME}/.bash_profile.d/$fragment" \
      >> "$HOME/.bash_profile"
  fi
}
