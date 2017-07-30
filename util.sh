#!/bin/bash

# This function exits on any exit code other than 0.
exit_on_error() {
  local exit_code=$1
  if [ $exit_code -ne 0 ]; then
    exit $exit_code
  fi
}

script_dir() {
  if [[ "$0" =~ '-bash' ]]; then
    echo "$(pwd)"
    return 0
  fi
  cd $(dirname "$0")
  pwd
}

refresh_sudo() {
  sudo -v
}

distro() {
  local distro_name="$(uname -s)"
  case "$distro_name" in
    "darwin")
      if [ -z "$DISTRO" ]; then
        export DISTRO='osx'
      fi
        echo "$DISTRO"
      ;;
    *) exit 1;;
  esac
}


status_echo() {
  echo -e "$(bash_colour green)${@}$(bash_colour)"
}

warning_echo() {
  echo -e "$(bash_colour orange)${@}$(bash_colour)"
}

error_echo() {
  (>&2 echo -e "$(bash_colour red)${@}$(bash_colour)")
}

bash_colour() {
  local colour_prefix='\033[0'
  case "$1" in
    red)
      local colour="${colour_prefix};31m";;
    blue)
      local colour="${colour_prefix};34m";;
    green)
      local colour="${colour_prefix};32m";;
    orange)
      local colour="${colour_prefix};33m";;
    *)
      local colour="${colour_prefix}m";;
  esac
  echo $colour
}
