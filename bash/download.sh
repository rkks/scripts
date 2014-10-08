#!/usr/bin/env bash
#  DETAILS: Downloads all links provided in ~/conf/custom/downloads file
#  CREATED: 11/19/12 12:43:39 IST
# MODIFIED: 10/08/14 11:29:03 IST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2012, Ravikiran K.S.

#set -uvx               # Treat unset variables as an error, verbose, debug mode

# Source .bashrc only if invoked as a sub-shell.
if [[ "download.sh" == "$(basename -- $0)" ]] && [ -f $HOME/.bashrc ]; then
    source $HOME/.bashrc
    log_init INFO $SCRIPT_LOGS/download.log
fi

usage()
{
    echo "usage: download.sh <links-file>"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    [[ $# -ne 1 ]] && { usage; exit $EINVAL; } || { local linkfile=$1; }

    [[ ! -f $linkfile ]] && { die $ENOENT "$linkfile not found. No pending downloads"; }
    [[ ! -d $DOWNLOADS ]] && { run mkdir -p $DOWNLOADS; }
    run cdie $DOWNLOADS
    while read line
    do
        log INFO "Download $line"
        run wget -c -o wget-$(basename $line).log -t 3 -b $line;
        if [ "$?" != "0" ]; then
            log ERROR "Error downloading $line"
        fi
    done<$linkfile

    log INFO "Clean download list"
    cat /dev/null > $linkfile;

    exit 0
}

if [ "$(basename -- $0)" == "$(basename download.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4
