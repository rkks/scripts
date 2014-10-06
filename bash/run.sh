#!/usr/bin/env bash
#  DETAILS: Runs input binary with all arguments provided.
#           - Checks if binary has executable permission
#           - Checks return value of process and notifies of error
#           - Checks of any intermittent errors
#  CREATED: 03/13/13 12:26:16 IST
# MODIFIED: 10/06/14 14:21:31 IST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

#set -uvx               # Treat unset variables as an error, verbose, debug mode

# Source .bashrc only if invoked as a sub-shell.
if [[ "$(basename run.sh)" == "$(basename -- $0)" ]] && [ -f $HOME/.bashrc ]; then
    source $HOME/.bashrc
    # define new ENV only if necessary.
fi

#LOGGER=/usr/bin/logger -t logrotate

run-binary()
{
    if [ "$(basename $1)" == "$1" ]; then
        bin=$(which $1)
    else
        # Input has been given with path.
        bin=$1
    fi
    shift;
    if [ ! -x $bin ]; then
        echo "ALERT! $bin doesnt have exec perms"
        exit 1
    fi
    $bin $*
    if [ "$?" != "0" ]; then
        $LOGGER "ALERT! $bin exited abnormally with [$?]"
    fi
}

run-bash()
{
    TMPFILE=$(mktemp -q -t raviks)
    count=0;
    echo $EDITOR
    vim $TMPFILE && $(cat $TMPFILE)
    res=$?
    while [ $res -ne 0 ] && [ $count -lt 2 ]; do
        echo "Command $(cat $TMPFILE) failed. Reinspect"
        $EDITOR $TMPFILE && $(cat $TMPFILE);
        res=$?
        let count=count+1;
    done
    rm -f $TMPFILE
}

usage()
{
    echo "usage: run.sh [<binary> [binary-opts]]"
    echo "note: In absence of any input, invokes $EDITOR to input command"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    if [ "$#" == "0" ]; then
        run-bash
        exit 0
    fi

    case $1 in
        'bin')
            shift
            run-binary  $*
            ;;
        *)
            usage
            ;;
    esac
    exit 0
}

if [ "$(basename -- $0)" == "$(basename run.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4

