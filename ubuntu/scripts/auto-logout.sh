#!/bin/bash
# Auto-logout for tty sessions after a period of inactivity
if [[ "$(tty)" =~ /dev/tty[0-9]+ ]] || [[ "$(tty)" =~ /dev/ttyS[0-9]+ ]]; then
  # Set TMOUT to 600 seconds (10 minutes) for tty and ttyS sessions
  export TMOUT=600
  readonly TMOUT
  RED='\033[1;31m'
  NC='\033[0m'
  echo -e "\n\nTo exit the console, press ${RED}CTRL+A${NC} then ${RED}D${NC} to return to the host machine,\nand then press ${RED}CTRL+D${NC} to return to the Lish menu\n\n"
fi