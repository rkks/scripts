#!/usr/bin/env bash
#  DETAILS: Network utilities
#  CREATED: 07/17/13 16:00:40 IST
# MODIFIED: 09/08/14 10:40:36 IST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

# Warn unset vars as error, Verbose (echo each command), Enable debug mode
#set -uvx

# Source .bashrc only if invoked as a sub-shell.
if [[ "$(basename network.sh)" == "$(basename -- $0)" ]] && [ -f $HOME/.bashrc ]; then
    source $HOME/.bashrc
    log_init INFO $SCRIPT_LOGS/network.log
fi

function arpclear() { for i in $(awk -F ' ' '{ if ( $1 ~ /[0-9{1,3}].[0-9{1,3}].[0-9{1,3}].[0-9{1,3}]/ ) print $1 }' /proc/net/arp); do arp -d $i; done; }

function dnscheck() { nslookup ${1:-google.com}; finger $USER; }

function pingwait()
{
    pingable=0;
    # for non-root users -f option is not allowed.
    [[ "Linux" == $(uname -s) ]] && local pingopts="-q -c 1" || local pingopts="-q -c 1"
    while [ $pingable -eq 0 ]; do
        ping $pingopts ${1:-google.com} 2>&1 >/dev/null;
        [[ $? -eq 0 ]] && { pingable=1; echo "!"; } || { echo -n "."; sleep 5; }
    done
}

usage()
{
    echo "usage: network.sh []"
    echo "usage: find.sh <-a|-d [host-name]|-p <host-name>|-h>"
    echo "Options:"
    echo "  -a              - clear arp database on this machine"
    echo "  -d [host-name]  - check dns query for give host (google.com - default)"
    echo "  -p [host-name]  - check ping reachability of given host (google.com - default)"
    echo "  -h              - print this help"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="hadps"
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

    ((opt_a)) && arpclear;
    ((opt_d)) && dnscheck $*;
    ((opt_p)) && pingwait $*;
    ((opt_h)) && { usage; exit 0; }

    exit 0
}

if [ "$(basename -- $0)" == "$(basename network.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab

