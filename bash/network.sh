#!/usr/bin/env bash
#  DETAILS: Network utilities
#  CREATED: 07/17/13 16:00:40 IST
# MODIFIED: 08/Apr/2021 02:49:12 PDT
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

# Warn unset vars as error, Verbose (echo each command), Enable debug mode
#set -uvx

# Source .bashrc.dev only if invoked as a sub-shell.
[[ "$(basename network.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

function arpclear() { for i in $(awk -F ' ' '{ if ( $1 ~ /[0-9{1,3}].[0-9{1,3}].[0-9{1,3}].[0-9{1,3}]/ ) print $1 }' /proc/net/arp); do arp -d $i; done; }

function dnscheck() { nslookup ${1:-google.com}; finger $USER; }

function pingmonitor()
{
    local succ=0 fail=0 last="!" tot=0 fper=0 ivl=${INTERVAL:-1} prnt=0;
    local out=${OUT_FILE:-/dev/null} dst=${1:-google.com} log_ivl=$(($ivl * 10));
    # for non-root users -f option is not allowed.
    [[ "Linux" == $(uname -s) ]] && local pingopts="-c 10" || local pingopts="-q -c 1"
    echo "ping monitor $dst, interval $ivl, dump to $out"
    while [ true ]; do
        echo "-------------------------------------------------------" >>$out 2>&1;
        date >>$out 2>&1;
        run ping $pingopts $dst >>$out 2>&1;
        [[ $? -eq 0 ]] && { last="!"; } || { fail=$((fail + 1)); last="."; }
        date >>$out 2>&1;
        [[ $last == "." ]] && { run traceroute $dst >>$out 2>&1; echo "" >>$out 2>&1; }
        #date >>$out 2>&1;
        #echo "" >>$out 2>&1;
        [[ ! -z $PING_WAIT ]] && { echo $last; [[ $last == "!" ]] && return || continue; }
        tot=$((tot + 1)); succ=$(($tot - $fail)); prnt=$(($tot % $log_ivl));
        [[ $prnt -eq 0 ]] && echo -ne "\rping($last): fail [$fail] succ[$succ] tot[$tot]";
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
    echo "  -a <interface>  - configure ip address, gateway, dns server on interface"
    echo "  -c              - clear arp database on this machine"
    echo "  -d [host-name]  - check dns query for give host (google.com - default)"
    echo "  -f <file-path>  - output terminal logs to this file (/dev/null - default)"
    echo "  -i <interval>   - use input interval instead of default (1s - default)"
    echo "  -m <host-name>  - periodically monitor ping of given host (google.com - default)"
    echo "  -w              - check ping reachability, use with -m option"
    echo "  -h              - print this help"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="ha:cdi:m:o:w"
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

    ((opt_o)) && OUT_FILE=$optarg_o || echo $optarg_o;
    ((opt_i)) && INTERVAL=$optarg_i;
    ((opt_w)) && PING_WAIT=1;
    ((opt_a)) && set_ip_addr $optarg_a;
    ((opt_c)) && arpclear;
    ((opt_d)) && dnscheck $*;
    ((opt_m || opt_w)) && pingmonitor $optarg_m;
    ((opt_h)) && { usage; exit 0; }

    exit 0
}

if [ "$(basename -- $0)" == "$(basename network.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
