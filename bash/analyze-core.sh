#!/usr/bin/env bash
#  DETAILS: Provides brief analysis of cores. Adopted from 
#  CREATED: 03/29/13 18:22:18 IST
# MODIFIED: 01/20/14 14:38:28 IST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

# Warn unset vars as error, Verbose (echo each command), Enable debug mode
#set -uvx

# Source .bashrc only if invoked as a sub-shell.
if [[ "$(basename analyze-core.sh)" == "$(basename $0)" ]] && [ -f $HOME/.bashrc ]; then
    source $HOME/.bashrc
    # Global defines. (Re)define ENV only if necessary.
fi

usage()
{
    echo "usage: analyze-core.sh <binary> <core>"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    if [ "$#" == "0" ]; then
        usage
        exit 1
    fi

    bin=$1
    core=$2
    log="$core-gdb.log"

    run gdb -batch \
        -ex "set logging file $log" \
        -ex "set logging on" \
        -ex "set pagination off" \
        -ex "printf \"**\n** Process info for $bin - $core \n** Generated `date`\n\"" \
        -ex "printf \"**\n** $(ls -l $bin) \n** $(ls -l $core)\n**\n\"" \
        -ex "file $bin" \
        -ex "core-file $core" \
        -ex "bt" \
        -ex "info proc" \
        -ex "printf \"*\n* Libraries \n*\n\"" \
        -ex "info sharedlib" \
        -ex "printf \"*\n* Memory map \n*\n\"" \
        -ex "info target" \
        -ex "printf \"*\n* Registers \n*\n\"" \
        -ex "info registers" \
        -ex "printf \"*\n* Current instructions \n*\n\"" -ex "x/16i \$pc" \
        -ex "printf \"*\n* Threads (full) \n*\n\"" \
        -ex "info threads" \
        -ex "bt" \
        -ex "thread apply all bt full" \
        -ex "printf \"*\n* Threads (basic) \n*\n\"" \
        -ex "info threads" \
        -ex "thread apply all bt" \
        -ex "printf \"*\n* Done \n*\n\"" \
        -ex "quit"

    exit 0
}

if [ "$(basename $0)" == "$(basename analyze-core.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4

