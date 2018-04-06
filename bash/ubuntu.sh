#!/bin/bash
#  DETAILS: ubuntu quirks and it's remedies
#  CREATED: 04/05/18 10:34:37 PDT
# MODIFIED: 04/05/18 10:38:58 PDT
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2018, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

PATH=/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin

[[ "$(basename ubuntu.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

function apt_cleanup()
{
    # remove third-party pkg repos, they cause problems
    sudo apt update
    sudo apt clean
    sudo apt autoclean
    [[ $# -ne 0 ]] && sudo dpkg --remove --force-remove-reinstreq $*
    sudo apt autoremove -f
}

usage()
{
    echo "Usage: ubuntu.sh [-h|]"
    echo "Options:"
    echo "  -h          - print this help"
    echo "  -c          - cleanup apt install cache, broken links"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="hc"
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

    ((opt_h)) && { usage; }
    ((opt_c)) && { apt_cleanup $*; }

    exit 0;
}

if [ "ubuntu.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
