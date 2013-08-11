#!/bin/sh
#
#
#
VERSION="1.00"

# ip link set eth0 up 
# udhcpc -a -q -n -i eth0

# Set the device 
DEVICE=wlan0

# Files in this directory gets created everytime the wireless starts.
WORK_DIR=tmp

# Config files for dnsmasq
DNSMASQ_PID=/$WORK_DIR/$DEVICE/dnsmasq.pid
DNSMASQ_CONF=/$WORK_DIR/$DEVICE/dnsmasq.conf
DNSMASQ_LEASES=/$WORK_DIR/$DEVICE/dnsmasq.leases
DNSMASQ_HOSTS=/$WORK_DIR/$DEVICE/dnsmasq.hosts

# Config file for AP deamon
HOSTAPD_CONF=/$WORK_DIR/$DEVICE/hostapd.conf

# use hostname as ssid for the AP
SSID=`hostname`

# Default
DEVICE_IP=169.254.89.5

# DHCP address pool
HOST_IP_RANGE_BEGIN=169.254.85.1
HOST_IP_RANGE_END=169.254.85.254

DOMAIN=krutt_
 
get_device_ip()
{
    echo $DEVICE_IP
}

get_random_llip()
{
    local major=$((RANDOM%254))
    local minor=0

    while [ $minor -eq 0 ]
    do
        minor=$((RANDOM%254))
    done

    echo "169.254.$major.$minor"
}

allocate_addresses()
{
   local device=$1
   local device_ip=$DEVICE_IP
   local ok=1

   # allocate and check device_ip
   while [ $ok -eq 1 ]
   do
        device_ip=`get_random_llip`
        ip addr add $device_ip/16 brd + dev $device
        arping -q -c 1 -w 5 -D -I $device $device_ip
        ok=$?
   done 

   DEVICE_IP=$device_ip 
}

mk_dnsmasq_conf()
{ 
    local device=$DEVICE 
    local device_ip=`get_device_ip`

cat << LAB_CONF > $DNSMASQ_CONF 
#--- setup dnsmasq.conf file ---
#
# use to set wireless or ethernet NIC device:
interface=$device

# do not read resolv.conf, local only
no-resolv

# do not forward any dns queries
local=/localnet/

# block Windows junk requests
filterwin2k

# do not use /etc/hosts
no-hosts

# instead, use this private hosts file 
addn-hosts=$DNSMASQ_HOSTS

# add domain to simple names in hosts file
expand-hosts

# DNS appends .local to simple names expanded by the above
domain=$DOMAIN

# only one address is DHCPd for this session
dhcp-range=$HOST_IP_RANGE_BEGIN,$HOST_IP_RANGE_END,255.255.0.0,12h

# DHCP clients will be given domain '.local'
dhcp-option=40,$DOMAIN

# add a classful static route to the target
dhcp-option=33,$device_ip,$device_ip

# all subnets are local
dhcp-option=27,1
dhcp-authoritative
dhcp-leasefile=$DNSMASQ_LEASES

LAB_CONF


cat << LAB_HOSTS > $DNSMASQ_HOSTS
#--- setup private hosts file ---
#
$device_ip $SSID

LAB_HOSTS
}

mk_hostapd_conf()
{
cat << LAB_HOSTAPD > $HOSTAPD_CONF 
channel=11
country_code=MX
driver=nl80211
dtim_period=1
fragm_threshold=2346
hw_mode=g
ieee80211n=1
interface=$DEVICE
rsn_pairwise=CCMP
rts_threshold=2347
ssid=$SSID
wmm_enabled=1
wpa=3
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP CCMP
wpa_passphrase=panda1234
LAB_HOSTAPD
}

remove_config_files()
{
    rm -f $DNSMASQ_PID
    rm -f $DNSMASQ_LEASES
    rm -f $DNSMASQ_HOSTS
    rm -f $DNSMASQ_CONF
}

dnsmasq_start()
{
    mk_dnsmasq_conf 
    dnsmasq -x $DNSMASQ_PID -C $DNSMASQ_CONF  
}

dnsmasq_stop()
{ 
    killall dnsmasq >& /dev/null 

    remove_config_files
} 

hostapd_start()
{
    mk_hostapd_conf
    hostapd -B $HOSTAPD_CONF 
}

wifi_on()
{ 
    local ok=0 

    echo "on" 
    return $ok
}

wifi_off()
{
    echo "off"
}

wifi_start()
{ 
    local device=$DEVICE

    wifi_on
    if [ $? -eq 0 ]
    then
        modprobe mac80211

        insmod /lib/modules/`uname -r`/kernel/drivers/net/wireless/ti/wlcore/wlcore.ko
        insmod /lib/modules/`uname -r`/kernel/drivers/net/wireless/ti/wlcore/wlcore_sdio.ko

        modprobe /lib/modules/`uname -r`/kernel/drivers/net/wireless/ti/wl12xx/wl12xx.ko

        ifconfig -a

        ifconfig wlan0 up 

        ip link set $device up 

        allocate_addresses $device 
        remove_config_files $device

        hostapd_start 

        dnsmasq_start $device 
    fi
}

wifi_stop()
{
    dnsmasq_stop 

    if [ -h /sys/class/net/$DEVICE ]
    then 
        ip link set $DEVICE down 
        wifi_off
    fi
}

init()
{ 
    mkdir -p /$WORK_DIR/$DEVICE
}


#
# MAIN
#
init

case "$1" in
    start)
        wifi_start
        ;;

    stop)
        wifi_stop
        ;; 

    version)
        echo netctrl version $VERSION 
        ;;

    *)
        echo "Usage: /etc/netctrl {start|stop|restart|version}"
        exit 1
        ;; 
esac



