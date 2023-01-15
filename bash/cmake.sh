#!/bin/bash
#  DETAILS: 
#  CREATED: 25/12/22 11:50:49 AM IST IST
# MODIFIED: 15/01/2023 08:10:52 PM IST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2022, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

PATH="/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin:/sbin"

[[ "$(basename cmake.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

BLD_BASE="$PWD";
BLD_PATH=$(echo "./bld-$(uname -s)-$(uname -m)" | tr '[:upper:]' '[:lower:]');
CMAKE_OPTS="-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON"
MAKE_OPTS="";   # "VERBOSE=1" --no-print-directory

usage()
{
    echo "Usage: cmake.sh [-h|-a|-b|-c|-d|-p|-z]"
    echo "Options:"
    echo "  -h              - print this help"
    echo "  -z              - dry run this script"
    echo "  -a              - clean build everything (-c -d -b)"
    echo "  -b              - build from generated files"
    echo "  -c              - generate config, makefiles"
    echo "  -d              - delete/clean everything"
    echo "  -p <dir-name>   - use this build dir path"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="habcdp:z"
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

    ((opt_z)) && { DRY_RUN=1; LOG_TTY=1; }
    ((opt_p)) && { BLD_PATH="./$optarg_p"; }
    ((opt_a || opt_d)) && { [[ -d $BLD_PATH ]] && run rm -rf $BLD_PATH; }
    ((opt_a || opt_b || opt_c)) && { mkdie $BLD_PATH && cdie $BLD_PATH; bail; }
    ((opt_a || opt_c)) && { run cmake $CMAKE_OPTS ../; bail; }
    ((opt_a || opt_b)) && { run make $MAKE_OPTS; bail; }
    ((opt_h)) && { usage; }

    exit 0;
}

if [ "cmake.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
