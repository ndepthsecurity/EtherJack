#!/bin/bash
#
###########
# preset.sh
###########

source ../../EtherJack.conf
source ../preset.conf

echo "############### PRESET MODE ###############" >>$EJLOG

case $CONFIG in
	static|STATIC)
		echo "Configuring EJ for a static IP configuration" >>$EJLOG
		systemctl stop NetworkManager
		systemctl disable NetworkManager
		ifconfig eth0 down
		ifconfig eth0 up
		ifconfig eth0 $IPADDR netmask $NETMASK
		route add default gw $GATEWAY
		echo "nameserver $NAMESERVER" > /etc/resolv.conf
		echo "My IP is: $IPADDR" >>$EJLOG
		echo "My Netmask is: $NETMASK" >>$EJLOG
		echo "My Gateway is: $GATEWAY" >>$EJLOG
		echo "My Nameserver is: $NAMESERVER" >>$EJLOG
		DONE=NO
		while [ $DONE == "NO" ]; do
			for TRY in {1..5}; do
				echo "Attempting to reach the Internet" >>$EJLOG
				PortCheck="$(nmap -n -sT -p $TESTPORT $TESTIP | grep -i open | awk '{print $2}')"
                		if [ "$PortCheck" != "open" ]; then
                        		echo "Try $TRY of 5. Static configuration didn't work!!" >>$EJLOG
					if [ $TRY == 5 ]; then
						echo "Number of trys to reach Internet exceeded. Shutting system down." >>$EJLOG
						init 0
					else
                        			echo "Trying Internet check again. Sleeping for 5 seconds..." >>$EJLOG
						sleep 5
					fi
                		else
                        		echo "Internet check successfull!!" >>$EJLOG
					break
				fi
			done
			echo "Calling home" >>$EJLOG
			$CALLHOME
			DONE=YES
		done
		;;
	dhcp|DHCP)
		echo "Configuring EJ for a DHCP configuration" >>$EJLOG
		systemctl stop NetworkManager
		systemctl start NetworkManager
		DONE=NO
		while [ $DONE == "NO" ]; do
			echo "Attempting to reach the Internet" >>$EJLOG
			PortCheck="$(nmap -n -sT -p $TESTPORT $TESTIP | grep -i open | awk '{print $2}')"
                	if [ "$PortCheck" != "open" ]; then
                        	echo "Still waiting on DHCP. Sleeping for 2 seconds until retry...." >>$EJLOG
				sleep 2
                        	DONE=NO
                	else
                        	echo "Internet check successfull!!" >>$EJLOG
				DHCPIP=$(hostname -I)
				DHCPGTW=$(ip route show default)
				DHCPMASK=$(ifconfig eth0 | grep -i mask | awk '{print $4}')
				DHCPNS=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')
				echo "My IP is: $DHCPIP" >>$EJLOG
				echo "My Netmask is: $DHCPMASK" >>$EJLOG
				echo "My Gateway is: $DHCPGTW" >>$EJLOG
				echo "My Nameserver is: $DHCPNS" >>$EJLOG
				echo "Calling home" >>$EJLOG
				$CALLHOME
                        	DONE=YES
			fi
		done
		;;
	*)
		echo "Invalid configuration defined. Shutting system down!!" >>$EJLOG
		init 0
		;;
esac
