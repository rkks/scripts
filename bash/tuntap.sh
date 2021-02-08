#!/bin/bash
#  DETAILS: Script to add/del/mod TUN/TAP devices
#  CREATED: Wednesday 15 April 2020 10:52:27  IST IST
# MODIFIED: 16/Apr/2020 09:58:11 IST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2020, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

# TAP interface requires an Application binding to it, for it to show carrier.
# Till then, the "ip link" will show "NO-CARRIER" for tapX interfaces in list.

PATH=/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin:/sbin

[[ "$(basename tuntap.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

TEST_BR_DEV=br0;
TEST_ETH_DEV=enp0s20f1;
TEST_IP_SUBNET=192.168
TEST_BR_SUBNET=1
TEST_TAP_SUBNET=2
TEST_TUN_SUBNET=3
TEST_BR_IP=$TEST_IP_SUBNET.$TEST_BR_SUBNET.1
TEST_BCAST_ADDR=$TEST_IP_SUBNET.255.255
TEST_NET_MASK=255.255.0.0
TEST_GATEWAY=$TEST_IP_SUBNET.0.1

usage()
{
    echo "Usage: tuntap.sh [-h|]"
    echo "Options:"
    echo "  -h          - print this help"
    echo "  -a <X>      - add tapX/tunX device with given number X"
    echo "  -d <X>      - del tapX/tunX device with given number X"
    echo "  -m <X>      - mod tapX/tunX device with given number X"
    echo "  -i <ip>     - pass IP address to add to tun/tap interface"
    echo "  -c <bc_addr>- pass bcast address for br/tun/tap interface"
    echo "  -n <netmask>- pass netmask to add to br/tun/tap interface"
    echo "  -p          - do operation on tap interface"
    echo "  -u          - do operation on tun interface"
    echo "  -t <tap|tun>- run tests on TAP/TUN interfaces"
}

function help()
{
    set -x
    local p; local a="";
    echo "$@"
    for p in "$@"; do
        echo "${a} \"${p}\""
        a="${a} \"${p}\"";
    done
    set +x
}

function run()
{
    echo "$*"; test -n "$DRY_RUN" && { return 0; } || { local p; local a=""; for p in "$@"; do a="${a} \"${p}\""; done; }
    test -z "$RUN_LOG" && { RUN_LOG=/dev/null; }; eval "$a" 2>&1 | tee -a $RUN_LOG 2>&1; return ${PIPESTATUS[0]};
}

do_tap_tunctl()
{
    case $1 in
    add)
        sudo tunctl -p -u $USER
        sudo ifconfig tap0 $IP_ADDR up
        sudo route add -host $TEST_GATEWAY dev tap0
        ;;
    mod)
        ;;
    del)
        sudo tunctl -d tap0
        ;;
    *)
        echo "Invalid option: $*"; return 1;
        ;;
    esac
}

do_tuntap_iproute2()
{
    #echo "do_$DEV: $*"
    case $1 in
    add)
        run sudo ip tuntap add dev $DEV$2 mode $DEV user $USER
        #run sudo brctl addif $BR_DEV $DEV$2
        [[ ! -z $BR_DEV && $DEV == tap ]] && { run sudo ip link set $DEV$2 master $BR_DEV; }
        [[ ! -z $IP_ADDR && ! -z $BCAST_ADDR ]] && { run sudo ip addr add $IP_ADDR broadcast $BCAST_ADDR dev $DEV$2; }
        #run sudo ifconfig $DEV$2 $IP_ADDR netmask $NET_MASK up
        run sudo ip link set $DEV$2 up
        [[ ! -z $GATEWAY ]] && { run sudo route add -host $GATEWAY dev $DEV$2; }
        ;;
    mod)
        ;;
    del)
        [[ ! -z $GATEWAY ]] && { run sudo route del -host $GATEWAY dev $DEV$2; }
        run sudo ip link set $DEV$2 nomaster
        run sudo ip addr flush dev $DEV$2
        run sudo ip tuntap del dev $DEV$2 mode $DEV
        ;;
    *)
        echo "Invalid option: $*"; return 1;
        ;;
    esac
}

do_install()
{
    local b=$(which brctl)
    [[ -z $b ]] && run sudo apt install -y bridge-utils
    #sudo apt install -y openvpn
}

