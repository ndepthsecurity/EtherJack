![alt text](https://github.com/ragetek/EtherJack/blob/master/files/EtherJack.png?raw=true)
## What is EtherJack?
EtherJack or "EJ", is a "plug-and-pray" leave behind device that can be used to establish different levels of persistence on a target network
through a series of software and hardware configurations. EJ was developed by and for pentesters to help support and aid in physical pentesting engagements
through the use of open/available RJ-45 Ethernet ports. EJ helps bring to light what a malicious actor can do when having physical access to an organization's
network and how poor network security hygiene can lead to devastating consequences. EJ offers a complimentary solution to existing physical pentest-assisting 
capabilities and allows offensive security practitioners to expand their toolkits used during physical pentests and offers an additional leave-behind component that
can accommodate most physical constraints and user requirements. As pentesters, we should leave no port untested! 
### Whats under the hood?
EJ runs on the following (recommended) hardware and accessories, which can be searched/found on [Amazon](https://amazon.com):
* **Raspberry Pi Zero W** or **Zero 2 W**.
* **microSD card** (64GB+ recommended).
* **Portable power bank** (micro usb connection) or **Pisugar Lithium Battery**
* **Raspberry Pi Zero W Basic Starter Kit** provides assortment of necessary cables and accessories.
* **Micro USB Ethernet Adapter for Raspberry Pi Zero** 
* **IEEE 802.3af Micro USB PoE Adapter for Raspberry Pi** for switches that support PoE.
* **USB-powered Ethernet Splitter** to share host network drop if needed.
* **Ethernet cables** support network connectivity.
* **Raspberry Pi Zero Case kit** for protection and concealment (case will vary if Pisugar battery is used).
* **External Hard Drive Case** to store EtherJack hardware.

EJ is made up of the following software:
* [Kali ARM (for Pi Zero W)](https://www.kali.org/get-kali/#kali-arm)
* BASH scripts and configuration files to carry out and manage the persistence activities
* C2 client or "call home" function (e.g., [Sliver](https://github.com/BishopFox/sliver) or [Metasploit](https://github.com/rapid7/metasploit-framework) payload)
## Prerequisites
Instructions below assume the user has similar experience with, and is installing EtherJack on, the recommended hardware mentioned above. The instructions also assume the user 
is knowledgable in pentesting, networking, Linux, etc. These instructions are not meant to be all-inclusive.  
1. Install Kali ARM for Pi Zero W or W2 using these procedures:
   * Pi Zero W: (https://www.kali.org/docs/arm/raspberry-pi-zero-w/)
   * Pi Zero W2: (https://www.kali.org/docs/arm/raspberry-pi-zero-2-w/)
2. Ensure the Pi has connectivity to the Internet using the microusb Ethernet dongle, NOT Wi-Fi.
3. Login to the Pi using the default user/password (kali/kali).
4. Open a terminal window, disable the GUI and reboot:
   ```sh
   sudo systemctl set-default multi-user.target
   sudo reboot
   ```
5. Login and change the password for the kali user:
   ```sh
   passwd kali
   ```
6. (Optional) Setup and verify the appropriate timezone and time:
   ```sh
   sudo timedatectl  # --> verify timezone
   sudo timedatectl list-timezones | grep America  # --> grep country
   sudo timedatectl set-timezone America/New_York  # --> set timezone
   sudo date -s "04 APR 2024 12:00:00" # --> set your time accordingly
   ```
7. Update the Kali operating system (this process can take a while):
   ```sh
   sudo apt-get update
   sudo apt full-upgrade -y
   ```
## EtherJack Installation
8. Open a terminal and Git the EtherJack repository:
    ```sh
    cd /usr/local
    sudo git clone https://github.com/ragetek/EtherJack
    ``` 
9. Install EJ motd:
    ```sh
    sudo cp /etc/motd /etc/motd.bak
    sudo cp /usr/local/EtherJack/files/ejmotd /etc/motd
    ```
10. Create service so EJ starts at boot:
    ```sh
    sudo systemctl enable /usr/local/EtherJack/EtherJack.service
    ```
11. Change the hostname (without rebooting):
    ```sh
    sudo sed -i 's/kali-raspberry-pi.*/etherjack/g' /etc/hosts   # --> this will change the entry in /etc/hostname as well.
    sudo hostnamectl set-hostname etherjack
    bash  # --> this will spawn another shell with the new hostname or your can exit the console and log back in.
    ```
12. Disable Kali operating system services to prevent starting at boot:
    ```sh
    sudo systemctl disable sshd.service
    sudo systemctl disable NetworkManager
    sudo systemctl disable bluetooth.service
    # ensure wlan0 is always set to manual configuration in /etc/network/interfaces when NetworkManager is enabled
    sudo echo "iface wlan0 inet manual" >> /etc/network/interfaces
    ```
## EtherJack Modes
EJ utilizes interchangable hardware components to support different configuration and power modes for connectivity within a target network.
Each mode is described in detail within the sections below. 

### Power Modes
EJ can operate in three (3) different power modes to accomodate most enviromental conditions during a pentest:
* **Standard** - the most standard way to power EJ is using the 3.3v Pi power adapter that
comes with the starter kit. The adapter terminates to a microUSB interface that
can be plugged into one of the two (2) available ports on the Pi Zero W.
* **PoE** - Power over Ethernet (PoE) can be achieved using the IEEE 802.3af Micro USB PoE Adapter and a 
network switch with an available PoE Ethernet port. This is the most optimal and convenient method
you can use to power EJ since it requires less hardware and setup 
to obtain persistence. The PoE adapter provides power and Ethernet connectivity to
the target network.
* **Battery** - When standard or PoE power methods are out of play, EJ can be powered using a portable battery bank
which terminates to a microUSB interface that can be plugged into an available USB port on the Pi. Mileage 
will  vary on these portable components so time will be of the essence. When these power components are in play
be sure to plan your remote activities accordingly.

### Configuration Modes
EJ plugs into an available RJ-45 Ethernet port and offers users three (3) different configuration modes:
* **LAN** - EJ operates passively in the background to blend and attach the ethernet interface to a RFC1918 compliant network using
a sample of ARP packets collected on the network. The total number of ARP packets to sample/collect is defined in the **EtherJack.conf** file. Once the interface
is configured, EJ will attempt to identify a gateway and execute a pre-defined payload to callhome and obtain persistent access on the network.   
* **PRESET** - EJ configures the ethernet interface with user-provided settings (i.e., static IP or DHCP configuration). These
settings are defined in the **preset/preset.conf** file. EJ will test/validate the preset settings and if testing is successfull, EJ will
execute the pre-defined payload to callhome and obtain persistent access on the network.
* **WIFI** - EJ operates as a rouge Wi-Fi access point using hostapd and dnsmasq for DHCP leasing. The **wifi/wifi.conf** file is used
to configure the rouge Wi-Fi network address and IP address of wlan0. The **wifi/hostapd.conf** file defines the configuration settings
for the wireless network.

## EtherJack Setup
This section assumes you are working from within /usr/local/EtherJack. You can use the "vi" editor or the "sed" command examples below
to edit the appropriate EJ configuration files. Editing/changing any setting outside the ones below could prevent EJ from working correctly.
*Use and modify at your own risk!!!*

13. EJ can only run in one (1) configuration mode. **WARNING** If you do not define a configuration mode or define an incorrect configuration mode, EJ
    will auto-shutdown the operating system. To set/change the configuration mode, update the EtherJack.conf file:
    ```sh
    sudo sed -i 's/EJMODE=.*/EJMODE=LAN/' EtherJack.conf
    # or
    sudo sed -i 's/EJMODE=.*/EJMODE=PRESET/' EtherJack.conf
    # or
    sudo sed -i 's/EJMODE=.*/EJMODE=WIFI/' EtherJack.conf
    ```
14. Define the payload you want to execute, and copy your payload to the EJ bin/ directory (the payload only gets executed in LAN and PREEST configuration modes) :
    ```sh
    sudo mkdir bin/
    sudo sed -i 's/EJEXE=.*/EJEXE=payload/' EtherJack.conf  # --> "payload" is whatever the name of your payload will be
    sudo cp path-to-payload /usr/local/EtherJack/bin/  # --> "path-to-payload" is the path to where you payload is located
    sudo chmod 755 /usr/local/EtherJack/bin/payload  # --> "payload" is whatever the name of your payload will be
    ```
15. (Optional) Define the test IP address and test port you want to use to verify connectivity to the Internet. By default, the TESTIP and TESTPORT settings
    in EtherJack.conf are set to resolve to the www.example.com address and port tcp/80:
    ```sh
    sudo sed -i 's/TESTIP=.*/TESTIP=93.184.216.34/' EtherJack.conf  # --> This is the default setting
    sudo sed -i 's/TESTPORT=.*/TESTPORT=80/' EtherJack.conf  # --> This is the default setting
    ```
### Setting up LAN mode
16. There is very little to do as far as configuration in this mode. The only thing you may want to adjust is the sample size of ARP packets to collect. The
    default setting is five (5) packets. Depending on how active the network is will determine the amount of time required to collect the desired sample
    size defined in the EtherJack.conf file. Change as needed:
    ```sh
    sudo sed -i 's/PKTS=.*/PKTS=5/' EtherJack.conf
    ```
### Setting up PRESET mode
17. Update the preset/preset.conf file and define if the target network uses DHCP or STATIC IP address configuration:
    ```sh      
    # Example CONFIG setting
    sudo sed -i 's/CONFIG=.*/CONFIG=STATIC/' preset/preset.conf
    # or
    sudo sed -i 's/CONFIG=.*/CONFIG=DHCP/' preset/preset.conf
    ```
18. Update the preset/preset.conf file with the appropriate STATIC configuration settings if the environment **does NOT** use DHCP:
    ```sh
    # Example STATIC CONFIG setting
    sudo sed -i 's/IPADDR=.*/IPADDR=192.68.10.57/' preset/preset.conf
    sudo sed -i 's/NETMASK=.*/NETMASK=255.255.255.0/' preset/preset.conf
    sudo sed -i 's/GATEWAY=.*/GATEWAY=192.168.10.254/' preset/preset.conf
    sudo sed -i 's/NAMESERVER=.*/NAMESERVER=8.8.8.8/' preset/preset.conf
    ```
### Setting up WIFI mode
WIFI mode enables users to have persistent access to the target environment without taking the risk of, or attempting to, connect to the Internet through
the customer's network. It offers an out-of-band connection that users can interact with safely, within proximity of the EJ access point. After associating
and authenticating to the EJ Wi-Fi access point, you can SSH to EJ using the kali user account and attempt further exploitation from there. 

19. Kali does not have hostapd or dnsmasq pre-installed. These services are needed to support the Wi-Fi and DHCP configuration, so you have to install them:
    ```sh
    sudo apt-get install hostapd -y
    sudo apt-get install dnsmasq -y
    ```
20. Next, update the wifi/wifi.conf file to define the network address, IP address for wlan0, and the netmask:
    ```sh
    # Example settings
    sudo sed -i 's/WLANNET=.*/WLANNET=172.16.0/' wifi/wifi.conf
    sudo sed -i 's/WLANIP=.*/WLANIP=172.16.0.1/' wifi/wifi.conf
    sudo sed -i 's/MASK=.*/MASK=24/' wifi/wifi.conf
    ```
21. Next, update the hostapd.conf file to define the hardware mode, Wi-Fi channel, SSID, and passphrase/password for the Wi-Fi network:
    ```sh
    # Example settings
    sudo sed -i 's/hw_mode=.*/hw_mode=g/' wifi/hostapd.conf   # --> This is the default setting. Depends on type of radio you have (5GHz or 2.4GHz)
    sudo sed -i 's/channel=.*/channel=11/' wifi/hostapd.conf   # --> This is the default setting.
    sudo sed -i 's/ssid=.*/ssid=EJNET/' wifi/hostapd.conf
    sudo sed -i 's/wpa_passphrase=.*/wpa_passphrase=Pa22word/' wifi/hostapd.conf
    ```
## Plug-and-pray
Now its time to test your configuration and hope for the best!!

22. Once all configurations are complete, power off EJ and ready for testing:
    ```sh
    sudo init 0
    ```
23. Plug EJ into an available ethernet port on your target network, or use a ethernet splitter to share a port with a target host.
24. Choose the appropriate power mode to accomodate your environment and power on EJ.
25. EJ will create an engagement folder inside the respective configuration mode folder (i.e., lan, wifi, preset). Any files associated
    wtih the configuration process will be stored in the engagement directory, to include an EJ log file (i.e., ej.log) to track the
    configuration setup process. The log file is used for debugging/troubleshooting configuration issues. If all goes well, you will
    have a successfull call back over the Internet and/or a rouge AP beaconing on the radio spectrum.

## Disclaimer
Use at your own risk. Authors, content developers, administrators of the EtherJack project assume no responsibility or liability for any errors or omissions in content, 
or unethical hacking/usage. All information provided for the EtherJack project is provided on an "as is" basis with no warranty or guarantees.
## Contact
RaGeTek - rag3tek@gmail.com
Project Link: [https://github.com/ndepthsecurity/EtherJack](https://github.com/ndepthsecurity/EtherJack)
<p align="right">(<a href="#readme-top">back to top</a>)</p>
