#!/usr/bin/env bash
#  DETAILS: Network utilities
#  CREATED: 07/17/13 16:00:40 IST
# MODIFIED: 10/Aug/2020 09:41:54 IST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

# Warn unset vars as error, Verbose (echo each command), Enable debug mode
#set -uvx

# Source .bashrc.dev only if invoked as a sub-shell.
[[ "$(basename network.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

function arpclear() { for i in $(awk -F ' ' '{ if ( $1 ~ /[0-9{1,3}].[0-9{1,3}].[0-9{1,3}].[0-9{1,3}]/ ) print $1 }' /proc/net/arp); do arp -d $i; done; }

function dnscheck() { nslookup ${1:-google.com}; finger $USER; }

function pingwait()
{
    local pingable=0;
    # for non-root users -f option is not allowed.
    [[ "Linux" == $(uname -s) ]] && local pingopts="-q -c 1" || local pingopts="-q -c 1"
    while [ $pingable -eq 0 ]; do
        ping $pingopts ${1:-google.com} 2>&1 >/dev/null;
        [[ $? -eq 0 ]] && { pingable=1; echo "!"; } || { echo -n "."; sleep 5; }
    done
}

function pingmonitor()
{
    local succ=0 fail=0 last="!" tot=0 fper=0 ivl=5;
    # for non-root users -f option is not allowed.
    [[ "Linux" == $(uname -s) ]] && local pingopts="-q -c 1" || local pingopts="-q -c 1"
    echo "ping monitor ${1:-google.com}, interval $ivl"
    while [ true ]; do
        #ping $pingopts ${1:-google.com}  >/dev/null 2>&1;
        ping $pingopts ${1:-google.com} >/dev/null 2>&1;
        [[ $? -eq 0 ]] && { last="!"; } || { fail=$((fail + 1)); last="."; }
        tot=$((tot + 1)); succ=$(($tot - $fail))
        echo -ne "\rping($last): fail [$fail] succ[$succ] tot[$tot]";
        sleep $ivl;
    done
}

function set_ip_addr()
{
    read_cfg $HOME/conf/template/ifconfig;
    #export LOG_TTY=1; DRY_RUN=1;
    run sudo ifconfig $1 $ADDRESS netmask $NETMASK up
    run sudo route add default gw $GATEWAY
    run echo \"dns-nameservers $NAMESVR\" \>\> /etc/network/interfaces;     # /etc/resolv.conf get overwritten
    clean_cfg;
}

usage()
{
    echo "usage: network.sh []"
    echo "usage: find.sh <-a|-d [host-name]|-p <host-name>|-h>"
    echo "Options:"
    echo "  -c              - clear arp database on this machine"
    echo "  -d [host-name]  - check dns query for give host (google.com - default)"
    echo "  -p [host-name]  - check ping reachability of given host (google.com - default)"
    echo "  -m [host-name]  - periodically monitor ping of given host (google.com - default)"
    echo "  -i <interface>  - configure ip address, gateway, dns server on interface"
    echo "  -h              - print this help"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="hcdi:mp"
    local opts_found=0
    while getopts ":$PARSE_OPTS" opt; do
        case $opt in
            [a-zA-Z0-9])
                log DEBUG "-$opt was triggered, Parameter: $OPTARG"
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

    ((opt_c)) && arpclear;
    ((opt_d)) && dnscheck $*;
    ((opt_m)) && pingmonitor $*;
    ((opt_p)) && pingwait $*;
    ((opt_i)) && set_ip_addr $optarg_i;
    ((opt_h)) && { usage; exit 0; }

    exit 0
}

if [ "$(basename -- $0)" == "$(basename network.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab

