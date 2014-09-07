#!/usr/bin/env bash
#  DETAILS: Do copy of binary while showing progress bar similar to wget
#  CREATED: 03/18/13 14:30:31 IST
# MODIFIED: 01/20/14 14:39:08 IST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

#set -uvx               # Treat unset variables as an error, verbose, debug mode

# Source .bashrc only if invoked as a sub-shell. Not when sourced.
if [[ "$(basename cpv.sh)" == "$(basename $0)" ]] && [ -f $HOME/.bashrc ]; then
    source $HOME/.bashrc
    # Global defines. (Re)define ENV only if necessary.
fi

usage()
{
    echo "usage: cpv.sh <src> <dst>"
    echo "doesnt support multi-src copy"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    if [ "$#" == "2" ]; then
        usage
        exit 1
    fi

    strace -q -ewrite cp -- "${1}" "${2}" 2>&1 \
        | awk '{
    count += $NF
    if (count % 10 == 0) {
        percent = count / total_size * 100
        printf "%3d%% [", percent
        for (i=0;i<=percent;i++)
            printf "="
            printf ">"
            for (i=percent;i<100;i++)
                printf " "
                printf "]\r"
            }
        }
        END { print "" }' total_size=$(stat -c '%s' "${1}") count=0
    exit 0
}

if [ "$(basename $0)" == "$(basename cpv.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4

