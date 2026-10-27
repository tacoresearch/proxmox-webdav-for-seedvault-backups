# webdavx5
This is a script that deploys a proxmox self-hosted Apache based WebDAV target for Seedvault backups, used on GrapheneOS, reached through DAVx⁵.
Runs as an unprivileged LXC on the Proxmox host `node5` (10.10.10.94).

customize 'create-container.sh' first before running.

## Deploy using this script

From a machine with SSH access to the Proxmox host:

```bash
ssh root@10.10.10.94 'bash -s' < scripts/create-container.sh
ssh root@10.10.10.94 'pct exec 506 -- bash -s' < scripts/setup-webdav.sh
ssh root@10.10.10.94 'bash -s' < scripts/test-webdav.sh
```

`setup-webdav.sh` is safe to re-run; it keeps an existing certificate and password.
## Account
| Item | Value |
|---|---|
| URL | `https://10.10.10.159/webdav/` |
| User | `seedvault` |

## Obtain Password
The password is not in this repo. Read it with:

```bash
ssh root@10.10.10.94 "pct exec 506 -- cat /root/webdav-credentials.txt"
```

## Phone setup

1. Install DAVx⁵, suggest finding on FDROID store.
2. Open the menu, then WebDAV mounts, then +, and enter the URL, user and password above.
   Do not use "Add account"; that wizard only finds CalDAV/CardDAV and will report it couldn't find a service.
3. Accept the self-signed certificate after checking its fingerprint.
4. Settings, System, Backup (Seedvault): pick the DAVx⁵ mount, save the 12-word recovery code, run a backup.

Seedvault's built-in WebDAV option is still beta and rejects self-signed certificates, so DAVx⁵ is used instead.


## Current deployment

| Item | Value |
|---|---|
| Container | 506, `seedvault5` (Debian 13) |
| IP | 10.10.10.159 (DHCP, MAC `BC:24:11:34:91:71`; reserve it in the router) |
| URL | `https://10.10.10.159/webdav/` |
| User | `seedvault` |
| Storage | 100 GB on `fivehundedsata`, mounted at `/srv/webdav` |
| TLS | Self-signed, 10 years, SHA-256 `D0:C4:5D:74:...:1F:9A:3A:23:ED` |

## Host fixes made on node5 (2026-10-26)

- Gateway in `/etc/network/interfaces` was `10.10.0.1` (unreachable); changed to `10.10.10.1`. Backup: `/etc/network/interfaces.bak-gateway`.
- `/etc/resolv.conf` pointed at `192.168.0.1` (not on this network); now `10.10.10.185` then `10.10.10.1`. Backup: `/etc/resolv.conf.bak-dns`.
- With no route out, chrony could not sync and the clock was six months behind, which broke apt signature checks. Clock resynced and written to the RTC.
- The RTC read 2009 before the fix, so the CMOS battery is probably dead.
