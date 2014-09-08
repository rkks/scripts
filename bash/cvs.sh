#!/usr/bin/env bash
#  DETAILS: CVS related actions
#  CREATED: 11/07/12 12:54:25 IST
# MODIFIED: 09/08/14 10:39:23 IST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2012, Ravikiran K.S.

#set -uvx               # Treat unset variables as an error, verbose, debug mode

# Source .bashrc only if invoked as a sub-shell.
if [[ "$(basename cvs.sh)" == "$(basename -- $0)" ]] && [ -f $HOME/.bashrc ]; then
    source $HOME/.bashrc
    log_init INFO $SCRIPT_LOGS/cvs.log
    # Global defines. (Re)define ENV only if necessary.
fi

function cvsmod()
{
    args=$#
    if [ $args == "0" ]; then
        echo "usage: cvsmod <conf|mod|priv>"
    else
        case $1 in
        'conf')
            #echo "Conflict: $(cat update.scm | grep "^C "| cut -d " " -f 2 | wc -l)";
            cat update.scm | grep "^C "
            ;;
        'mod')
            #echo "Modified: $(cat update.scm | grep "^M "| cut -d " " -f 2 | wc -l)";
            cat update.scm | grep "^M "
            ;;
        'priv')
            #echo "Private: $(cat update.scm | grep "^? "| cut -d " " -f 2 | wc -l)";
            cat update.scm | grep "^? "
            ;;
        *)
            echo "usage: nvcvs <conf|mod|priv>"
            ;;
        esac
    fi
}

function cvsdiff()
{
    args=$#
    if [ $args == "0" ]; then
        echo "usage: cvsdiff <zilla-number> <file-names>"
    else
        zilla=$1
        shift
        cvs diff -Ncp $* > pr-$zilla-c.patch
        cvs diff -Nup $* > pr-$zilla-u.patch
        mv pr-$zilla-c.patch pr-$zilla-u.patch ~/workspace/patches/
        echo "Review Please: PR$zilla"
        echo "AutoPR: $zilla"
        echo "Reviewer: "
        echo "Tested: Precommit, Build cb. Verified basic sanity."
        echo "Description:"
        echo "Patch Files:"
        echo "$HOME/workspace/patches/pr-$zilla-c.patch"
        echo "$HOME/workspace/patches/pr-$zilla-u.patch"
    fi
}

function cvs-update()
{
    args=$#;
    if [ "$args" != "1" ]; then
        usage
    else
        cvspath=$1;
        pause "Updating CVS: $cvspath" || return $?
        cdie $cvspath && cvs update 2>&1 | tee $LOGFILE;
    fi
}

function cvs-daily()
{
    cvs-update $PWD
    ctags --extra=+q --fields=afmikKlnsSz --c++-kinds=+p -a -L cscope.files > /dev/null 2>&1
    cscope -be -i cscope.files -f cscope.out > /dev/null 2>&1
}

usage()
{
    echo "usage: cvs.sh <-a|-d <sfile/sdir> <dfile/ddir>|-h|-u <cvs-workspace>>"
    echo "Options:"
    echo "  -a                          - kick-off daily update of cvs workspace (-u)"
    echo "  -d <sfile/sdir> <dfile/ddir>- run cvs diff on given file/directory paths"
    echo "  -u <cvs-workspace>          - run cvs update on given cvs workspace path"
    echo "  -h                          - print this help message"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="hadu:"
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

    ((opt_a)) && cvs-daily
    ((opt_d)) && cvs-diff $*
    ((opt_u)) && cvs-update $optarg_u
    ((opt_h)) && (usage; exit 0)

    exit 0
}

if [ "$(basename -- $0)" == "$(basename cvs.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4

