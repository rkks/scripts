#!/bin/bash
#  DETAILS: 
#  CREATED: 09/11/21 14:46:07 IST
# MODIFIED: 11/Sep/2021 15:43:05 IST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2021, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

PATH=/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin:/sbin

[[ "$(basename vnc.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

usage()
{
    echo "Usage: vnc.sh [-h|]"
    echo "Options:"
    echo "  -h          - print this help"
    echo "  -l          - list vnc server"
    echo "  -s          - start vnc server"
    echo "  -t          - stop vnc server"
}

# It is better to use vncserver -list than $(pgrep vncconfig), Also, do not use
# "exec vncserver", as that does replace login shell with new child process
function start_vnc()
{
    [[ $# -lt 1 ]] && return;
    [[ -z $(which vncserver) ]] && { echo "No VNC server found"; return; }
    local nvnc=$(vncserver -list | grep -E "\:$1" | wc -l)
    [[ $nvnc -eq 0 ]] && { vncserver "\:$1" -localhost no -geometry 1920x1080; }
}

function stop_vnc()
{
    [[ $# -lt 1 ]] && return;
    [[ -z $(which vncserver) ]] && { echo "No VNC server found"; return; }
    local nvnc=$(vncserver -list | grep -E "\:$1" | wc -l)
    [[ $nvnc -ne 0 ]] && { vncserver -kill "\:$1"; }
}

function list_vnc()
{
    [[ -z $(which vncserver) ]] && { echo "No VNC server found"; return; }
    vncserver -list;
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="hls:t:"
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

    #set -x; echo $*
    ((opt_l)) && { list_vnc $*; }
    ((opt_t)) && { stop_vnc $optarg_t $*; }
    ((opt_s)) && { start_vnc $optarg_s $*; }
    ((opt_h)) && { usage; }

    exit 0;
}

if [ "vnc.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
