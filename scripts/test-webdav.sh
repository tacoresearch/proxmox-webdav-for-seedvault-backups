#!/bin/bash
# Run on the Proxmox host (node5) as root.
# Exercises auth, MKCOL, PUT, PROPFIND, GET, MOVE and DELETE against the server.
set -uo pipefail

CTID=${CTID:-506}
IP=$(pct exec "$CTID" -- ip -4 -o addr show eth0 | awk '{print $4}' | cut -d/ -f1)
PASS=$(pct exec "$CTID" -- awk -F': ' '/^Password/{print $2}' /root/webdav-credentials.txt)
U=https://$IP/webdav
c() { curl -sk -o /dev/null -w '%{http_code}' "$@"; }

echo "anon GET:      $(c $U/)   (expect 401)"
echo "wrong pass:    $(c -u seedvault:nope $U/)   (expect 401)"
echo "MKCOL:         $(c -u "seedvault:$PASS" -X MKCOL $U/test/)   (expect 201)"
head -c 50M /dev/urandom > /tmp/t.bin
echo "PUT 50MB:      $(c -u "seedvault:$PASS" -T /tmp/t.bin $U/test/t.bin)   (expect 201)"
echo "PROPFIND:      $(c -u "seedvault:$PASS" -X PROPFIND -H 'Depth: 1' $U/test/)   (expect 207)"
curl -sk -u "seedvault:$PASS" $U/test/t.bin -o /tmp/t2.bin
cmp -s /tmp/t.bin /tmp/t2.bin && echo "GET matches:   yes" || echo "GET matches:   NO"
echo "MOVE:          $(c -u "seedvault:$PASS" -X MOVE -H "Destination: $U/test/t3.bin" $U/test/t.bin)   (expect 201)"
echo "DELETE:        $(c -u "seedvault:$PASS" -X DELETE $U/test/)   (expect 204)"
echo "http->https:   $(c http://$IP/)   (expect 301)"
rm -f /tmp/t.bin /tmp/t2.bin
