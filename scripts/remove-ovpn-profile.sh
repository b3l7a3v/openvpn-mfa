#!/bin/bash

### Remove user from container
echo "removed -> user $1  from openvpn container"
docker exec -it openvpn bash -c "deluser --remove-home $1"

### Remove certificate for a user
echo "removed -> /root/pki/issued/$1.crt"
rm -f /root/pki/issued/$1.crt

echo "removed -> /root/pki/private/$1.key"
rm -f /root/pki/private/$1.key

echo "removed -> /root/pki/reqs/$1.req"
rm -f /root/pki/reqs/$1.req

echo "removed -> /root/pki/inline/$1.inline"
rm -f /root/pki/inline/$1.inline

### Release a free ip-address 
# (DHCP)

### Remove a ccd file
echo "removed -> /opt/openvpn-ccd/$1"
rm -f /opt/openvpn-ccd/$1

### Remove a google-auth private key
echo "removed -> /opt/openvpn-mfa/$1"
rm -rf /opt/openvpn-mfa/$1

### Remove .ovpn file
echo "removed -> /opt/openvpn-profiles/$1.ovpn"
rm -f /opt/openvpn-profiles/$1.ovpn

