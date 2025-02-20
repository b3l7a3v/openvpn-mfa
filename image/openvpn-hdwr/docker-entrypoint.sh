#!/bin/bash
set -e

CCD_DIR="/etc/openvpn/ccd/"

### Check for existing PKI
if [[ -f /root/pki/ca.crt ]]; then
  echo 'PKI already set up.'
else
  ### Override pki directory for build new CA
  export EASYRSA_PKI=/pki
  echo "Check EASYRSA_PKI -> $EASYRSA_PKI"

  ### Enable non-interactive mode for easyrsa
  export EASYRSA_BATCH=1
  echo "Check EASYRSA_BATCH -> $EASYRSA_BATCH"

  ### Create an CA
  echo "Create an CA..."
  easyrsa init-pki

  ### Build certs
  echo "Build certs..."
  easyrsa build-ca nopass

  ### Create revokation-list
  echo "Create revokation-list..."
  easyrsa gen-crl

  ### Creating the request for CA from openvpn-server
  echo "Creating the request for CA from openvpn-server..."
  easyrsa gen-req vpn-server nopass

  ### Signing the request
  echo "Signing the request..."
  easyrsa sign-req server vpn-server

  ### Generate Diffie-Hellman key
  echo "Generate Diffie-Hellman key..."
  easyrsa gen-dh

  ### Create HMAC-key
  echo "Create HMAC-key..."
  openvpn --genkey > /etc/openvpn/ta.key

  ### Copy pki into mounted dir
  echo "Copy pki into mounted dir..."
  cp -rf /pki/* /root/pki
  echo "Copying to /root/pki completed!"

  ### Copy configs into ovpn dir
  echo "Copy configs into ovpn dir..."
  mkdir -p /etc/openvpn/pki/
  cp -f /root/pki/ca.crt /etc/openvpn/pki/ca.crt
  cp -f /root/pki/issued/vpn-server.crt /etc/openvpn/pki/server.crt
  cp -f /root/pki/private/vpn-server.key /etc/openvpn/pki/server.key
  cp -f /root/pki/dh.pem /etc/openvpn/pki/dh.pem
  cp -f /root/pki/crl.pem /etc/openvpn/pki/crl.pem
  echo "Copying to /etc/openvpn completed!"
fi

echo  "Startup syslogd service..."
syslogd -O /var/log/messages -D && tail -f /var/log/messages &

### Startup OpenVPN server
echo "Startup OpenVPN server..."
openvpn --config /etc/openvpn/server.conf
