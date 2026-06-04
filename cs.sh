#!/bin/bash

set -e

echo "========================================"
echo " X-Road Security Server Installer"
echo "========================================"

# Variables
XR_ADMIN="xroadadmin"
HOSTNAME_FQDN=$(hostname -f)

# Actualizar sistema
apt update && apt upgrade -y

# Configurar locale
apt install -y locales lsb-release curl gnupg ufw

locale-gen en_US.UTF-8

if ! grep -q "LC_ALL=en_US.UTF-8" /etc/environment; then
    echo "LC_ALL=en_US.UTF-8" >> /etc/environment
fi

# Crear usuario administrador
if ! id "$XR_ADMIN" &>/dev/null; then
    adduser --disabled-password --gecos "" $XR_ADMIN
fi

# Agregar llave GPG oficial
curl -fsSL https://x-road.eu/gpg/key/public/niis-artifactory-public.gpg \
| tee /usr/share/keyrings/niis-artifactory-keyring.gpg > /dev/null

# Agregar repositorio
echo "deb [signed-by=/usr/share/keyrings/niis-artifactory-keyring.gpg] \
https://artifactory.niis.org/xroad-release-deb \
$(lsb_release -sc)-current main" \
> /etc/apt/sources.list.d/xroad.list

apt update

# Firewall
ufw --force enable

# Administración
ufw allow 22/tcp
ufw allow 4000/tcp

# Comunicación X-Road
ufw allow 5500/tcp
ufw allow 5577/tcp

# Servicios
ufw allow 80/tcp
ufw allow 443/tcp

# IS Access Points
ufw allow 8080/tcp
ufw allow 8443/tcp

# PostgreSQL local
apt install -y postgresql

systemctl enable postgresql
systemctl start postgresql

# Instalar Security Server
DEBIAN_FRONTEND=noninteractive apt install -y xroad-securityserver

# Habilitar servicios
systemctl enable xroad-signer
systemctl enable xroad-proxy
systemctl enable xroad-confclient
systemctl enable xroad-monitor
systemctl enable xroad-proxy-ui-api

systemctl restart xroad-signer
systemctl restart xroad-proxy
systemctl restart xroad-confclient
systemctl restart xroad-monitor
systemctl restart xroad-proxy-ui-api

echo ""
echo "========================================"
echo " INSTALACION COMPLETADA"
echo "========================================"
echo ""
echo "Verifique:"
echo "https://${HOSTNAME_FQDN}:4000"
echo ""
echo "Servicios:"
systemctl list-units "xroad-*"
