#!/usr/bin/env bash
#  DETAILS: External diff tool for git
#  CREATED: 03/20/13 21:55:08 IST
# MODIFIED: 03/28/16 17:47:03 IST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

#set -uvx               # Treat unset variables as an error, verbose, debug mode
[[ "$(basename git.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

function add_ssh_key()
{
    [[ $# -ne 1 -o ! -e $1 ]] && { echo "usage: add_ssh_key <rsa/dsa-priv-file>"; echo "  ex. ~/.ssh/id_rsa"; return 1; }
    local agent=$(eval "$(ssh-agent -s)")
    [[ $agent =~ Agent* ]] && { ssh-add $*; }
}

function usage()
{
    echo "usage: git.sh <path> <old-file> <old-hex> <old-mode> <new-file> <new-hex> <new-mode>"
    echo "Usual set of arguments provided by git while invoking external diff program"
    echo "OR"
    echo "usage: git.sh [-h|-a]"
    echo "  -a <ssh-priv-key>       - add ssh private key to agent. ex: ~/.ssh/id_rsa"
    echo "  -h                      - print this help message"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    local DIFF=$(which diff 2>/dev/null);
    [[ $# -eq 7 -a ! -z $DIFF ]] && { $DIFF "$2" "$5"; exit 0; }       # echo $*

    PARSE_OPTS="ha:"
    local opts_found=0
    while getopts ":$PARSE_OPTS" opt; do
        case $opt in
        [a-zA-Z0-9])
            #echo DEBUG "-$opt was triggered, Parameter: $OPTARG"
            local "opt_$opt"=1 && local "optarg_$opt"="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG"; usage; exit $EINVAL
            ;;
        :)
            echo "[ERROR] Option -$OPTARG requires an argument";
            usage; exit $EINVAL
            ;;
        esac
        shift $((OPTIND-1)) && OPTIND=1 && local opts_found=1;
    done

    if ((!opts_found)); then
        usage && exit $EINVAL;
    fi

    ((opt_a)) && { add_ssh_key $optarg_a; }
    ((opt_h)) && { usage; }

    exit 0;
}

if [ "$(basename -- $0)" == "$(basename git.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4
