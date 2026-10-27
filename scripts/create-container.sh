#!/bin/bash
# Run on the Proxmox host (node5) as root.
# Creates the unprivileged Debian 13 LXC that hosts the Seedvault WebDAV server.
set -euo pipefail

CTID=${CTID:-506}
TEMPLATE=${TEMPLATE:-local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst}
DATA_SIZE=${DATA_SIZE:-100}   # GB, on the fivehundedsata ZFS pool

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
