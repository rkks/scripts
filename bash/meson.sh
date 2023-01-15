#!/bin/bash
#  DETAILS: 
#  CREATED: 25/11/22 03:22:14 PM IST IST
# MODIFIED: 15/01/2023 08:12:03 PM IST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2022, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

PATH="/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin:/sbin"

[[ "$(basename meson.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

BLD_PATH=$(echo "./bld-$(uname -s)-$(uname -m)" | tr '[:upper:]' '[:lower:]');

usage()
{
    echo "Usage: meson.sh [-h|]"
    echo "Options:"
    echo "  -h          - print this help"
    echo "  -a          - clean build everything"
    echo "  -b          - start (re-)build"
    echo "  -c          - trigger (re-)configure"
    echo "  -d          - distclean build-directory"
    echo "  -p <path>   - build directory path"
    echo "blddir: $BLDDIR"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="habcdp:"
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

    ((opt_z)) && { DRY_RUN=1; LOG_TTY=1; }
    ((opt_p)) && { BLD_PATH="$optarg_p"; }
    ((opt_a || opt_d)) && { [[ -d $BLD_PATH ]] && rm -rf $BLD_PATH; }
    # meson setup deprecated, but mandatory to use for compatibility
    ((opt_a || opt_c)) && { run meson setup $BLD_PATH; bail; }
    ((opt_a || opt_b)) && { run meson compile -C $BLD_PATH; bail; }
    ((opt_i)) && { run meson install $BLD_PATH; }
    ((opt_h)) && { usage; }

    exit 0;
}

if [ "meson.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
