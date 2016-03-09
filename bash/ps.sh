#!/bin/bash
#  DETAILS: Process handling utilities
#  CREATED: 07/17/13 17:14:12 IST
# MODIFIED: 03/08/16 23:31:33 PST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

# Warn unset vars as error, Verbose (echo each command), Enable debug mode
#set -uvx

# Source .bashrc only if invoked as a sub-shell.
if [[ "$(basename ps.sh)" == "$(basename -- $0)" ]] && [ -f $HOME/.bashrc ]; then
    source $HOME/.bashrc
    log_init INFO $SCRPT_LOGS/ps.log
fi

# zomb_ps : list zombie processes
function zomb_ps () { ps hr -Nos | awk 'if ($1 == "Z") {print $1}'; }

function psid() { test -z $1 && { echo "Usage: psid <proc-name>"; return $EINVAL; } || ps h -l -C $1; }

function psname() { test -z $1 && { echo "Usage: psname <proc-id>"; return $EINVAL; } || ps h -o comm -p $1; }

# alternative: ps acx | egrep -i $@ | awk '{print $1}';
function pidof() { test -z $1 && { echo "Usage: pidof <proc-name>"; return; } || ps haxo comm,pid | awk "\$1 ~ /$@/ { print \$2 }"; }


usage()
{
    echo "usage: ps.sh []"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    if [ "$#" == "0" ]; then
        usage
        exit 1
    fi

    case $1 in
        *)
            usage
            ;;
    esac
    exit 0
}

if [ "$(basename -- $0)" == "$(basename ps.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab

