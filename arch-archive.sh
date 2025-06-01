#!/bin/bash
echo "arch-archive.sh [ALPHA] v0.1"
FILE=/etc/pacman.conf
DIR=/etc/pacman.d

usage(){
echo -e "this script requires rw access to /etc/pacman.d/ and /etc/pacman.conf, and bc to calculates dates
Usage:\tarch-archive.sh [ -h | -f [n] | -u | -s ]
\t-h\tShow this help
\t-f n\tFreeze repo to previous n days, n default to 0
\t-u\tUnfreeze repo and return to current mirrorlist
\t-s\tUpdate now & Freeze again"
}

info(){
  echo -n "pacman is currently "
  if [[ -L /etc/pacman.d/archive ]]; then
    echo "unfreezed"
  else
    echo "freezed to $(grep repos /etc/pacman.d/archive | sed 's/.*repos\///; s/\/$repo\/.*$//')"
  fi
}

unfreeze(){
  info
  echo "replacing occurance of archive to mirrorlist in /etc/pacman.conf"
  sed -i 's/archive/mirrorlist/' /etc/pacman.conf
  pacman -Syu --noconfirm
}

freeze(){
  echo "linking archive repository"
  days=${1:-1}
  date=$(date --date=@$(echo "$(date +%s)-61200*($days)" | bc) +%Y/%m/%d)
  rm /etc/pacman.d/archive -f
  echo -e "SigLevel = PackageRequired\nServer=https://archive.archlinux.org/repos/$date/\$repo/os/\$arch\n" > /etc/pacman.d/archive
  sed -i 's/mirrorlist/archive/' /etc/pacman.conf
  pacman -Syu --noconfirm
  info
}

if [[ "$EUID" -ne 0 || ! -r "$FILE" && ! -w "$FILE" || ! -w "$DIR" ]] then 
  usage
  exit
fi

case "$1" in
  "-f")
    freeze $2
    ;;
  "-u")
    unfreeze
    ;;
  "-s")
    unfreeze
    freeze
    ;;
  *)
    info
    usage
    ;;
esac
