#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
IP=$(ip -4 -o addr show eth0 | awk '{print $4}' | cut -d/ -f1)

apt-get update -qq
apt-get install -y -qq apache2 apache2-utils openssl >/dev/null

# Storage
mkdir -p /srv/webdav/data /var/lib/dav
chown -R www-data:www-data /srv/webdav/data /var/lib/dav

# Self-signed cert, 10 years, valid for the IP and hostname
mkdir -p /etc/ssl/webdav
if [ ! -f /etc/ssl/webdav/cert.pem ]; then
  openssl req -x509 -newkey rsa:3072 -sha256 -days 3650 -nodes \
    -keyout /etc/ssl/webdav/key.pem -out /etc/ssl/webdav/cert.pem \
    -subj "/CN=seedvault5" \
    -addext "subjectAltName=IP:${IP},DNS:seedvault5,DNS:seedvault5.local" 2>/dev/null
  chmod 600 /etc/ssl/webdav/key.pem
fi

# Credentials
if [ ! -f /etc/apache2/webdav.htpasswd ]; then
  PASS=$(openssl rand -base64 18 | tr -d '/+=' | cut -c1-20)
  htpasswd -cbB /etc/apache2/webdav.htpasswd seedvault "$PASS" >/dev/null
  chown root:www-data /etc/apache2/webdav.htpasswd; chmod 640 /etc/apache2/webdav.htpasswd
  printf 'URL: https://%s/webdav/\nUser: seedvault\nPassword: %s\n' "$IP" "$PASS" > /root/webdav-credentials.txt
  chmod 600 /root/webdav-credentials.txt
fi

cat > /etc/apache2/sites-available/webdav.conf <<CONF
DavLockDB /var/lib/dav/lockdb

<VirtualHost *:80>
    ServerName seedvault5
    Redirect permanent / https://${IP}/
</VirtualHost>

<VirtualHost *:443>
    ServerName seedvault5
    DocumentRoot /srv/webdav/data
    SSLEngine on
    SSLCertificateFile /etc/ssl/webdav/cert.pem
    SSLCertificateKeyFile /etc/ssl/webdav/key.pem

    # Large backup chunks
    LimitRequestBody 0
    Timeout 600

    Alias /webdav /srv/webdav/data
    <Directory /srv/webdav/data>
        Dav On
        Options -Indexes
        AllowOverride None
        AuthType Basic
        AuthName "Seedvault"
        AuthBasicProvider file
        AuthUserFile /etc/apache2/webdav.htpasswd
        Require valid-user
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/webdav-error.log
    CustomLog \${APACHE_LOG_DIR}/webdav-access.log combined
</VirtualHost>
CONF

a2enmod -q ssl dav dav_fs auth_basic headers >/dev/null
a2dissite -q 000-default >/dev/null || true
a2ensite -q webdav >/dev/null
apache2ctl configtest
systemctl enable --now apache2 >/dev/null
systemctl restart apache2
echo "OK ip=$IP"
openssl x509 -in /etc/ssl/webdav/cert.pem -noout -fingerprint -sha256
