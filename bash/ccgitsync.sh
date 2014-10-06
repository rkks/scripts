#!/usr/bin/env bash
#===============================================================================
#
#          FILE:  ccgitsync
#
#         USAGE:  ./ccgitsync
#
#   DESCRIPTION:  A script to sync clearcase snapshot and a git repository.
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Ravikiran K.S. (rkks), mr.rkks@gmail.com
#       COMPANY:
#       VERSION:  1.0
#       CREATED:  05/13/09 11:21:10 IST
#===============================================================================

# pristine clearcase directory to sync to git directory
SRCDIR=/viewstore/rkks/cc/$1
DSTDIR=/viewstore/rkks/git/$1

# excludes file - this contains a wildcard pattern per line of files to exclude
EXCLUDES=$HOME/scripts/exclude

# the name of the backup machine
# BSERVER=localhost

# your password on the backup server
# export RSYNC_PASSWORD=XXXXXX

########################################################################

#OPTS="--force --ignore-errors --delete-excluded --exclude-from=$EXCLUDES
#      --delete --backup --backup-dir=$DSTDIR -a"
OPTS="-rvt --progress --delete --exclude-from=$EXCLUDES"
DRYRUN="-n"

# now the actual transfer
# rsync $OPTS $BDIR $BSERVER::$USER/current
rsync $OPTS $SRCDIR $DSTDIR
