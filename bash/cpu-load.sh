#!/bin/bash
#  DETAILS: Collect cpu load at regular intervals of time
#  CREATED: 04/11/17 11:09:03 IST
# MODIFIED: 04/Apr/2022 21:33:40 PDT
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2017, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

PATH=/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin

RECORDS_DIR="/bootflash"
NEW_REC_SEPARATOR="================================================================================";
SLEEP_DURATION=5;       # 5sec is not too aggressive, but granular enough
LOOP_COUNTER=1;         # default is 1 iteration
ROTATE_COUNTER=60;      # 60 rotations in 30secs
ROTATE_DIR="/var/log/external";

# print to stderr. echo swallows -e, -n, options: { >&2 echo -- $*; }
function log_warn() { >&2 printf "%s\n" "$@"; }
function log_dump() { printf "%s\n" "$@"; }
function die()  { log_warn "$@"; exit 1; }

usage()
{
    log_warn "Usage: cpu-load.sh [-h|]"
    log_warn "Options:"
    log_warn "  -h          - print this help message"
    log_warn "  -c <count>  - loop count for record collect"
    log_warn "  -d <dir>    - records dump directory path"
    log_warn "  -s <secs>   - sleep interval (default: 5s)"
    log_warn "  -t <fname>  - file name for records write"
}

function rotate_file()
{
    [[ $# -ne 1 ]] && { die "usage: rotate_file <file-name>"; }
    fname="$1";
    local cnt=0;
    #while true; do
    while [ $ROTATE_COUNTER -gt 0 ]; do
        ROTATE_COUNTER=$[$ROTATE_COUNTER-1];
        cnt=$[$cnt+1];
        cp $1 /bootflash/$1.$cnt
        sleep 0.5;
    done
}

function count_top()
{
    [[ $# -ne 1 ]] && { die "usage: count_top <file-name>"; }
    fname="$RECORDS_DIR/$1";
    #while true; do
    while [ $LOOP_COUNTER -gt 0 ]; do
        LOOP_COUNTER=$[$LOOP_COUNTER-1];
        echo $NEW_REC_SEPARATOR >> $fname;
        top -d 1 -n 1 -b >> $fname;
        sleep $SLEEP_DURATION;
    done
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="hc:d:r:s:t:"
    local opts_found=0
    while getopts ":$PARSE_OPTS" opt; do
        case $opt in
        [a-zA-Z0-9])
            #warn DEBUG "-$opt was triggered, Parameter: $OPTARG"
            local "opt_$opt"=1 && local "optarg_$opt"="$OPTARG"
            ;;
        \?)
            log_warn "Invalid option: -$OPTARG"; usage; exit $EINVAL
            ;;
        :)
            log_warn "[ERROR] Option -$OPTARG requires an argument";
            usage; exit $EINVAL
            ;;
        esac
        shift $((OPTIND-1)) && OPTIND=1 && local opts_found=1;
    done

    if ((!opts_found)); then
        usage && exit $EINVAL;
    fi

    ((opt_c)) && { LOOP_COUNTER="$optarg_c"; }
    ((opt_d)) && { RECORDS_DIR="$optarg_d"; }
    ((opt_r)) && { rotate_file "$optarg_r"; }
    ((opt_s)) && { SLEEP_DURATION="$optarg_s"; }
    ((opt_t)) && { count_top "$optarg_t"; }
    ((opt_h)) && { usage; }

    exit 0;
}

if [ "cpu-load.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
