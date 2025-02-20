# openvpn-server (with the support of MFA)

### Installing docker + compose. Debian example:
```
curl get.docker.com -L |bash
```

### Installing iptables:
```
sudo apt update
sudo apt install -y iptables iptables-persistent
sudo systemctl enable netfilter-persistent
```

### Preparing directories:
```
mkdir -p /root/pki/
mkdir -p /etc/openvpn-mfa/pki/ 
mkdir -p /etc/openvpn-mfa/pam/ 
mkdir -p /opt/openvpn-mfa/
mkdir -p /opt/openvpn-mfa-profiles/
mkdir -p /opt/openvpn-mfa-ccd/
mkdir -p /opt/openvpn-mfa-scripts/
mkdir -p /var/log/openvpn-mfa/
```

### Copy configs and scripts from project to dest. server:
```

cp configs/ovpn/server.conf /etc/openvpn/ && ls /etc/openvpn/


cp configs/pam/openvpn /etc/openvpn-mfa/pam/ && ls /etc/openvpn-mfa/pam/

cp scripts/make-ovpn-profile.sh /opt/openvpn-mfa-scripts/ && ls /opt/openvpn-mfa-scripts/
cp scripts/remove-ovpn-profile.sh /opt/ /opt/openvpn-mfa-scripts/ && ls /opt/openvpn-mfa-scripts/
```

### Create dummy config for start PAM module
```
echo "" > /opt/openvpn-mfa-ccd/dummy.client
mkdir -p /opt/openvpn-mfa/dummy.client/
echo "" > /opt/openvpn-mfa/dummy.client/.google_authenticator
```

### Setup OpenVPN server address into /opt/openvpn-scripts/make-ovpn-profile.sh
```
vim /opt/openvpn-ccd/make-ovpn-profile.sh

---
...
client
remote <SERVER_ADDRESS> 1199
dev tun
...
---
```

### Build project:
```
sudo docker-compose up -d --build
```

### Basic iptables network configuration:
```
sudo echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
```

```
sudo iptables -P INPUT ACCEPT # (only for dev mode)

sudo iptables -F 
sudo iptables -t nat -F 
sudo iptables -X

### FOR OVPN
sudo iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i tun1 -o eth0 -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o tun1 -j ACCEPT
sudo iptables -A FORWARD -s 10.12.0.0/24 -j ACCEPT

### FOR OVPN-MFA
sudo iptables -A FORWARD -i tun0 -o eth0 -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o tun0 -j ACCEPT
sudo iptables -A FORWARD -s 10.11.0.0/16 -j ACCEPT

### FOR OVPN
sudo iptables -t nat -A POSTROUTING -s 10.12.0.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE

### FOR OVPN-MFA
sudo iptables -t nat -A POSTROUTING -s 10.11.0.0/16 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -o tun1 -j MASQUERADE

sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

---
### Additional informarion:

```
/root/pki - access: root
Local CA directory. Private keys, certificates, openssl parameters are stored there. Clients are verified by private keys in this directory.

/etc/openvpn/ - access: root
The openvpn configuration files directory contains:
+ server.conf - openvpn server configuration file (corresponds to version 2.6.12)
+ ta.key - tls encryption key

/etc/openvpn/pki/ - access: root
The certificates and keys directory contains:
+ server.crt - openvpn server certificate
+ server.key - private key of the openvpn server
+ ca.crt - CA certificate
+ dh.pem - Diffie-Hellman key
+ crl.pem - revocation sheet

/etc/openvpn/pam/ - access: root
Directory with authentication plugin configurations for PAM module

/opt/openvpn-mfa/ - access: usergroup
The directory with openvpn unix-users for the pam module.
MFA private keys (.google_auth) are stored there.

/opt/openvpn-profiles/ - access: user group
Directory with ovpn-profiles files

/opt/openvpn-scripts/ - access: user group
Directory with openvpn server manager scripts

/opt/openvpn-ccd/ - access: user group
The directory of client configurations contains:
+ files with dedicated address and client routes

/var/log/openvpn - access: user group
The logs directory contains:
+ openvpn.log - openvpn log file (or reference to stdout - depends on implementation)
+ openvpn-status.log - file with current client connections on the server
+ dedicated_ips.txt - list of allocated ip addresses to clients
```
