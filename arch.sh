#!/bin/bash

source "$(dirname "$0")/util.sh"

SCRIPT_DIR="$(script_dir)"

UTIL_PACKAGES=(
  'extras/bash-completion'
  'community/openbsd-netcat'
  'community/jq'
)

SEED_DIRS=("$HOME/.bash_profile.d" "$HOME/dev/config")

initial_setup() {
  for dir in "${SEED_DIRS[@]}"; do
    status_echo "creating directory $dir..."
    [ -d "$dir" ] || mkdir -p "$dir"
  done
}
