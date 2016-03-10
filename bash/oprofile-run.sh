#!/usr/bin/env bash
#  DETAILS: Profile given binary using Oprofile
#  CREATED: 04/22/13 15:13:32 IST
# MODIFIED: 10/06/14 14:21:15 IST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

# Warn unset vars as error, Verbose (echo each command), Enable debug mode
#set -uvx

#
# A script to OProfile a program.
# Must be run as root.
#

# Source .bashrc.dev only if invoked as a sub-shell.
if [[ "$(basename oprofile-run.sh)" == "$(basename -- $0)" ]] && [ -f $HOME/.bashrc.dev ]; then
    source $HOME/.bashrc.dev
    # define new ENV only if necessary.
fi

usage()
{
    echo "usage: oprofile-run.sh <path-to-binary>"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    if [ "$#" == "0" ]; then
        usage
        exit 1
    fi

    binimg=$1

    echo "Start"
    opcontrol --stop
    opcontrol --shutdown

    # Out of the box RedHat kernels are OProfile repellent.
    opcontrol --no-vmlinux
    opcontrol --reset

    # List of events for platform to be found in /usr/share/oprofile/<>/events
    opcontrol --event=L2_CACHE_MISSES:1000

    opcontrol --start

    $binimg

    opcontrol --stop
    opcontrol --dump

    rm $binimg.opreport.log
    opreport > $binimg.opreport.log

    rm $binimg.opreport.sym
    opreport -l > $binimg.opreport.sym

    opcontrol --shutdown
    opcontrol --deinit
    echo "Done"
    exit 0
}

if [ "$(basename -- $0)" == "$(basename oprofile-run.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4

