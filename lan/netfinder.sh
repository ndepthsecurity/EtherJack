#!/bin/bash
#
###############
# netfinder.sh
###############
#
source ../../EtherJack.conf

echo "############### LAN MODE ###############" >>$EJLOG
echo "############### NETFINDER ###############" >>$EJLOG

# Disable Network Manager
echo "Shutting down NetworkManager and resetting interface" >>$EJLOG
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
echo "Bringing up eth0" >>$EJLOG
ifconfig eth0 up

# Identify MAC addresses on LAN and set global variables
DUMP=dump
IPS=ips
IPv4=ipv4
NET=net
CLASSB=classB
CLASSA=classA
MAC_ADDR=mac_addr
MAC_ADDR_UNIQ=mac_addr_uniq
MAC_ADDR_OUI_UNIQ=mac_addr_oui_uniq
echo "Discovering local mac address to blend with on network" >>$EJLOG
tshark -q -i eth0 -e eth.src -Tfields -Q -c $PKTS >$MAC_ADDR 2>&1
echo "Generating list of uniq mac addresses and OUIs to use" >>$EJLOG
grep -v -e "tshark" -e "Running" $MAC_ADDR | sort -rn | uniq >$MAC_ADDR_UNIQ
awk -F \: '{print $1":"$2":"$3}' $MAC_ADDR_UNIQ | sort -rn | uniq >$MAC_ADDR_OUI_UNIQ
echo "Generating a mac address using most common OUI to blend into network" >>$EJLOG
MY_OUI=$(head -1 $MAC_ADDR_OUI_UNIQ)
OCT1=$(tr -dc a-f </dev/urandom | head -c 1; tr -dc 0-9 </dev/urandom | head -c 1)
OCT2=$(tr -dc 0-9 </dev/urandom | head -c 2)
OCT3=$(tr -dc 0-9 </dev/urandom | head -c 2)
echo "New mac address will be $MY_OUI:$OCT1:$OCT2:$OCT3" >>$EJLOG
echo "Configuring interface with new mac address" >>$EJLOG
ifconfig eth0 down
macchanger -m $MY_OUI:$OCT1:$OCT2:$OCT3 eth0
ifconfig eth0 up

# Finding source networks on LAN
echo "Locating source networks within broadcast domain" >>$EJLOG
echo "Discovering local RFC1918 private IP addresses" >>$EJLOG
tcpdump -i eth0 -n -c $PKTS arp src net 10 or 172.16/12 or 192.168/16 -w $DUMP > /dev/null 2>&1
tcpdump -r $DUMP 2>&1 | awk '(NR>1)' | awk '{print $7}' | awk -F \, '{print $1}' | sort -rn | uniq > $IPS
grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' $IPS > $IPv4
echo "Identifying uniq RFC1918 network ranges" >>$EJLOG
grep -v -e '^[[:space:]]"$' $IPv4 | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | awk -F \. '{print $1"."$2"."$3}' | sort -rn | uniq > $NET
echo "Determine specific target class network" >>$EJLOG
ROW=$(wc -l < $NET)
#echo "row equals $row"
if [ "$ROW" -eq 1 ]; then
	echo "Class C network" >>$EJLOG
	CLASS=$(cat $NET)
	echo "Target network is $CLASS" >>$EJLOG
	echo "Define our IP Address" >>$EJLOG
	DONE=NO
	while [ "$DONE" == "NO" ]; do
        	RANDNUM=$(shuf -i 2-253 -n 1)
        	MYIP="$CLASS.$RANDNUM"
		# Check if $MYIP exists in $IPv4
        	if grep -q "$MYIP" $IPv4; then
                	DONE=NO
        	else
			# Verify $MYIP does not exist on the network already
			echo "Verify $MYIP does not exist on the network already" >>$EJLOG
			SRC_IP=$(head -1 $IPv4)
			arping -I eth0 -c 1 $MYIP -S $SRC_IP | grep -q "0 packets received" && IP_EXISTS="" || IP_EXISTS="YES"
			if [ -z "$IP_EXISTS" ]; then
                		echo "Our IP is $MYIP" >>$EJLOG
				echo "Configuring IP address and netmask" >>$EJLOG
				ifconfig eth0 $MYIP/24
				echo "$CLASS.0/24" >my_net
				echo "$MYIP" >my_ip
                		DONE=YES
			else
				echo "The IP exists...start again" >>$EJLOG
				DONE=NO
			fi
        	fi
	done
