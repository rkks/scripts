#!/usr/bin/env bash
#  DETAILS: Displays file extension
#  CREATED: 12/19/12 21:12:25 IST
# MODIFIED: 10/06/14 14:20:24 IST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2012, Ravikiran K.S.

#set -uvx               # Treat unset variables as an error, verbose, debug mode

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    [[ "$#" != "1" ]] && die $EINVAL "usage: extension.sh <file>"

    filepath=$1
    filename=$(basename "$filepath")
    extension="${filename##*.}"
    filename="${filename%.*}"
    echo $extension
    exit 0
}

if [ "$(basename -- $0)" == "$(basename extension.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4

