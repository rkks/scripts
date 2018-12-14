#!/usr/bin/env bash
#  DETAILS: Makes log file by redirecting both stdout and stderr.
#           The main difference is, this uses 'tee' than >.
#  CREATED: 11/13/12 19:09:06 IST
# MODIFIED: 14/Dec/2018 07:00:05 PST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2012, Ravikiran K.S.

#set -uvx               # Treat unset variables as an error, verbose, debug mode

# Source .bashrc.dev only if invoked as a sub-shell.
[[ "run.sh" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

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

usage()
{
    echo "Usage: run.sh [-c <cmds-list-file>|-e <email-addresses>]"
    echo "Options:"
    echo "  -c <cmd-list-file>  - file having list of commands to be run"
    echo "  -e <email-addrs>    - list of email addresses to notify"
    echo "  -h                  - print this help message"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    local PARSE_OPTS="hc:e:"
    local opts_found=0
    while getopts ":$PARSE_OPTS" opt; do
        case $opt in
            [a-zA-Z0-9])
                log DEBUG "-$opt was triggered, Parameter: $OPTARG"
                local "opt_$opt"=1 && local "optarg_$opt"="$OPTARG"
                ;;
            \?)
                echo "Invalid option: -$OPTARG"; usage; exit $EINVAL;
                ;;
            :)
                echo "[ERROR] Option -$OPTARG requires an argument";
                usage; exit $EINVAL;
                ;;
        esac
        shift $((OPTIND-1)) && OPTIND=1 && local opts_found=1;
    done

    if ((!opts_found)); then
        usage && exit $EINVAL;
    fi

    ((opt_h)) && { usage; exit 0; }
    #export SHDEBUG=yes;
    ((opt_e)) && { NOTIFY_EMAIL="$optarg_e"; } || { NOTIFY_EMAIL=$COMP_EMAIL_ID; }
    ((opt_c)) && { RUN_LOG="run.log"; truncate --size 0 $RUN_LOG; batch_run $optarg_c; }

    exit 0
}

if [ "$(basename -- $0)" == "run.sh" ]; then
    main $*
fi
# VIM: ts=4:sw=4
