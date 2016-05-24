#!/usr/bin/env bash
#  DETAILS: Runs the required scripts and jobs every time invoked.
#
#   AUTHOR: Ravikiran K.S. (ravikirandotks@gmail.com)
#  CREATED: 11/08/11 13:35:02 PST
# MODIFIED: 05/11/16 04:18:37 PDT

# Cron has defaults below. Redefining to suite yours(if & only if necessary).
# HOME=user-home-directory  # LOGNAME=user.s-login-id
# PATH=/usr/bin:/usr/sbin:. # BASH=/usr/bin/env bash    # USER=$LOGNAME

#set -uvx       # Treat unset variables as an error, verbose, debug mode

# Source .bashrc.dev only if invoked as a sub-shell. Not if sourced.
[[ "$(basename cron.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

# Provide callback function to be called for each item in list
function run_forall_in_file()
{
    [[ $# -eq 0 ]] && { echo "Usage: $FUNCNAME <list-file>"; return $EINVAL; }
    local fname=$1; shift; local dir_list=$2; shift; local rval=0;
    while read dir; do
        [[ "$dir" == \#* || ! -d $dir ]] && { continue; } || { local conflicts=0; cdie $dir; }
        log INFO "$fname $dir"
        run "$fname $dir"; [[ $? -ne 0 ]] && { rval=1; }      # reflects if any of runs failed
    done < $dir_list
    return rval;
}

function local_backup()
{
    [[ $# -eq 0 ]] && { echo "Usage: backup <dir-name>"; return $EINVAL; }
    log INFO "Backing up: $1";
    shell backup.sh "$1";
}

function backup()
{
    [[ ! -z "$(grep -w $FUNCNAME $CUST_CONFS/cronskip)" ]] && { echo "$0: Skip $FUNCNAME"; return; }
    log INFO "Backing up directories list in file $1"
    # Git Backup: Preferred way to sync text stuff
    run_forall_in_file local_backup $1
}

function sync()
{
    [[ ! -z "$(grep -w $FUNCNAME $CUST_CONFS/cronskip)" ]] && { echo "$0: Skip $FUNCNAME"; return; }
    log INFO "Syncing directory list from $1";
    # Manual Sync: What can't be synced using revision control.
    shell rsync.sh -l $CUST_CONFS/rsync.lst $HOME eng-shell1:
}

function nightly()
{
    log CRIT "Running cron for $(/bin/date +'%a %b/%d/%Y %T%p %Z')";

    [[ ! -z "$(grep -w cron $CUST_CONFS/cronskip)" ]] && return;  # skip if configured so

    # take backup before SCM changes the contents
    run_on Now backup $CUST_CONFS/backup;
    run_on Now revision $COMPANY_CONFS/workspaces;
    run_on Now database $COMPANY_CONFS/workspaces;
    run_on Now build $COMPANY_CONFS/workspaces;
    run_on Fri reserve $COMPANY_CONFS/reserve;
    run_on Fri sync;
    run_on Now download;
    run_on Now report;
}

function svn_revision_update()
{
    [[ $# -eq 0 ]] && { echo "Usage: svn_revision <dir-path>"; return $EINVAL; }
    local SVNLOG=svn.log; local STATUS=status.log; local dir=$1;
    shell svn.sh -b $dir; shell svn.sh -s $dir; shell svn.sh -r $STATUS changes.log;
}

function no_revision_conflicts()
{
    [[ -f $SVNLOG ]] && { conflicts=$(cat $SVNLOG | grep "^\? "| cut -d " " -f 2 | wc -l | tr -d ' '); }
    [[ $conflicts -eq 0 ]] && { log INFO "No conflicts found"; return 0; }
    log ERROR "Conflicts found in $SVNLOG. Resolve & retry."; return 1;
}

function revision()
{
    [[ ! -z "$(grep -w $FUNCNAME $CUST_CONFS/cronskip)" ]] && { echo "$0: Skip $FUNCNAME"; return; }
    log INFO "$FUNCNAME: Update revision of workspaces list in file $1"
    run_forall_in_file svn_revision_update $1
}

function database_update()
{
    shell cscope_cgtags.sh -c $1;
}

function database()
{
    [[ ! -z "$(grep -w $FUNCNAME $CUST_CONFS/cronskip)" ]] && { echo "$0: Skip $FUNCNAME"; return; }
    log INFO "Build cscope/ctags db for workspaces list in file $1"
    run_forall_in_file database_update $1
}

function build_target()
{
    no_revision_conflicts && cdie $1/build && shell cbuild.sh -9 all;
}

function build()
{
    [[ ! -z "$(grep -w $FUNCNAME $CUST_CONFS/cronskip)" ]] && { echo "$0: Skip $FUNCNAME"; return; }
    log INFO "Build code for workspaces list in file $1"
    run_forall_in_file build_target $1
}

function download()
{
    [[ ! -z "$(grep -w $FUNCNAME $CUST_CONFS/cronskip)" ]] && { echo "$0: Skip $FUNCNAME"; return; }
    log INFO "Start pending downloads"
    shell download.sh $CUST_CONFS/downlinks;
}

function report()
{
    log INFO "Sending Cron job report"
    shell mail.sh -c;
}

function reserve()
{
    [[ $# -eq 0 ]] && { echo "Usage: reserve <path-to-reserve-file>"; return $EINVAL; }
    [[ ! -f $1 ]] && { log INFO "File $1 not found. Skipping router reservation"; return $ENOENT; }

    [[ ! -z "$(grep -w reserve $CUST_CONFS/cronskip)" ]] && return;  # skip if configured so

    local reserve_file=$1
    # Format in $reserve_file is: router duration start-time repeat
    while read router duration start repeat; do
        [[ "$router" == \#* ]] && { continue; }
        [[ -z $start ]] && { local start = "09:00"; }
        [[ -z $duration ]] && { local duration = "4h"; }
        log INFO "Reserving Router $router";    # res sh $router;
        run res co -c "Testing" -P "scripting" -s "$(date -v+3d +"%Y-%m-%d") $start" -d $duration -r $repeat $router
    done < $reserve_file
}

function usage()
{
    echo "Usage: cron.sh <-b <backup-path>|-c <scm-workspace>|-d <build-path>|-l|-n|-r <reserve-file>|-s <crontab-file>|-t>"
    echo "Options:"
    echo "  -b <backup-file>    - backup file with list of dirs to backup"
    echo "  -c <scmupdate-list> - update source code in dirs in given file"
    echo "  -d <build-path>     - build source code in given location"
    echo "  -l                  - list crontab configured for user"
    echo "  -n                  - kick-off nightly cron job (-bcdr)"
    echo "  -r <reserve-file>   - reserve routers listed in given file"
    echo "  -s <crontab-file>   - start user cronjob with given crontab file"
    echo "  -t                  - stop the cronjob for user"
    echo "  -z                  - test the environment variables"
    echo "  -h                  - print this help message"
}

function main()
{
    local PARSE_OPTS="hb:c:d:lnr:s:tz"
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

    export SHDEBUG=yes;
    ((opt_b)) && backup $optarg_b;
    ((opt_c)) && link-confs;
    ((opt_d)) && build $optarg_d;
    ((opt_l)) && crontab -l;
    ((opt_n)) && nightly;
    ((opt_r)) && reserve $optarg_r;
    ((opt_s)) && crontab $optarg_s;
    ((opt_t)) && crontab -r;
    ((opt_z)) && { for i in {1..79}; do echo -n "-"; done; echo "-"; set; alias; }
    ((opt_h)) && { usage; exit 0; }

    exit 0
}

# $0 is to account for the "-bash" type of strings in login_shell.
# login shell if [[ "$(shopt login_shell | cut -f 2)" == "off" ]]
if [ "$(basename -- $0)" == "$(basename cron.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4
