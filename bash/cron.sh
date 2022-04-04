#!/usr/bin/env bash
#  DETAILS: Runs the required scripts and jobs every time invoked.
#
#   AUTHOR: Ravikiran K.S. (ravikirandotks@gmail.com)
#  CREATED: 11/08/11 13:35:02 PST
# MODIFIED: 04/Apr/2022 18:00:47 IST

# Cron has defaults below. Redefining to suite yours(if & only if necessary).
# HOME=user-home-directory  # LOGNAME=user.s-login-id
# PATH=/usr/bin:/usr/sbin:. # BASH=/usr/bin/env bash    # USER=$LOGNAME

#set -uvx       # Treat unset variables as an error, verbose, debug mode

# Source .bashrc.dev only if invoked as a sub-shell. Not if sourced.
[[ "cron.sh" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

DIFF_LOG=diff.log;

function local_backup()
{
    [[ $# -ne 1 ]] && { echo "Usage: $FUNCNAME <dir-name>"; return $EINVAL; }
    log INFO "Backing up: $1";
    shell backup.sh "$1";
}

function backup()
{
    local fname=$FUNCNAME;
    [[ ! -z "$(grep -w $fname $CUST_CONFS/cronskip)" ]] && { echo "$0: Skip $FUNCNAME"; return; }
    [[ $# -ne 1 ]] && { echo "Usage: $FUNCNAME <dir-list>"; return $EINVAL; }
    log INFO "Backing up directories list in file $1"
    # Git Backup: Preferred way to sync text stuff
    batch_func local_backup $1
}

function sync()
{
    local fname=$FUNCNAME;
    [[ ! -z "$(grep -w $fname $CUST_CONFS/cronskip)" ]] && { echo "$0: Skip $FUNCNAME"; return; }
    [[ $# -ne 0 ]] && { local RSYNC_LST=$1; } || { local RSYNC_LST=$CUST_CONFS/rsync.lst; }
    log INFO "Syncing directory list from $1";
    # Manual Sync: What can not be synced using revision-control.
    shell rsync.sh -l $RSYNC_LST $HOME eng-shell1:
}

# IMP: Do not comment out any run_on here, instead update $CUST_CONFS/cronskip
function nightly()
{
    log CRIT "Running cron for $(/bin/date +'%a %b/%d/%Y %T%p %Z')";

    [[ ! -z "$(grep -w cron $CUST_CONFS/cronskip)" ]] && return;  # skip if configured so

    # SCM should not update repo if there is a working change in repo
    func_on Now backup $CUST_CONFS/backup;
    func_on Now revision $CUST_CONFS/workspaces;
    func_on Now database $CUST_CONFS/workspaces;
    func_on Now build $CUST_CONFS/workspaces;
    func_on Fri reserve $COMPANY_CONFS/reserve;
    func_on Fri sync;
    func_on Now download;
    func_on Now report;
}

function git_revision_update()
{
    [[ $# -eq 0 ]] && { echo "Usage: $FUNCNAME <dir-path>"; return $EINVAL; }
    [[ ! -d $1 ]] && { echo "$FUNCNAME: no repo $1 exists"; return $ENOENT; }
    cdie $1 && shell git.sh -d nightly -f $DIFF_LOG;
    [[ ! -f $DIFF_LOG ]] && { echo "$FUNCNAME: git diff failed"; return $ENOENT; }
    local chgs=$(cat $DIFF_LOG | wc -l);
    [[ $chgs -ne 0 ]] && { log INFO "Changes found, skip update"; return 0; }
    log DEBUG "No changes found in $DIFF_LOG. Update repo.";
    shell git.sh -u $1;
}

function revision()
{
    local fname=$FUNCNAME;
    [[ ! -z "$(grep -w $fname $CUST_CONFS/cronskip)" ]] && { echo "$0: Skip $FUNCNAME"; return; }
    [[ $# -ne 1 ]] && { echo "Usage: $FUNCNAME <list-file>"; return $EINVAL; }
    log INFO "$FUNCNAME: Update revision of workspaces list in file $1"
    batch_func git_revision_update $1
}

function database_update()
{
    [[ $# -ne 1 ]] && { echo "Usage: $FUNCNAME <dir-path>"; return $EINVAL; }
    shell cscope_cgtags.sh -c $1;
}

function database()
{
    local fname=$FUNCNAME;
    [[ ! -z "$(grep -w $fname $CUST_CONFS/cronskip)" ]] && { echo "$0: Skip $FUNCNAME"; return; }
    [[ $# -ne 1 ]] && { echo "Usage: $FUNCNAME <list-file>"; return $EINVAL; }
    log INFO "Build cscope/ctags db for workspaces list in file $1"
    batch_func database_update $1
}

function build_target()
{
    [[ $# -eq 0 ]] && { echo "Usage: $FUNCNAME <dir-path>"; return $EINVAL; }
    [[ ! -d $1 ]] && { echo "$FUNCNAME: no repo $1 exists"; return $ENOENT; }
    cdie $1;
    [[ ! -f $DIFF_LOG ]] && { echo "No $DIFF_LOG found at $PWD"; return $ENOENT; }
    local chgs=$(cat $DIFF_LOG | wc -l);
    [[ $chgs -eq 0 ]] && shell vbuild.sh -d waf -f;
}

function build()
{
    local fname=$FUNCNAME;
    [[ ! -z "$(grep -w $fname $CUST_CONFS/cronskip)" ]] && { echo "$0: Skip $FUNCNAME"; return; }
    [[ $# -ne 1 ]] && { echo "Usage: $FUNCNAME <list-file>"; return $EINVAL; }
    log INFO "Build code for workspaces list in file $1"
    batch_func build_target $1
}

function download()
{
    local fname=$FUNCNAME;
    [[ ! -z "$(grep -w $fname $CUST_CONFS/cronskip)" ]] && { echo "$0: Skip $FUNCNAME"; return; }
    local linkfile=$CUST_CONFS/downlinks;
    [[ ! -f $linkfile ]] && { echo "$linkfile not found. No pending downloads"; return; }
    [[ ! -d $DOWNLOADS ]] && { run mkdir -p $DOWNLOADS; }
    log INFO "Start pending downloads"
    run cdie $DOWNLOADS
    while read line
    do
        log INFO "Download $line"
        run wget -c -o wget-$(basename $line).log -t 3 -b $line;
        if [ "$?" != "0" ]; then
            log ERROR "Error downloading $line"
        fi
    done<$linkfile

    log INFO "Clean download list"
    cat /dev/null > $linkfile;

    return 0;
}

function report()
{
    [[ $# -ne 1 ]] && { echo "Usage: $FUNCNAME <list-file>"; return $EINVAL; }
    log INFO "Sending Cron job report"
    shell mail.sh -c $SCRPT_LOGS/cron.sh.log;
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

# openfortivpn has auto-reconnect option on disconnect, no need of cron job
function usage()
{
    echo "Usage: cron.sh <-b <backup-path>|-c <scm-workspace>|-d <build-path>|-l|-n|-r <reserve-file>|-s <crontab-file>|-t>"
    echo "Options:"
    echo "  -b <dir-list>       - backup modified files in given list of dirs"
    echo "  -c <repo-list>      - update source code in dirs in given file"
    echo "  -d <repo-list>      - build source code in given location"
    echo "  -e <repo-list>      - create cscope/tags DB in given location"
    echo "  -l                  - list crontab configured for user"
    echo "  -m <email-id>       - email-id to which sends report"
    echo "  -n                  - kick-off nightly cron job (-bcdr)"
    echo "  -r <device-list>    - reserve routers listed in given file"
    echo "  -s <crontab-file>   - start user cronjob with given crontab file"
    echo "  -t                  - stop the cronjob for user"
    echo "  -z                  - test the environment variables"
    echo "  -h                  - print this help message"
}

function main()
{
    local PARSE_OPTS="ha:b:c:d:e:lnr:s:tz"
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

    #export SHDEBUG=yes;
    ((opt_m)) && { NOTIFY_EMAIL="$optarg_m"; }
    ((opt_a)) && { RUN_LOG="run.log"; truncate --size 0 $RUN_LOG; batch_run $optarg_a; }
    ((opt_b)) && { backup $optarg_b; }
    ((opt_c)) && { revision $optarg_c; }
    ((opt_d)) && { build $optarg_d; }
    ((opt_e)) && { database $optarg_e; }
    ((opt_l)) && { crontab -l; }
    ((opt_n)) && { nightly; }
    ((opt_r)) && { reserve $optarg_r; }
    ((opt_s)) && { crontab $optarg_s; }
    ((opt_t)) && { crontab -r; }
    ((opt_z)) && { page_brkr 40 -; set; alias; page_brkr 40 -; }
    ((opt_h)) && { usage; exit 0; }

    exit 0
}

# $0 is to account for the "-bash" type of strings in login_shell.
# login shell if [[ "$(shopt login_shell | cut -f 2)" == "off" ]]
if [ "$(basename -- $0)" == "cron.sh" ]; then
    main $*
fi
# VIM: ts=4:sw=4
