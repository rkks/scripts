#!/bin/bash
#  DETAILS: RPM wrappers
#  CREATED: 07/16/13 21:11:04 IST
# MODIFIED: 03/08/16 23:31:56 PST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

# Warn unset vars as error, Verbose (echo each command), Enable debug mode
#set -uvx

# Source .bashrc.dev only if invoked as a sub-shell.
if [[ "$(basename rpm.sh)" == "$(basename -- $0)" ]] && [ -f $HOME/.bashrc.dev ]; then
    source $HOME/.bashrc.dev
    log_init INFO $SCRPT_LOGS/rpm.log
fi

# Create cpio image with all files under current directory (no recurse)
function mkcpio() { test -z $1 && { echo "Usage: mkcpio <rpm-name>"; return $EINVAL; } || (ls | cpio -o > $1); }

function rpm2dir()
{
    [[ $# -ne 1 ]] && { echo "usage: rpm2dir <rpm-name>"; return $EINVAL; }
    (own rpm2cpio) && rpm2cpio $1 | cpio -idv
}

function whichrpm()
{
    [[ $# -ne 1 ]] && { echo echo "usage: whichrpm <command-name>"; return $EINVAL; }
    COMMAND=$(which $1 2>/dev/null)
    [[ -z $COMMAND ]] && { echo "Command $COMMAND not found"; return $ENOENT; }
    echo "Short:"; rpm -q --whatprovides $COMMAND; echo "\nDetail:"; rpm -qif $COMMAND;
}


usage()
{
    echo "usage: rpm.sh []"
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

if [ "$(basename -- $0)" == "$(basename rpm.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab

