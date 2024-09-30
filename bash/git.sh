#!/usr/bin/env bash
#  DETAILS: External diff tool for git
#  CREATED: 03/20/13 21:55:08 IST
# MODIFIED: 30/09/24 11:00:09 PM IST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

#set -uvx       # Treat unset variables as an error, verbose, debug mode
[[ "$(basename git.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

# TODO: Add support for git submodule add & delete from given path
git_submodule_add()
{
    git lspriv;
}

# https://gist.github.com/myusuf3/7f645819ded92bda6677
git_submodule_del()
{
    git rm --cached $1;
}

# .mailmap allows users with different email-addrs to be recognized by same name
function add_mailmap()
{
    git shortlog -se | awk -F'[ -' '{print $2,$3,$2,$3}' | sort > .mailmap
    # Now manually edit .mailmap to name all emails belonging to single person
    # with same Name/title. So that release-notes generates grouping with name
}

function new_remote()
{
    [[ $# -ne 2 ]] && { echo "usage: new_remote <remote-name> <url>"; return; }
    local remote=$1; local url=$2;
    # git remote add bitbucket git@bitbucket.org:mrksravikiran/wiki.git
    git remote add $remote $url;
    git push --all $remote;
    git push --tags $remote;
}

function config_local_repo()
{
    [[ $# -ne 1 ]] && { echo "usage: set_local_repo_user <key-value-conf-file-path>"; return 1; }
    [[ ! -z $COMP_CONFS ]] && cp $COMP_CONFS/vimrc.local "$PWD/.vimrc.local"
    while IFS== read -r key value; do
        [[ $key == \#* ]] && { continue; }
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

function git_pull_update()
{
    [[ $# -eq 0 ]] && { echo "Usage: $FUNCNAME <repo-path>"; return $EINVAL; }
    [[ ! -d $1 ]] && { echo "$FUNCNAME: no repo $1 exists"; return $ENOENT; }
    local UPDLOG=update.log;
    cdie $1 && echo "update repo: $PWD" && git pa >> $UPDLOG && git cln >> $UPDLOG;
}

# pulls every remote branch from every remote repo by adding tracking & rebasing
git_pull_all()
{
    git branch -r | grep -v '\->' | sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" | while read remote; do git branch --track "${remote#origin/}" "$remote"; done
    git fetch --all
    git pull --all
}

function git_diff()
{
    if [ -z $DIFF_NM ]; then
        [[ "$@" == "nightly" ]] && { DIFF_NM="$(date +%d%m%Y)-nightly-$(id -nu)-u.diff"; } || { DIFF_NM="$(date +%d%m%Y-%H%M%S)-$@-$(id -nu)-u.diff"; }
    fi
    echo "diff output: $PWD/$DIFF_NM";
    git dir > $DIFF_NM;
}

function git_clone() { [[ -z $GIT_REPO ]] && { return $EINVAL; } || { git clone $GIT_REPO $BRANCH $*; }; }

function cherry_pick()
{
    [[ $# -ne 3 ]] && { echo "usage: cherry_pick <sha> <from-br> <to-br1,to-br2,..,to-brN>"; return; }
    local sha=$1; shift; local from_br=$1; shift; local to_brs=$(echo "$*" | sed 's/,/ /g'); local br;
    local curr=$(git symbolic-ref HEAD | awk -F/ '{print $3}')  # $(git st | head -n1 | awk '{print $3}')
    [[ $from_br != $curr ]] && { echo "current workspace branch $curr does not match from-branch $from_br"; return; }
    for br in "$to_brs"; do
        git stash && git co $br && git cp $sha && git co $curr && git stash pop; [[ $? -ne 0 ]] && return $?;
    done
}

# requires gh cli of github. https://cli.github.com/manual/
# Ref: https://gist.github.com/caniszczyk/3856584
function github_clone_org()
{
    [[ $# -ne 1 ]] && { echo "usage: $FUNCNAME <github-org-name>"; exit -1; }
    mkdir $1 && cd $1; [[ $? -ne 0 ]] && { echo "mkdir $1 failed w/ rc $?"; return -1; }
    gh repo list $1 --limit 9999 --json sshUrl | jq '.[]|.sshUrl' | xargs -n1 > list;
    local r;
    for r in $(cat list); do
        git clone $r; [[ $? -ne 0 ]] && { echo "Failed to clone $r"; exit 1; }
    done
}

function usage()
{
    echo "usage: git.sh <path> <old-file> <old-hex> <old-mode> <new-file> <new-hex> <new-mode>"
    echo "Usual set of arguments provided by git while invoking external diff program"
    echo "OR"
    echo "usage: git.sh [-h|-a]"
    echo "  -a <ssh-priv-key>       - add ssh private key to agent. ex: ~/.ssh/id_rsa"
    echo "  -b <branch>             - pull branch of given name"
    echo "  -c <kv-conf-path>       - use given key-val file to config local repo"
    echo "  -d <diff-name>          - use given diff-name generate diff file-name"
    echo "  -f <diff-file-path>     - do not generate file-name, use provided name"
    echo "  -g <github-org-name>    - clone all repos of given organization from github"
    echo "  -l [ws-name]            - clone repo from GIT_REPO url with opts"
    echo "  -p                      - pull & track all branches in remote repo"
    echo "  -r <remote-name> <url>  - move git repo to different hosting"
    echo "  -t                      - track all branches in remote repo"
    echo "  -h                      - print this help message"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    local DIFF=$(which diff 2>/dev/null);
    [[ $# -eq 7 ]] && { [[ ! -z $DIFF ]] && $DIFF "$2" "$5"; exit 0; }  # echo $*

    PARSE_OPTS="ha:b:c:d:f:g:lpr:tu:"
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
    ((opt_b)) && { BRANCH=" -b $optarg_b"; } || { unset BRANCH; }
    ((opt_f)) && { DIFF_NM=$optarg_f; } || { unset DIFF_NM; }
    ((opt_g)) && { github_clone_org $optarg_g; exit 0; }
    ((opt_l)) && { git_clone $*; exit 0; }
    ((opt_d)) && { git_diff $optarg_d; return; }
    [[ ! -d .git ]] && { echo "Unknown git repo, .git not found"; return; }
    ((opt_c)) && { config_local_repo $optarg_c; }
    ((opt_r)) && { new_remote $optarg_r $*; }
    ((opt_p)) && { git_pull_all $*; }
    ((opt_t)) && { track_branch_all $*; }
    ((opt_u)) && { git_pull_update $optarg_u; }
    ((opt_h)) && { usage; }

    exit 0;
}

if [ "$(basename -- $0)" == "$(basename git.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4
