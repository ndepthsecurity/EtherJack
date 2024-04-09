#!/bin/bash
#
###############
#  EtherJack.sh
###############

source EtherJack.conf

case $EJMODE in
	lan|LAN)
		mkdir $EJPATH/lan/$ENGAGEMENT
		cd $EJPATH/lan/$ENGAGEMENT
		cat $EJPATH/files/ejmotd >>$EJLOG
		echo "Running EJ in LAN Mode" >>$EJLOG
		echo "Setting up Engagement Folder" >>$EJLOG
		echo "Starting netfinder.sh" >>$EJLOG
		$EJPATH/lan/netfinder.sh
		;;
	wifi|WIFI|WiFi)
		mkdir $EJPATH/wifi/$ENGAGEMENT
		cd $EJPATH/wifi/$ENGAGEMENT
		cat $EJPATH/files/ejmotd >>$EJLOG
		echo "Running EJ in WiFi Mode" >>$EJLOG
		echo "Setting up Engagement Folder" >>$EJLOG
		$EJPATH/wifi/wifi.sh
		;;
	preset|PRESET)
		mkdir $EJPATH/preset/$ENGAGEMENT
		cd $EJPATH/preset/$ENGAGEMENT
		cat $EJPATH/files/ejmotd >>$EJLOG
		echo "Running EJ in preset mode" >>$EJLOG
		echo "Setting up Engagement Folder" >>$EJLOG
		$EJPATH/preset/preset.sh
		;;
	*)
		echo "Invalid mode defined. Shutting system down!!"
		init 0
		;;
esac
