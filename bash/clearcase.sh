#!/usr/bin/env bash
#  DETAILS: Clearcase Utlities
#  CREATED: 06/25/13 11:27:14 IST
# MODIFIED: 09/05/14 21:46:25 IST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

# Warn unset vars as error, Verbose (echo each command), Enable debug mode
#set -uvx

function ctmkbranch()
{
    args=$#
    if [ $args = "0" ]; then
        echo "usage: $0 <zilla>"
        echo "It will generate config spec for zilla branch. At the same time, it will create branch type in /vobs/fm40"
    else
        ZILLA=$1
        BRANCH="$USER-zilla-$ZILLA"
        OLDPATH=`pwd`
        echo "Creating branch type $BRANCH..."
        cd-bond

        cleartool mkbrtype -nc $BRANCH
        echo ""
        echo "##########################################"
        echo "# Config spec for zilla $ZILLA"
        echo "##########################################"
        echo "element * CHECKEDOUT"
        echo "element * .../$BRANCH/LATEST"
        echo ""
        cd $OLDPATH
    fi
}

function ctmklabel()
{
    args=$#
    if [ $args = "0" ]; then
        echo "usage: mklabel <labelname>"
    else
        ct mklabel -recurse -replace $1 $PWD
    fi
}

function ctmkview()
{
    args=$#
    if [ $args = "0" ]; then
        echo "usage: mkview <viewname>"
    else
        ct mkview -tag $1 -stgloc -auto
    fi
}

function ctfindbrversion()
{
    args=$#
    if [ $args = "0" ]; then
        echo "usage: findver <branch-name>"
    else
        ct find . -type f -version 'version('$1')' -print
#       ct find . -type f -version 'version('$1')' -print | awk -F @@ '{print $1}'
    fi
}

function ctfindlbversion()
{
    args=$#
    if [ $args = "0" ]; then
        echo "usage: findver <branch-name>"
    else
        ct find . -type f -version 'lbtype('$1')' -print
    fi
}

function ccgitsync()
{
    args=$#
    if [ $args = "0" ]; then
        echo "usage: ccgitsync <branch-name>"
    else
    # pristine clearcase directory to sync to git directory
        SRCDIR=/viewstore/rkks/cc/$1
        DSTDIR=/viewstore/rkks/git

    # this contains a wildcard pattern per line of files to exclude
        EXCLUDES=$CUSTOM_CONFS/.gitexclude

    # now the actual transfer
        OPTS="-rvt --progress --delete --exclude-from=$EXCLUDES"
        rsync $OPTS $SRCDIR $DSTDIR
    fi

# BSERVER=localhost                 # the name of the backup machine
# export RSYNC_PASSWORD=XXXXXX  # your password on the backup server
# rsync $OPTS $BDIR $BSERVER::$USER/current
}

function ccgitsyncdry()
{
    args=$#
    if [ $args = "0" ]; then
        echo "usage: ccgitsyncdry <branch-name>"
    else
    # pristine clearcase directory to git directory sync
        SRCDIR=/viewstore/rkks/cc/$1
        DSTDIR=/viewstore/rkks/git

    # this contains a wildcard pattern per line of files to exclude
        EXCLUDES=$CUSTOM_CONFS/.gitexclude

    # now the actual transfer
        OPTS="-rvtn --progress --delete --exclude-from=$EXCLUDES"
        rsync $OPTS $SRCDIR $DSTDIR
    fi
}

usage()
{
    echo "usage: clearcase.sh []"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    if [ "$#" == "0" ]; then
        usage
        exit 1
    fi

    case $1 in
        *)
            usage
            ;;
    esac
    exit 0
}

if [ "$(basename $0)" == "$(basename clearcase.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4

