#!/usr/bin/env bash
#  DETAILS: Makes log file by redirecting both stdout and stderr.
#           The main difference is, this uses 'tee' than >.
#  CREATED: 11/13/12 19:09:06 IST
# MODIFIED: 09/08/14 10:41:40 IST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2012, Ravikiran K.S.

#set -uvx               # Treat unset variables as an error, verbose, debug mode

# Source .bashrc only if invoked as a sub-shell.
if [[ "$(basename teelog.sh)" == "$(basename -- $0)" ]] && [ -f $HOME/.bashrc ]; then
    source $HOME/.bashrc
    # Global defines. (Re)define ENV only if necessary.
fi

usage()
{
    echo "usage: teelog.sh <stdout-log-name> <stderr-log-name>"
}

# Untested. This may not work for command with command line inputs
teelog-alternate()
{
    command=$1
    stdout=$2
    stderr=$3

    out="${TMPDIR:-/tmp}/out.$$" err="${TMPDIR:-/tmp}/err.$$"
    mkfifo "$out" "$err"
    trap 'rm "$out" "$err"' EXIT
    tee $stdout < "$out" &
    tee $stderr < "$err" >&2 &

    $command >"$out" 2>"$err"
}

teelog()
{
    stdout=$1
    stderr=$2
    echo -n "> >(tee "$stdout") 2> >(tee "$stderr" >&2)"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    if [ "$#" != "2" ]; then
        usage
        exit 1
    fi

    teelog $*
    exit 0
}

if [ "$(basename -- $0)" == "$(basename teelog.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4

