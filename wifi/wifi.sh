#!/bin/bash
#
#########
# wifi.sh
#########

source ../../EtherJack.conf
source ../wifi.conf

echo "############### WIFI MODE ###############" >>$EJLOG

echo "Enabling WiFi Radio" >>$EJLOG
rfkill unblock all
iw dev wlan0 set power_save off

echo "Setting static IP" >>$EJLOG
ifconfig wlan0 0.0.0.0
ifconfig wlan0 down
ifconfig wlan0 up
ifconfig wlan0 $WLANIP/$MASK

echo "Starting SSHD" >>$EJLOG
systemctl stop ssh
systemctl start ssh

echo "Enforcing Firewall Rules" >>$EJLOG
iptables -I INPUT -i lo -j ACCEPT
iptables -I OUTPUT -o lo -j ACCEPT
iptables -I INPUT -p tcp --dport 22 -s $WLANNET.0/$MASK -j ACCEPT
iptables -I INPUT -p tcp --dport 53 -s $WLANNET.0/$MASK -j ACCEPT
iptables -I INPUT -p udp --dport 53 -s $WLANNET.0/$MASK -j ACCEPT
iptables -I INPUT -p udp --dport 67 -s $WLANNET.0/$MASK -j ACCEPT
iptables -I INPUT -p udp --dport 68 -s $WLANNET.0/$MASK -j ACCEPT
iptables -I INPUT -i wlan0 -j ACCEPT
iptables -I OUTPUT -o wlan0 -j ACCEPT
iptables -I OUTPUT -o eth0 -d 0.0.0.0/0 -j ACCEPT
iptables -I INPUT -i eth0 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i eth0 -j DROP


# Disable NetworkManager and reset eth0 
echo "Shutting down NetworkManager and resetting eth0 interface" >>$EJLOG
systemctl stop NetworkManager
systemctl disable NetworkManager
ifconfig eth0 0.0.0.0
ifconfig eth0 down

# configure nameserver as Google
echo "Configuring nameserver" >>$EJLOG
echo "nameserver 8.8.8.8" >/etc/resolv.conf

# Disable ipv6 on eth0
echo "Ensuring ipv6 is disabled" >>$EJLOG
if grep -q "net.ipv6.conf.all.disable_ipv6 = 1" /etc/sysctl.conf; then
        echo "IPV6 already disabled" >>$EJLOG
else
        echo "Disabling IPV6" >>$EJLOG
        echo "net.ipv6.conf.all.disable_ipv6 = 1" >>/etc/sysctl.conf
        sysctl -p
fi

echo "Starting dnsmasq" >>$EJLOG
pkill -9 dnsmasq
dnsmasq -i wlan0 --dhcp-range=$WLANNET.50,$WLANNET.60,255.255.255.0,24h

echo "Start wlan0 using hostapd" >>$EJLOG
pkill -9 hostapd
hostapd ../hostapd.conf -t -f hostapd.log
