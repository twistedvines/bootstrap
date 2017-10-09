#!/bin/bash

source "$(dirname "$0")/util.sh"

SCRIPT_DIR="$(script_dir)"

UTIL_PACKAGES=(
  'extras/bash-completion'
  'community/openbsd-netcat'
  'community/jq'
  'core/curl'
  'core/pkg-config'
  'core/fakeroot'
)

SEED_DIRS=(
  "$HOME/.bash_profile.d"
  "$HOME/.bashrc.d/auto-completion.d"
  "$HOME/dev/config"
)

RUBIES=('2.4.2')

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

install_git() {
  install_via_pacman 'git'

  create_bashrc_autocompletion

  create_symbolic_link_if_not_exists '/usr/share/git/completion/'`
    `'git-completion.bash' \
    "${HOME}/.bashrc.d/auto-completion.d/git-completion.bash"
}

install_yaourt() {
  umask 0003 # u=rwx,g=rwx,o=r

  git clone 'https://aur.archlinux.org/package-query.git' \
    '/usr/local/src/package-query'
  git clone 'https://aur.archlinux.org/yaourt.git' \
    '/usr/local/src/yaourt'

  umask 0022 # u=rwx,g=rx,o=rx

  cd '/usr/local/src/package-query' && makepkg --noconfirm -si
  cd '/usr/local/src/yaourt' && makepkg --noconfirm -si
}

install_config() {
  clone_repository 'twistedvines/.config'
  install_repository 'twistedvines/.config' "${HOME}/.config"
}

install_vim() {
  install_via_pacman 'extra/vim'
  clone_repository 'twistedvines/.vim'
  install_repository 'twistedvines/.vim' "${HOME}/.vim"
  ln -s "${HOME}/.vim/.vimrc" "${HOME}/.vimrc"
}

install_neovim() {
  install_via_pacman 'community/neovim'
  install_repository 'twistedvines/.vim' "${HOME}/.vim"

  for file in 'autoload' 'colors' 'plugged'; do
    ln -s "${HOME}/.vim/$file" "${HOME}/.config/nvim/${file}" > /dev/null
  done
}

install_tmux() {
  install_via_pacman 'community/tmux'
  clone_repository 'twistedvines/.tmux'
  install_repository 'twistedvines/.tmux' "${HOME}/.tmux"
  ln -s "${HOME}/.tmux/.tmux.conf" "${HOME}/.tmux.conf"
}

install_rbenv() {
  install_via_yaourt 'aur/ruby-build'
  install_via_yaourt 'aur/rbenv'
  eval "$(rbenv init -)"
}

install_rubies() {
  for ruby in ${RUBIES[@]}; do
    status_echo "installing ruby $ruby..."
    rbenv install "$ruby" && \
      rbenv rehash
    rbenv local "$ruby"
    gem install bundler
    status_echo "finished installing ruby $ruby."
  done
}

# -- SPECIFIC FILE CREATION FUNCTIONS -- #

create_bashrc_autocompletion() {
  create_file_if_not_exists "${HOME}/.bashrc.d/auto-completion" \
    'for file in $(find "${HOME}/.bashrc.d/auto-completion.d/" -type f);'`
    `'do source "$file"; done'

  insert_source_line_in_to_bashrc
}

# -- SPECIFIC FILE CONTENT FUNCTIONS -- #

insert_source_line_in_to_bashrc() {
  insert_content_if_not_present "${HOME}/.bashrc" \
    'for file in $(find "$HOME/.bashrc.d/" -type f);'`
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

clone_repository() {
  local repository_name="$1"
  mkdir -p "/usr/local/src/${repository_name}"
  git clone \
    --recurse-submodules \
    "https://github.com/${repository_name}.git" \
    "/usr/local/src/${repository_name}"

  git submodule > /dev/null
  local exit_code=$?
  if [ $exit_code -ne 128 ]; then
    cd "/usr/local/src/${repository_name}" && \
      git submodule update --init --recursive
  fi
}

install_repository() {
  local repository_name="$1"
  local destination="$2"

  if [ -d "${destination}" ]; then
    warning_echo "destination ${destination} already exists:"`
      `" overwriting installation of ${repository_name}."
  fi

  install_tmp_git_tools

  mkdir -p "$destination"
  cd "/usr/local/src/${repository_name}"
  git submodule > /dev/null
  local exit_code=$?

  echo "exit code for $repository_name: $exit_code"

  if [ $exit_code -ne 128 ]; then
    echo "using git-archive!"
    /tmp/git-tools/git-archive-all/git-archive-all.sh --format tar -- - | \
    tar -x -C "${destination}"
  else
    git archive HEAD | tar -x -C "${destination}"
  fi
}

refresh_sudo() {
  warning_echo 'refreshing sudo session...'
  sudo -v
}

install_tmp_git_tools() {
  ! [ -d /tmp/git-tools ] && mkdir /tmp/git-tools
  ! [ -d /tmp/git-tools/git-archive-all ] && \
    git clone https://github.com/meitar/git-archive-all.sh.git \
    /tmp/git-tools/git-archive-all
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

install_via_yaourt() {
  local package="$1"
  status_echo "installing package $package via yaourt..."
  yaourt -S --noconfirm "$package"
}
