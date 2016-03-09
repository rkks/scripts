#!/usr/bin/env bash
#  DETAILS: Invokes rsyncs with well known better options.
#  CREATED: 06/29/13 16:14:34 IST
# MODIFIED: 03/08/16 23:32:20 PST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

# if rsync gives 'command not found' error, it means that non-interactive bash
# shell on server is unable to find rsync binary. So, use --rsync-path option
# to specify exact location of rsync binary on target server.

#set -uvx           # Warn unset vars as error, Verbose (echo each command), Enable debug mode

# Source .bashrc only if invoked as a sub-shell. Not if sourced.
if [[ "$(basename rsync.sh)" == "$(basename -- $0)" ]] && [ -f $HOME/.bashrc ]; then
    source $HOME/.bashrc
    log_init INFO $SCRPT_LOGS/rsync.log
fi

# contains a wildcard pattern per line of files to exclude. has no entries -- sync everything
RSYNC_EXCLUDE=$CUST_CONFS/rsyncexclude

# common rsync options
# -a - sync all file perms/attributes
# -h - display output in human readable form
# -i - itemize all changes
# -q - not used as -q hides almost every info
# -R - not used as creates confusion. use relative path names
# -u - skip files newer on destination (don't overwrite by fault)
# -v - not used as -v is too verbose
# -W - don't run diff algorithm. algo consumes lot of CPU and unreliable
# -x - don't go outside filesystem boundaries.
# -z - compress data while sync
# -e ssh    - always use ssh for authentication
# --force   - for if some operation requires special privileges
# --delete  - if any file is absent in source, delete it in dest
# --delete-excluded - delete any files that are excluded in RSYNC_EXCLUDE on dest
# --out-format="%i|%n|" - Display itemized changes in this format.
# --safe-links - ignore symlinks that point outside the tree
RSYNC_OPTS="-ahiuWxz -e ssh --stats --force --delete --safe-links --out-format=%i|%n"
RSYNC_OPTS+=" --log-file=$SCRPT_LOGS/rsync.log --exclude-from=$RSYNC_EXCLUDE"
#RSYNC_OPTS+=" --rsync-path=/homes/raviks/tools/bin/freebsd/rsync"

function rsync_dir()
{
    [[ "$#" != "2" ]] && (usage; exit $EINVAL)

    SRC_DIR=$1
    DST_DIR=$2
    [[ "" != "$RSYNC_DRY_RUN" ]] && RSYNC_OPTS+=" -n"
    echo "[SYNC] src: $SRC_DIR dst: $DST_DIR"
    run rsync $RSYNC_OPTS $SRC_DIR $DST_DIR
    unset SRC_DIR DST_DIR
}

function rsync_list()
{
    [[ "$#" != "3" ]] && (usage; exit $EINVAL)

    # Directory paths in $LIST_FILE are included only if specified with a closing slash. Ex. pathx/pathy/pathz/.
    #RSYNC_OPTS+=" --files-from=$LIST_FILE"     # this option not supported on freeBSD
    LIST_FILE=$1; shift;
    # If remote location, dont append /. awk also works: awk '{ print substr( $0, length($0) - 1, length($0) ) }'
    tmpSrc=$(echo $1 | sed 's/^.*\(.\)$/\1/')
    if [ "$tmpSrc" == ":" ] || [ "$tmpSrc" == "/" ]; then SRC="$1"; else SRC="$1/"; fi
    tmpDst=$(echo $2 | sed 's/^.*\(.\)$/\1/')
    if [ "$tmpDst" == ":" ] || [ "$tmpDst" == "/" ]; then DST="$2"; else DST="$2/"; fi

    for dir in $(cat $LIST_FILE); do
        rsync_dir $SRC$dir $DST$dir
    done
    unset LIST_FILE && unset SRC && unset DST && unset tmpSrc && unset tmpDst
}

function rsync_cron()
{
    if [ "$#" != "2" ]; then
        usage
        return
    fi

    # Directory path names must be terminated with a "/" or "/."
    CRON_RSYNC_LIST=$CUST_CONFS/rsync.lst

    rsync_list $CRON_RSYNC_LIST $*
}

usage()
{
    echo "usage: rsync.sh <-c|-d|-l <list-file>|-n> <src-dir> <dst-dir>"
    echo "Options:"
    echo "  -c              - kick-off rsync as part of cron job using pre-defined list"
    echo "  -d              - start recursive rsync between given directory pair"
    echo "  -l <list-file>  - do recursive rsync on all files/directores listed in given file"
    echo "  -n              - enable DRY_RUN during rsync. Gives list of changes to be done"
    echo "Note: In list-file, dir path names must be terminated with a / or /."
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="hcdl:n"
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

    ((opt_n)) && export RSYNC_DRY_RUN=TRUE
    ((opt_c)) && rsync_cron $*
    ((opt_d)) && rsync_dir $*
    ((opt_l)) && rsync_list $optarg_l $*
    ((opt_h)) && (usage; exit 0)

    exit 0
}

if [ "$(basename -- $0)" == "$(basename rsync.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4

