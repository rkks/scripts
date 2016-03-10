#!/usr/bin/env bash
#  DETAILS: SVN related actions
#  CREATED: 11/07/12 12:54:25 IST
# MODIFIED: 10/06/14 14:21:35 IST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2012, Ravikiran K.S.

#set -uvx               # Treat unset variables as an error, verbose, debug mode

# Source .bashrc.dev only if invoked as a sub-shell.
if [[ "$(basename svn.sh)" == "$(basename -- $0)" ]] && [ -f $HOME/.bashrc.dev ]; then
    source $HOME/.bashrc.dev
    # define new ENV only if necessary.
fi

LOGFILE=svn.log

function nvsvndiff()
{
    args=$#
    if [ $args == "0" ]; then
        echo "usage: svndiff <pr-number> <file-names>"
    else
        pr=$1
        shift
        svn diff -x -NHcp $* > pr-$pr-c.diff
        svn diff -x -NHup $* > pr-$pr-u.diff
        mv $zilla-c.diff $pr-u.diff ~/commit-logs/patches/
        echo "PR: $pr"
        echo "Tested: SS-ROD, Build jinstall. Verify basic sanity."
        echo "Description:"
        echo "Patch Files:"
        echo "$HOME/commit-logs/patches/$pr-c.diff"
        echo "$HOME/commit-logs/patches/$pr-u.diff"
    fi
}

function svn-cat()
{
    [[ "$#" != "2" ]] && (usage; exit $EINVAL)

    #rev="--revision $1"
    local rev=$1; local file=$2; local output="$(basename $file)_$rev";
    svn cat https://bng-svn.juniper.net/svn/junos-2009/branches/$rev/$file > $output 2>/dev/null
}

function svn-diff-graphical()
{
    # Useless stuff. Diffing single file is not needed
    local dif="gvimdiff -R"; local file=$2; local prev=${file}_PREV;
    trap "rm -f $prev" 2 3 15; # Trap bash command signals: SIGINT = 2,  SIGQUIT = 3, SIGTERM = 15
    svn cat $rev $file > $prev 2>/dev/null; $dif $prev $file
    sleep 3; rm -f $prev   # Allow non-blocking apps like gvimdiff to read file before it is deleted.
}

