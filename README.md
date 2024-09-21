# openvpn-server (with the support of MFA)

### Installing docker + compose. Debian example:
```
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"

sudo apt update

apt-cache policy docker-ce
sudo apt install docker-ce
```

```
sudo curl -L "https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

docker-compose --version
```

### Installing iptables:
```
sudo apt update
sudo apt install -y iptables iptables-persistent
sudo systemctl enable netfilter-persistent
```

### Preparing directories:
```
mkdir -p /root/pki/ # CA and users keys
mkdir -p /etc/openvpn/pki/ # openvpn-server keys
mkdir -p /etc/openvpn/pam/ # 
mkdir -p /opt/openvpn-mfa/
mkdir -p /opt/openvpn-profiles/
mkdir -p /opt/openvpn-ccd/
mkdir -p /opt/openvpn-scripts/
mkdir -p /var/log/openvpn/
```

### Copy configs and scripts from project to dest. server:
```
cp configs/ovpn/server.conf /etc/openvpn/
cp configs/pam/openvpn /etc/openvpn/pam/

cp scripts/make-ovpn-profile.sh /opt/openvpn-scripts/
cp scripts/remove-ovpn-profile.sh /opt/ /opt/openvpn-scripts/
```

### Create dummy config for start PAM module
```
echo "" > /opt/openvpn-ccd/dummy.client
```

### Setup OpenVPN server address into /opt/openvpn-scripts/make-ovpn-profile.sh
```
vim /opt/openvpn-ccd/dummy.client

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

sudo iptables -I FORWARD -i <DEFAULT_IF_NAME> -o <VIRTUAL_IF_NAME> -j ACCEPT
sudo iptables -I FORWARD -i <VIRTUAL_IF_NAME> -o <DEFAULT_IF_NAME> -j ACCEPT

sudo iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -s 10.8.0.0/16 -j ACCEPT

sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/16 -o <DEFAULT_IF_NAME> -j MASQUERADE
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE

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
