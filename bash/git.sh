#!/usr/bin/env bash
#  DETAILS: External diff tool for git
#  CREATED: 03/20/13 21:55:08 IST
# MODIFIED: 03/22/18 12:50:51 IST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

#set -uvx               # Treat unset variables as an error, verbose, debug mode
[[ "$(basename git.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

# To change remote url for github repo from https to ssh, do
# git remote set-url origin git@github.com:rkks/scripts.git

# .mailmap allows users with different email-addrs to be recognized by same name
function add_mailmap()
{
    git shortlog -se | awk -F'[ -' '{print $2,$3,$2,$3}' | sort > .mailmap
    # Now manually edit .mailmap to name all emails belonging to single person
    # with same Name/title. So that release-notes generates grouping with name
}

function configure_local_repo()
{
    [[ $# -ne 1 ]] && { echo "usage: set_local_repo_user <key-value-conf-file-path>"; return 1; }
    while IFS== read -r key value; do
        echo "git config $key \"$value\"";
        git config $key "$value";
    done < $1;
}

function add_ssh_key()
{
    [[ $# -ne 1 ]] && { echo "usage: add_ssh_key <rsa/dsa-priv-file>"; echo "  ex. ~/.ssh/id_rsa"; return 1; }
    [[ ! -e $1 ]] && { echo "$1 not found"; return 1; }
    local agent=$(eval "$(ssh-agent -s)")
    [[ $agent =~ Agent* ]] && { ssh-add $*; } || return 1;
    ssh -T git@bitbucket.org;   # watch for username printed in 'logged in as rkks'
    ssh -T git@github.com;      # watch for username printed in "Hi rkks! You've successfully authenticated""'"
}

function track_branch_all()
{
    # Tracks all branches with remote
    for branch in `git branch -a | grep remotes | grep -v HEAD | grep -v master `; do
        git branch --track ${branch#remotes/origin/} $branch
    done
}

function git_diff()
{
    local output="$(date +%d%m%Y-%H%M%S)-$@-$(id -nu)-u.diff";
    echo "diff output: $PWD/$output";
    git dir > $output;
}

function usage()
{
    echo "usage: git.sh <path> <old-file> <old-hex> <old-mode> <new-file> <new-hex> <new-mode>"
    echo "Usual set of arguments provided by git while invoking external diff program"
    echo "OR"
    echo "usage: git.sh [-h|-a]"
    echo "  -a <ssh-priv-key>   - add ssh private key to agent. ex: ~/.ssh/id_rsa"
    echo "  -c <kv-conf-path>   - use given key-val file to configure local repo"
    echo "  -d <diff-name>      - use given diff-name generate diff-file"
    echo "  -t                  - track all branches in remote repo"
    echo "  -h                  - print this help message"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    local DIFF=$(which diff 2>/dev/null);
    [[ $# -eq 7 ]] && { [[ ! -z $DIFF ]] && $DIFF "$2" "$5"; exit 0; }  # echo $*

    PARSE_OPTS="ha:d:c:t"
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
    ((opt_d)) && { git_diff $optarg_d; }
    ((opt_c)) && { configure_local_repo $optarg_c; }
    ((opt_t)) && { track_branch_all $optarg_t; }
    ((opt_h)) && { usage; }

    exit 0;
}

if [ "$(basename -- $0)" == "$(basename git.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4
