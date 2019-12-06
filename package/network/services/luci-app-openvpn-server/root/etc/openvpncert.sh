#!/bin/sh

rm -rf /www/pki
echo -en "\n" | easyrsa init-pki
echo -en "\n" | easyrsa build-ca nopass
echo -en "\n" | easyrsa gen-req server nopass
echo -en "yes\n" | easyrsa sign server server
echo -en "\n" | easyrsa gen-dh
echo -en "\n" | easyrsa gen-req client1 nopass
echo -en "yes\n" | easyrsa sign client client1
cp /www/pki/ca.crt /etc/openvpn/
cp /www/pki/issued/server.crt /etc/openvpn/
cp /www/pki/private/server.key /etc/openvpn/
cp /www/pki/dh.pem /etc/openvpn/
cp /www/pki/issued/client1.crt /etc/openvpn/
cp /www/pki/private/client1.key /etc/openvpn/
sleep 2
rm -rf /www/pki
sleep 2
logger "OpenVPN Cert renew successfully"
sleep 2
/etc/init.d/openvpn restart
