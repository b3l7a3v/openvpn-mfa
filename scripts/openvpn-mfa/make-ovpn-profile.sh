#!/bin/bash

### Request certificate for a user
docker exec -it openvpn-mfa bash -c "easyrsa build-client-full $1 nopass"

### Check a free address 
# (DHCP)

### Create a ccd file
sudo tee /opt/openvpn-mfa-ccd/$1 <<EOF
push "route 10.11.0.0 255.255.0.0"
EOF

### Create a user in container
docker exec -it openvpn-mfa bash -c "adduser -D $1"

### Create a google-auth private key
docker exec -it openvpn-mfa bash -c "su - $1 -c 'google-authenticator --time-based --no-confirm --window=5 --rate-limit=10 --rate-time=60 --disallow-reuse --force'"

### Create .ovpn file
tee /opt/openvpn-mfa-profiles/$1.ovpn <<EOF
#####
### $1
#####
client
remote vpn.bloomex.ca 1199
dev tun
proto udp
auth SHA512
nobind
remote-cert-tls server
persist-key
persist-tun
verb 3
auth-nocache
auth-user-pass
reneg-sec 0
# keepalive 10 50
# key-direction 1
# resolv-retry infinite
# data-ciphers AES-256-GCM:AES-128-GCM
# compress lz4
<ca>
`cat /root/pki/ca.crt `
</ca>
<cert>
`grep -Pzo '(?s)-----BEGIN CERTIFICATE-----(.*)-----END CERTIFICATE-----' /root/pki/issued/$1.crt`
</cert>
<key>
`cat /root/pki/private/$1.key`
</key>
EOF