do_br()
{
    [[ -z $BR_DEV ]] && { echo "do_br(): Bridge ($BR_DEV) device not set"; exit 1; }
    #echo "do_$BR_DEV: $*"
    case $1 in
    add)
        #run sudo brctl addbr $BR_DEV
        run sudo ip link add dev $BR_DEV type bridge
        [[ ! -z $ETH_DEV ]] && { run sudo ip link set $ETH_DEV master $BR_DEV; }
        #run sudo ifconfig $BR_DEV $IP_ADDR netmask $NET_MASK up OR run sudo ip link set $BR_DEV address $IP_ADDR
        [[ ! -z $IP_ADDR && ! -z $BCAST_ADDR ]] && { run sudo ip addr add $IP_ADDR broadcast $BCAST_ADDR dev $BR_DEV; }
        run sudo ip link set dev $BR_DEV up
        [[ ! -z $GATEWAY ]] && { run sudo route add -host $GATEWAY dev $BR_DEV; }
        run sudo sysctl net.ipv4.ip_forward=1
        ;;
    mod)
        ;;
    del)
        run sudo sysctl net.ipv4.ip_forward=0
        [[ ! -z $GATEWAY ]] && { run sudo route del -host $GATEWAY dev $BR_DEV; }
        run sudo ip addr flush dev $BR_DEV

        [[ ! -z $ETH_DEV ]] && { run sudo ip link set $ETH_DEV nomaster; }
        [[ ! -z $ETH_DEV ]] && { run sudo ip link set dev $ETH_DEV down; }
        run sudo ip link set dev $BR_DEV down
        #run sudo ifconfig $BR_DEV down

        run sudo ip link del dev $BR_DEV type bridge    #run sudo brctl delbr $BR_DEV
        [[ ! -z $ETH_DEV ]] && { run sudo ip link set dev $ETH_DEV up; }
        ;;
    *)
        echo "Invalid option: $*"; return 1;
        ;;
    esac
}

show_tap_detail()
{
    local i; local s;
    for i in $(seq 0 $INF_NUM); do
        s="/sys/class/net/$i/statistics/"
        echo "$i: RX $(cat $s/rx_packets) pkts, TX $(cat $s/tx_packets) pkts";
    done
}

do_tuntap_test()
{
    [[ $# -ne 1 || -z $DEV ]] && { echo "Usage: DEV=<tun|tap> do_tuntap_test <add|mod|del>"; return 1; }
    [[ $DEV != tap && $DEV != tun ]] && { echo "Invalid device $DEV"; return 1; }
    [[ $INF_NUM -gt 254 ]] && { echo "Invalid number($INF_NUM) of devices. Valid range 0-254"; return 1; }
    [[ $1 != add && $1 != del && $1 != mod ]] && { echo "Invalid args $1" && return 1; }
    BEGIN_IP=0; END_IP=$(($INF_NUM - 1)); BR_DEV=$TEST_BR_DEV; ETH_DEV=$TEST_ETH_DEV; GATEWAY=$TEST_GATEWAY;
    [[ $1 == add ]] && do_br $INF_OP
    BCAST_ADDR=$TEST_BCAST_ADDR; NET_MASK=$TEST_NETMASK; TUN_SUBNET=$TEST_TUN_SUBNET; TAP_SUBNET=$TEST_TAP_SUBNET;
    for i in $(seq $BEGIN_IP $END_IP); do
        echo "TUN-Test: $1 $i"
        [[ $DEV == tap ]] && { IP_ADDR=$TEST_IP_SUBNET.$TAP_SUBNET.$i; }
        [[ $DEV == tun ]] && { IP_ADDR=$TEST_IP_SUBNET.$TUN_SUBNET.$i; }
        do_tuntap_iproute2 $1 $i
    done
    IP_ADDR=$TEST_BR_IP;
    [[ $1 == del ]] && do_br $INF_OP
}


# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="ha:bc:d:e:g:i:m:n:put:"
    local opts_found=0
    while getopts ":$PARSE_OPTS" opt; do
        case $opt in
        [a-zA-Z0-9])
            #log DEBUG "-$opt was triggered, Parameter: $OPTARG"
            local "opt_$opt"=1 && local "optarg_$opt"="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG"; usage; exit $EINVAL
            ;;
        :)
            echo "[ERROR] Option -$OPTARG requires an argument";
            usage; exit $EINVAL
            ;;
        esac
        shift $((OPTIND-1)) && OPTIND=1 && local opts_found=1;
    done

    if ((!opts_found)); then
        usage && exit $EINVAL;
    fi

    ((opt_h)) && { usage; help abc def ghk xyz; return; }

    #DRY_RUN=1
    ((opt_a)) && { INF_OP=add; INF_NUM=$optarg_a; }
    ((opt_d)) && { INF_OP=del; INF_NUM=$optarg_d; }
    ((opt_m)) && { INF_OP=mod; INF_NUM=$optarg_m; }
    ((opt_e)) && { ETH_DEV=$optarg_e; }
    ((opt_g)) && { GATEWAY=$optarg_g; }
    ((opt_i)) && { IP_ADDR=$optarg_i; }
    ((opt_c)) && { BCAST_ADDR=$optarg_c; }
    ((opt_n)) && { NET_MASK=$optarg_n; }

    [[ -z $INF_OP || -z $INF_NUM ]] && { echo "Interface Operation & Number missing"; usage; return 1; }
    [[ ! -z $IP_ADDR && -z $BCAST_ADDR ]] && { echo "IP address requires netmask as well"; usage; return 1; }
    ((opt_b)) && { BR_DEV="br$INF_NUM"; do_br $INF_OP; }
    ((opt_p)) && { DEV=tap; do_tuntap_iproute2 $INF_OP $INF_NUM; }
    ((opt_u)) && { DEV=tun; do_tuntap_iproute2 $INF_OP $INF_NUM; }
    ((opt_t)) && { DEV=$optarg_t; do_tuntap_test $INF_OP; }

    exit 0;
}

if [ "tuntap.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
