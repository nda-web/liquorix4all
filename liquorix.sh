#!/bin/bash

set -euo pipefail

log() {
  local level=$1
  local message=$2

  echo ""
  case "$level" in
      INFO)  printf "\033[32m[INFO ] %s\033[0m\n" "$message" ;; # green
      WARN)  printf "\033[33m[WARN ] %s\033[0m\n" "$message" ;; # yellow
      ERROR) printf "\033[31m[ERROR] %s\033[0m\n" "$message" ;; # red
      *) printf "[UNKNOWN] %s\n" "$message" ;;
  esac
  echo ""
}

if [ "$(id -u)" -ne 0 ]; then
    log ERROR "You must run this script as root!"
    exit 1
fi

if [ "$(uname -m)" != x86_64 ]; then
    log ERROR "Architecture not supported"
    exit 1
fi

export DEBIAN_FRONTEND="noninteractive"
export NEEDRESTART_SUSPEND="*"

# Lógica de instalación para distribuciones Debian/derivadas
apt-get update && apt-get install -y --no-install-recommends \
    curl gpg ca-certificates

mkdir -p /etc/apt/{sources.list.d,keyrings}
chmod 0755 /etc/apt/{sources.list.d,keyrings}

keyring_url='https://liquorix.net/liquorix-keyring.gpg'
keyring_path='/etc/apt/keyrings/liquorix-keyring.gpg'
curl "$keyring_url" | gpg --batch --yes --output "$keyring_path" --dearmor
chmod 0644 "$keyring_path"

log INFO "Liquorix keyring added to $keyring_path"

apt-get install apt-transport-https lsb-release -y

repo_file="/etc/apt/sources.list.d/liquorix.list"
repo_code="$(
    apt-cache policy | grep o=Debian | grep -Po 'n=\w+' | cut -f2 -d= |\
    sort | uniq -c | sort | tail -n1 | awk '{print $2}'
)"
repo_line="[arch=amd64 signed-by=$keyring_path] https://liquorix.net/debian $repo_code main"
echo "deb $repo_line"      > $repo_file
echo "deb-src $repo_line" >> $repo_file

apt-get update -y

log INFO "Liquorix repository added successfully to $repo_file"

apt-get install -y linux-image-liquorix-amd64 linux-headers-liquorix-amd64

log INFO "Liquorix kernel installed successfully"
