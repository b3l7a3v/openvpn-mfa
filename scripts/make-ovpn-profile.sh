#!/bin/bash

### Request certificate for a user
docker exec -it openvpn bash -c "easyrsa build-client-full $1 nopass"

### Check a free address 
# (DHCP)

### Create a ccd file
sudo tee /opt/openvpn-ccd/$1 <<EOF
push "route 10.8.0.0 255.255.0.0"
EOF

### Create a user in container
docker exec -it openvpn bash -c "adduser -D $1"

### Create a google-auth private key
docker exec -it openvpn bash -c "su - $1 -c 'google-authenticator --time-based --no-confirm --window=5 --rate-limit=10 --rate-time=60 --disallow-reuse --force'"

### Create .ovpn file
tee /opt/openvpn-profiles/$1.ovpn <<EOF
client
remote <SERVER_ADDRESS> 1199
dev tun
proto udp
data-ciphers AES-256-GCM:AES-128-GCM
auth SHA512
nobind
resolv-retry infinite
remote-cert-tls server
persist-key
persist-tun
verb 3
key-direction 1
verb 3
auth-nocache
auth-user-pass
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
