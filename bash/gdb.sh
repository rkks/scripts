#!/bin/bash
#  DETAILS: 
#  CREATED: 09/02/21 01:12:23 PM IST IST
# MODIFIED: 01/Sep/2021 15:18:58 IST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2021, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

PATH=/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin:/sbin

[[ "$(basename gdb.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

usage()
{
    echo "Usage: gdb.sh [-h|]"
    echo "Options:"
    echo "  -h          - print this help"
}

function generate_core()
{
    # -n : do not source/run any .gdbinit files
    # -x : run cmds listed in input batch-file
    sudo gdb -n -x $GDB_CMDS_FILE
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="hc:x:"
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

    ((opt_x)) && { GDB_CMDS_FILE=$optarg_x; } || { GDB_CMDS_FILE="$HOME/.gdbinit"; }
    ((opt_c)) && { generate_core $*; }
    ((opt_h)) && { usage; }

    exit 0;
}

if [ "gdb.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
