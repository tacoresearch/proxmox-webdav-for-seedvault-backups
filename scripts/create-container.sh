#!/bin/bash
# Run on the Proxmox host as root.
# Requirements: the --mp0 is calling a mount point for the fivehundedsata ZFS pool and it must exist before running this script, and the Debian 13 LXC template must be downloaded.
# Settings: CTID, DATA_SIZE
# Actions: Creates the unprivileged Debian 13 LXC that hosts the Seedvault WebDAV server.
set -euo pipefail

CTID=${CTID:-506}
DATA_SIZE=${DATA_SIZE:-100}   # GB, on the fivehundedsata ZFS pool
TEMPLATE=${TEMPLATE:-local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst}

pct create "$CTID" "$TEMPLATE" \
  --hostname seedvault5 \
  --unprivileged 1 \
  --features nesting=1 \
  --cores 1 --memory 512 --swap 256 \
  --rootfs local-lvm:4 \
  --mp0 "fivehundedsata:${DATA_SIZE},mp=/srv/webdav,backup=1" \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp,ip6=auto,type=veth \
  --onboot 1 \
  --timezone America/New_York \
  --tags 'seedvault,webdav'

pct start "$CTID"
sleep 8
pct exec "$CTID" -- ip -br a
