#!/usr/bin/env bash

# set linting rules
# shellcheck disable=SC2059
# shellcheck disable=SC2154

BLUE='\033[1;34m'
GREEN='\33[92m'
ORANGE='\033[38;5;208m'
RED='\033[0;91m'
WHITE='\033[1;37m'
YELLOW='\033[93m'

# Logging
log() {
  timestamp=$(date -u "+%Y-%m-%d %H:%M:%S")
  stream='>&1'

  if [ $# -eq 2 ]; then
    case "${1,,}" in
      'error') colour=$RED
               level='ERROR'
               stream='>&2' ;;
      'warn' ) colour=$ORANGE
               level='WARN' ;;
      'pass' ) colour=$GREEN
               level='PASS' ;;
      'info' ) colour=$BLUE
               level='INFO' ;;
      'debug') colour=$YELLOW
               level='DEBUG' ;;
           * ) colour=$BLUE
               level='INFO' ;;
    esac

    message=$2

  else
    colour=$BLUE
    level='INFO'
    message=$1
  fi

  if [[ $level == 'DEBUG' && ${DEBUG,,} != 'true' ]]; then
    return 0
  fi

  printf "$timestamp ${colour}[$level]${WHITE} $message \n" $stream
}
export -f log