else
	echo "Not a class C network" >>$EJLOG
	awk -F \. '{print $1"."$2}' $NET | uniq > $CLASSB
	ROW=$(wc -l < $CLASSB)
	if [ "$ROW" -eq 1 ]; then
		echo "Class B network" >>$EJLOG
		CLASS=$(cat $CLASSB)
		echo "Target network is $CLASS" >>$EJLOG
		echo "Define our IP Address" >>$EJLOG
		DONE=NO
		while [ "$DONE" == "NO" ]; do
			RANDNUM=$(shuf -i 2-253 -n 1)
			RANDNUM2=$(shuf -i 2-253 -n 1)
        		MYIP="$CLASS.$RANDNUM.$RANDNUM2"
			# Check if $MYIP exists in $IPv4
        		if grep -q "$MYIP" $IPv4; then
                		DONE=NO
        		else
				# Verify $MYIP does not exist on the network already
				echo "Verify $MYIP does not exist on the network already" >>$EJLOG
				SRC_IP=$(head -1 $IPv4)
				arping -I eth0 -c 1 $MYIP -S $SRC_IP | grep -q "0 packets received" && IP_EXISTS="" || IP_EXISTS="YES"
				if [ -z "$IP_EXISTS" ]; then
                			echo "Our IP is $MYIP" >>$EJLOG
					echo "Configuring IP address and netmask" >>$EJLOG
					ifconfig eth0 $MYIP/16
					echo "$CLASS.0.0/16" >my_net
					echo "$MYIP" >my_ip
                			DONE=YES
				else
					echo "The IP exists...start again" >>$EJLOG
					DONE=NO
				fi
			fi
		done
	else
		echo "Class A network" >>$EJLOG
		awk -F \. '{print $1}' $NET | uniq > $CLASSA
		CLASS=$(cat $CLASSA)
		echo "Target network is $CLASSA" >>$EJLOG
		echo "Define our IP Address" $EJLOG
		DONE=NO
		while [ "$DONE" == "NO" ]; do
			RANDNUM=$(shuf -i 2-253 -n 1)
			RANDNUM2=$(shuf -i 2-253 -n 1)
			RANDNUM3=$(shuf -i 2-253 -n 1)
        		MYIP="$CLASS.$RANDNUM.$RANDNUM2.$RANDNUM3"
			# Check if $MYIP exists in $IPv4
        		if grep -q "$MYIP" $IPv4; then
                		DONE=NO
        		else
				# Verify $MYIP does not exist on the network already
				echo "Verify $MYIP does not exist on the network already" >>$EJLOG
				SRC_IP=$(head -1 $IPv4)
				arping -I eth0 -c 1 $MYIP -S $SRC_IP | grep -q "0 packets received" && IP_EXISTS="" || IP_EXISTS="YES"
				if [ -z "$IP_EXISTS" ]; then
                			echo "Our IP is $MYIP" >>$EJLOG
					echo "Configuring IP address and netmask" >>$EJLOG
					ifconfig eth0 $MYIP/8
					echo "$CLASS.0.0.0/8" >my_net
					echo "$MYIP" >my_ip
                			DONE=YES
				else
					echo "The IP exists...start again" >>$EJLOG
					DONE=NO
				fi
        		fi
		done
	fi
fi

#Configure IPtables rules
echo "Configuring IPtables rules to block all the things inbound" >>$EJLOG
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

#Finding the default Gateway
echo "Lanuching routefinder.sh" >>$EJLOG
echo "############### END NETFINDER ###############" >>$EJLOG
$EJPATH/lan/routefinder.sh
