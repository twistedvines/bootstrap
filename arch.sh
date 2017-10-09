#!/bin/bash

source "$(dirname "$0")/util.sh"

SCRIPT_DIR="$(script_dir)"

UTIL_PACKAGES=(
  'extras/bash-completion'
  'community/openbsd-netcat'
  'community/jq'
  'core/curl'
)

SEED_DIRS=(
  "$HOME/.bash_profile.d"
  "$HOME/.bashrc.d/auto-completion.d"
  "$HOME/dev/config"
)

initial_setup() {
  refresh_sudo
  for dir in "${SEED_DIRS[@]}"; do
    status_echo "creating directory $dir..."
    [ -d "$dir" ] || mkdir -p "$dir"
  done
}

install_util() {
  sync_pacman
  for pkg in ${UTIL_PACKAGES[@]}; do
    install_via_pacman "$pkg"
  done
}

sync_pacman() {
  refresh_sudo
  sudo pacman -Sy
}

install_via_pacman() {
  local package="$1"
  refresh_sudo
  status_echo "installing package $package..."
  sudo pacman -S --noconfirm "$package"
}

install_git() {
  install_via_pacman 'git'

  create_bashrc_autocompletion

  create_symbolic_link_if_not_exists '/usr/share/git/completion/'`
    `'git-completion.bash' \
    "${HOME}/.bashrc.d/auto-completion.d/git-completion.bash"
}

# -- SPECIFIC FILE CREATION FUNCTIONS -- #

create_bashrc_autocompletion() {
  create_file_if_not_exists "${HOME}/.bashrc.d/auto-completion" \
    'for file in $(find "${HOME}/.bashrc.d/auto-completion.d/" -type f);'`
    `'do source "$file"; done'
}

# -- GENERIC HELPER FUNCTIONS -- #

create_file_if_not_exists() {
  local filepath="$1"
  shift
  local initial_content="$@"

  if [ ! -f "$filepath" ]; then
    touch "$filepath"
    [ -n "$initial_content" ] && echo "$initial_content" > "$filepath"
  fi
}

create_symbolic_link_if_not_exists() {
  local target="$1"
  local link_name="$2"
  [ ! -e "$link_name" ] && ln -s "$target" "$link_name"
}

insert_content_if_not_present() {
  local filepath="$1"
  shift
  local content="$@"

  if ! [[ "$(cat "$filepath")" =~ "$content" ]]; then
    echo "$content" >> "$filepath"
  fi
}

refresh_sudo() {
  warning_echo 'refreshing sudo session...'
  sudo -v
}
