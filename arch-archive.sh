#!/bin/bash
echo "arch-archive.sh [ALPHA] v0.1"
FILE=/etc/pacman.conf
DIR=/etc/pacman.d

usage(){
echo -e "this script requires rw access to /etc/pacman.d/ and /etc/pacman.conf, and bc to calculates dates
Usage:\tarch-archive.sh { -s | -f n | -u}
\t-f n\tFreeze repo to previous n days, n default to 0
\t-u\tUnfreeze repo and return to current mirrorlist
\t-i\tShow current repo"
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
  echo "replacing occurance of archive to mirrorlist in /etc/pacman.conf"
  sed -i 's/archive/mirrorlist/' /etc/pacman.conf
  pacman -Syyu
}

freeze(){
  echo "linking archive repository"
  days=${1:-0}
  date=$(date --date=@$(echo "$(date +%s)-86400*($days+1)" | bc) +%Y/%m/%d)
  rm /etc/pacman.d/archive -f
  echo -e "SigLevel = PackageRequired\nServer=https://archive.archlinux.org/repos/$date/\$repo/os/\$arch\n" > /etc/pacman.d/archive
  sed -i 's/mirrorlist/archive/' /etc/pacman.conf
  info
  pacman -Syyu
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
  "-i")
    info
    ;;
  *)
    usage
    ;;
esac
