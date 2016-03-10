#!/bin/bash
#  DETAILS: Sync IETF RFCs to local workspace
#  CREATED: 10/16/14 16:10:03 IST
# MODIFIED: 03/08/16 23:33:45 PST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2014, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

if [ "ietf-sync.sh" == "$(basename $0)" ] && [ -f $HOME/.bashrc.dev ]; then
    source $HOME/.bashrc.dev
    log_init INFO $SCRPT_LOGS/ietf-sync.sh.log
fi

usage()
{
    echo "Usage: ietf-sync.sh [-h|-a|-c|-i|-l|-m|-p] <dir-name>"
    echo "Options:"
    echo "  -a     - sync entire ietf ftp site"
    echo "  -c     - sync charter module"
    echo "  -i     - sync internet-drafts module"
    echo "  -l     - list all modules available for sync"
    echo "  -m     - sync mailman-archive module"
    echo "  -p     - sync proceedings module"
    echo "  -h     - print this help"
    echo "IMP: retains old copies, does not delete"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="hacilmp"
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

    ((opt_h)) && { usage; exit 0; }
    ((opt_l)) && { rsync rsync.ietf.org:: && exit 0; }    # list modules
    [[ $# -eq 1 ]] && { mkdir -pv $1; } || { usage; exit $EINVAL; }
    ((opt_a)) && { rsync -avz rsync.ietf.org::everything-ftp $1; }    # all
    ((opt_c)) && { rsync -avz rsync.ietf.org::charter $1; }    # charter
    ((opt_i)) && { rsync -avz rsync.ietf.org::internet-drafts $1; }    # internet
    ((opt_m)) && { rsync -avz rsync.ietf.org::mailman-archive $1; }    # maillist
    ((opt_p)) && { rsync -avz rsync.ietf.org::proceedings $1; }    # proceeds

    exit 0;
}

if [ "ietf-sync.sh" == "$(basename $0)" ]; then
main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab

