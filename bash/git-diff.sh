#!/usr/bin/env bash
#  DETAILS: External diff tool for git
#  CREATED: 03/20/13 21:55:08 IST
# MODIFIED: 10/06/14 14:20:34 IST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

#set -uvx               # Treat unset variables as an error, verbose, debug mode

DIFF=$(which diff 2>/dev/null)

usage()
{
    echo "usage: git-diff.sh <path> <old-file> <old-hex> <old-mode> <new-file> <new-hex> <new-mode>"
    echo "Usual set of arguments provided by git while invoking external diff program"
}

main()
{
    echo $*
    [ $# -eq 7 ] && $DIFF "$2" "$5"
}

if [ "$(basename -- $0)" == "$(basename git-diff.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4

