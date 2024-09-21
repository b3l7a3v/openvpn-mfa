#!/bin/bash
set -e

CCD_DIR="/etc/openvpn/ccd/"
start_uid=3000
start_gid=3000

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

### Creating users according to user route configurations
if [ ! -d "$CCD_DIR" ]; then
  echo "Directory $CCD_DIR does not exist"
  exit 1
fi

### Iteration of client configurations (ovpn-routes) in the CCD folder
for file in "$CCD_DIR"/*; do
  username=$(basename "$file")

  if id "$username" &>/dev/null; then
    echo "User $username already exists"
  else
    ### Create a user with incrementable UID and GID
    adduser -D -u "$start_uid" -g "$start_gid" "$username"
    chown  "$start_uid":"$start_gid" /home/$username/.google_authenticator
    chmod 400 /home/$username/.google_authenticator
    echo "User $username created with UID $start_uid and GID $start_gid"
    ### Increment the UID and GID for the following user
    start_uid=$((start_uid + 1))
    start_gid=$((start_gid + 1))
  fi
done

### Checking free uid and gid
#get_next_uid_gid() {
#  local current_uid=$1
#  local current_gid=$2
#
#  while id -u "$current_uid" >/dev/null 2>&1; do
#    current_uid=$((current_uid + 1))
#  done

#  while getent group "$current_gid" >/dev/null 2>&1; do
#    current_gid=$((current_gid + 1))
#  done

#  echo "$current_uid $current_gid"
#}

#for file in "$CCD_DIR"/*; do
#  username=$(basename "$file")

#  if id "$username" &>/dev/null; then
#    echo "User $username already exists"
#  else
#    read next_uid next_gid <<<$(get_next_uid_gid "$start_uid" "$start_gid")
#    adduser -D -u "$next_uid" -g "$next_gid" "$username"
#    chown  "$next_uid":"$next_gid" /home/$username/.google_authenticator
#    chmod 400 /home/$username/.google_authenticator
#    echo "User $username created with UID $next_uid and GID $next_gid"

#    start_uid=$((next_uid + 1))
#    start_gid=$((next_gid + 1))
#  fi
#done

### Startup OpenVPN server
echo "Startup OpenVPN server..."
openvpn --config /etc/openvpn/server.conf
