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
  sudo pacman -Sy
}

install_via_pacman() {
  local package="$1"
  status_echo "installing package $package..."
  sudo pacman -S --noconfirm "$package"
}

install_git() {
  install_via_pacman 'git'

  create_file_if_not_exists "${HOME}/.bashrc.d/auto-completion"

  create_symbolic_link_if_not_exists '/usr/share/git/completion/'`
    `'git-completion.bash' \
    "${HOME}/.bashrc.d/auto-completion.d/git-completion.bash"

  insert_content_if_not_present "${HOME}/.bashrc.d/auto-completion" \
    'source "${HOME}/.bashrc.d/auto-completion.d/git-completion.bash"'
}

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