# Extra flags like --revision <rev1:rev2> can be provided as args like:
# $ svn.sh <out-file> <svn-extra-args> <svn-files>
function svn-diff()
{
    [[ $# -lt 2 ]] && { usage; exit $EINVAL; } || { local file=$1; shift; local cdate=$(date +%d%b%Y); }

    svn diff --diff-cmd /usr/bin/diff -x "-Napur" $* > $file-$cdate-u.diff    # -Napcr - context diff
}

# Outputs the full history of a given file as a sequence of
# logentry/diff pairs.  The first revision of the file is emitted as
# full text since there's not previous version to compare it to.
function svn-history()
{
    [[ $# -ne 1 ]] && (usage; exit $EINVAL)

    # file url
    local url=$1
    svn log -q $url | grep -E -e "^r[[:digit:]]+" -o | cut -c2- | sort -n | {
        # first revision as full text
        echo
        read r
        svn log -r$r $url@HEAD
        svn cat -r$r $url@HEAD
        echo

        # remaining revisions as differences to previous revision
        while read r
        do
            echo
            svn log -r$r $url@HEAD
            svn diff -c$r $url@HEAD
            echo
        done
    }
}

function svn-update()
{
    [[ $# -ne 1 ]] && { usage; exit $EINVAL; }
    [[ ! -e $1 ]] && { echo "Path: $1 doesnt exist."; exit $ENOENT; }

    local svnpath=$1;
    pause "Updating SVN: $svnpath"
    [[ -d $svnpath ]] && { cdie $svnpath; } || { cdie $(dirname $svnpath); }
    [[ ! -d .svn ]] && die $ENOENT "ERROR: You are not working in an SVN directory"

    LOGFILE=svn.log; truncate_file $LOGFILE;
    if [ -d $svnpath ]; then
       run svn update 2>&1 1>>$LOGFILE | tee -a $LOGFILE
    elif [ -f $svnpath ]; then
       run svn update $svnpath 2>&1 1>>$LOGFILE | tee -a $LOGFILE
    else
       echo "Unable to identify svn workspace"; return 1;
    fi
    if [ $? != 0 ]; then
        echo "svn-update failed"; return 1;
    fi
}

function svn-status()
{
    [[ $# -ne 1 ]] && { usage; exit $EINVAL; }

    local svnpath=$1;
    pause "Modifications in SVN: $svnpath"
    [[ -d $svnpath ]] && { cdie $svnpath; } || { cdie $(dirname $svnpath); }
    [[ ! -d .svn ]] && die $ENOENT "ERROR: You are not working in an SVN directory"

    LOGFILE=status.log; truncate_file $LOGFILE
    run svn status 2>&1 1>>$LOGFILE | tee -a $LOGFILE
    if [ $? != 0 ]; then
        echo "svn-status failed"; return 1;
    fi
}

function svn-backup()
{
    cdie $1
    [[ ! -d ~/work/backup ]] && mkdir -p ~/work/backup/
    svn diff > ~/work/backup/$(echo $PWD | sed 's/\//\_/g')-$(date "+%d%b%Y").diff
}

function svn-report()
{
    [[ ! -f $1 ]] && { echo "File: $1 doesn't exist"; return; }
    [[ -f $2 ]] && { echo "File: $2 already exists"; return; } || { cat /dev/null > $2; }
    printf "Modified:\n---------\n" >> $2;
    cat $1 | grep "^M " | awk '{print $2}' >> $2
    printf "\nConflicts:\n----------\n" >> $2;
    cat $1 | grep "^C " | awk '{print $2}' >> $2
    printf "\nUnknown:\n--------\n" >> $2;
    cat $1 | grep "^\? " | awk '{print $2}' >> $2
}

usage()
{
    echo "usage: svn.sh <-c <revision> <file>|-d <revision> <file>|-i <file>|-s <path>|-u <path>>";
    echo "Options:"
    echo "  -a - kick-off nightly processing of svn workspaces (-us)"
    echo "  -c <revision> <file>- list/cat given file for provided revision"
    echo "  -d <out> <files>    - output diff of given file(s) to <out>-c/u.diff"
    echo "  -i <file>           - provide history of given file"
    echo "  -r <ifile> <ofile>  - given status/svn log, outputs modification report"
    echo "  -s <path>           - provide status for given workspace"
    echo "  -u <path>           - update given workspace to latest revision"
    echo "  -h                  - print this help message"
    echo "Note: below is list of svn diff results for some revision values"
    echo "  HEAD        - Diff with latest in repository"
    echo "  BASE        - Diff with what you had checked out"
    echo "  COMMITTED   - Diff with the version before BASE"
    echo "  PREV        - Diff with the version before COMMITTED"
}

main()
{
    PARSE_OPTS="hb:c:d:i:r:s:u:"
    local opts_found=0
    while getopts ":$PARSE_OPTS" opt; do
        case $opt in
            [a-zA-Z0-9])
                decho DEBUG "-$opt was triggered, Parameter: $OPTARG"
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

    ((opt_b)) && svn-backup $optarg_b
    ((opt_c)) && svn-cat $optarg_c $*
    ((opt_d)) && svn-diff $optarg_d $*
    ((opt_i)) && svn-history $optarg_i
    ((opt_r)) && svn-report $optarg_r $*
    ((opt_s)) && svn-status $optarg_s
    ((opt_u)) && svn-update $optarg_u
    ((opt_h)) && (usage; exit 0)

    exit 0
}

if [ "$(basename -- $0)" == "$(basename svn.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4

