#!/bin/bash
#===============================================================================
#
#          FILE:  bonding.sh
#
#         USAGE:  ./bonding.sh
#
#   DESCRIPTION:  Starts, stops, restarts and queries Ethernet channel bonding driver
#
#       OPTIONS:  start | stop | restart | status
#  REQUIREMENTS:  Ethernet channel bonding driver included in Kernel modules.
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Ravikiran K.S. (ravikirandotks@gmail.com)
#       VERSION:  1.0
#       CREATED:  12/29/2007 12:28:48 PM IST
#      REVISION:  ---
#===============================================================================

BOND_DEVS=`ifconfig | grep bond | awk '{print $1}'`
ETH1_IP=192.168.0.153
ETH2_IP=192.168.0.154
ETH3_IP=192.168.0.155
ETH4_IP=192.168.0.156
ETH5_IP=192.168.0.157
BOND0_IP=192.168.0.158
BOND1_IP=192.168.0.159
NET_MASK=255.255.0.0

#set -n                                 # Dry run. Syntax check
#set -u                                 # Treat unset variables as an error
#set -v                                 # Verbose. Echo each command
#set -x                                 # Last resort. Enable debugging mode

start_bonding()
{
    modprobe e1000
    modprobe bonding mode=active-backup arp_interval=1000 arp_ip_target=172.25.0.254,172.25.20.70 max_bonds=2

    ifconfig eth1 $ETH1_IP netmask $NET_MASK up
    ifconfig eth2 $ETH2_IP netmask $NET_MASK up
    ifconfig eth3 $ETH3_IP netmask $NET_MASK up
    ifconfig eth4 $ETH4_IP netmask $NET_MASK up
    ifconfig eth5 $ETH5_IP netmask $NET_MASK up

    ifconfig bond0 $BOND0_IP netmask $NET_MASK up
    ifconfig bond1 $BOND1_IP netmask $NET_MASK up

    ifenslave bond0 eth2
    ifenslave bond0 eth3
    ifenslave bond1 eth4
    ifenslave bond1 eth5

    ifconfig -a
}

stop_bonding()
{
    for bond in $BOND_DEVS
    do
      ifconfig $bond down
    done
    rmmod bonding
    rmmod e1000
}

case $1 in
'start')
    echo "Starting Ethernet channel bonding driver"
    start_bonding
;;
'stop')
    echo "Stopping Ethernet channel bonding driver"
    stop_bonding
;;
'restart')
    echo "Restarting Ethernet channel bonding driver"
    stop_bonding
    sleep 1
    start_bonding
;;
'status')
    echo "Retrieving status of Ethernet channel bonding driver"
    case $2 in
    'bond')
        for bond in $BOND_DEVS
        do
            cat /proc/net/bonding/$bond
        done
    ;;
    'out')
        tail -500 /var/log/messages | less
    ;;
    'eth*')
        ethtool $2
        mii-tool -v $2
    ;;
    'tcp')
        case $3 in
        'bond0')
            tcpdump -vv -i $3
        ;;
        *)
            echo "usage: $0 [status [tcp bondX]]"
        ;;
        esac
    ;;
    *)
    echo "usage: $0 [status [bondX]]"
    ;;
    esac
;;
*)
    echo "usage: $0 [start | stop | restart | status [bondX]]"
;;
esac
exit 0
