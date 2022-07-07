#!/usr/bin/env bash
#  DETAILS: Runs the required scripts and jobs every time invoked.
#
#   AUTHOR: Ravikiran K.S. (ravikirandotks@gmail.com)
#  CREATED: 11/08/11 13:35:02 PST
# MODIFIED: 07/07/2022 12:25:12 PM IST

# Cron has defaults below. Redefining to suite yours(if & only if necessary).
# HOME=user-home-directory  # LOGNAME=user.s-login-id
# PATH=/usr/bin:/usr/sbin:. # BASH=/usr/bin/env bash    # USER=$LOGNAME

#set -uvx       # Treat unset variables as an error, verbose, debug mode

# Source .bashrc.dev only if invoked as a sub-shell. Not if sourced.
[[ "cron.sh" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

DIFF_LOG="$(date +%d%m%Y)-nightly-$(id -nu)-u.diff";

function backup_update()
{
    [[ $# -ne 1 ]] && { echo "Usage: $FUNCNAME <dir-name>"; return $EINVAL; }
    cdie $1 && chk_revision_chgs
    [[ $? -eq 0 ]] && { log_note "No changes found, skip backup"; return 0; }
    log_note "Backing up: $1";
    shell backup.sh -v "$1/$DIFF_LOG" "$1";  # without -v is waste of space for repos
}

function backup()
{
    local fname="$FUNCNAME";    # skip backup altogether
    [[ $# -ne 1 ]] && { echo "Usage: $FUNCNAME <dir-list>"; return $EINVAL; }
    log_note "Backing up directories list in file $1"
    # Git Backup: Preferred way to sync text stuff
    cron_batch_func backup_update $1
}

function sync()
{
    local fname="$FUNCNAME";    # skip sync altogether
    [[ $# -ne 0 ]] && { local RSYNC_LST=$1; } || { local RSYNC_LST=$CUST_CONFS/rsync.lst; }
    log_note "Syncing directory list from $1";
    # Manual Sync: What can not be synced using revision-control.
    shell rsync.sh -l $RSYNC_LST $HOME eng-shell1:
}

# IMP: Do not comment out any run_on here, instead update $HOME/.cronskip
function nightly()
{
    log CRIT "Running cron for $(/bin/date +'%a %b/%d/%Y %T%p %Z')";

    [[ ! -z "$(grep -w cron $HOME/.cronskip)" ]] && return;  # skip cron altogether

    # SCM should not update repo if there is a working change in repo
    cron_func_on Now revision $HOME/.repos;
    cron_func_on Now database $HOME/.repos;
    cron_func_on Now build $HOME/.repos;
    cron_func_on Now backup $HOME/.repos;
    cron_func_on Fri reserve $COMPANY_CONFS/reserve;
    cron_func_on Fri sync;
    cron_func_on Now download;
    cron_func_on Now report;
    cron_func_on Now cleanup $HOME/.repos;
}

function chk_revision_chgs()
{
    #Usage: $FUNCNAME [generate]
    [[ "$@" == "generate" ]] && { shell git.sh -d nightly -f $DIFF_LOG; }
    [[ ! -f $DIFF_LOG ]] && { return 0; } || { local chgs=$(cat $DIFF_LOG | wc -l); }
    [[ $chgs -eq 0 ]] && { rm -f $DIFF_LOG && return 0; } || return $EEXIST;
}

function revision_update()
{
    [[ $# -eq 0 ]] && { echo "Usage: $FUNCNAME <dir-path>"; return $EINVAL; }
    cdie $1 && chk_revision_chgs generate;
    [[ $? -ne 0 ]] && { log_note "Changes found, skip update"; return 0; }
    log DEBUG "No changes found in $DIFF_LOG. Update repo.";
    shell git.sh -u $1;
}

function revision()
{
    local fname="$FUNCNAME";    # skip revision altogether
    [[ $# -ne 1 ]] && { echo "Usage: $FUNCNAME <list-file>"; return $EINVAL; }
    log_note "$FUNCNAME: Update revision of repos list in file $1"
    cron_batch_func revision_update $1
}

function database_update()
{
    [[ $# -ne 1 ]] && { echo "Usage: $FUNCNAME <dir-path>"; return $EINVAL; }
    shell cscope_cgtags.sh -d $1;   # -e -u
}

function database()
{
    local fname="$FUNCNAME";    # skip database altogether
    [[ $# -ne 1 ]] && { echo "Usage: $FUNCNAME <list-file>"; return $EINVAL; }
    log_note "Build cscope/ctags db for repos list in file $1"
    cron_batch_func database_update $1
}

function build_update()
{
    [[ $# -eq 0 ]] && { echo "Usage: $FUNCNAME <dir-path>"; return $EINVAL; }
    cdie $1 && chk_revision_chgs;
    [[ $? -ne 0 ]] && { log_note "Changes found, skip build"; return 0; }
    log DEBUG "No changes found in $DIFF_LOG. Build repo.";
    shell vbuild.sh -d waf -f;
}

function build()
{
    local fname="$FUNCNAME";    # skip build altogether
    [[ $# -ne 1 ]] && { echo "Usage: $FUNCNAME <list-file>"; return $EINVAL; }
    log_note "Build code for repos list in file $1"
    cron_batch_func build_update $1
}

function download()
{
    local fname="$FUNCNAME";    # skip download altogether
    local linkfile=$CUST_CONFS/downlinks;
    [[ ! -f $linkfile ]] && { log_dbg "$linkfile not found. No pending downloads"; return; }
    [[ ! -d $DOWNLOADS ]] && { run mkdir -p $DOWNLOADS; }
    log_note "Start pending downloads"
    run cdie $DOWNLOADS
    while read line
    do
        log_note "Download $line"
        run wget -c -o wget-$(basename $line).log -t 3 -b $line;
        if [ "$?" != "0" ]; then
            log ERROR "Error downloading $line"
        fi
    done<$linkfile

    log_note "Clean download list"
    cat /dev/null > $linkfile;

    return 0;
}

function report()
{
    [[ $# -ne 1 ]] && { echo "Usage: $FUNCNAME <list-file>"; return $EINVAL; }
    log_note "Sending Cron job report"
    shell mail.sh -c $SCRPT_LOGS/cron.sh.log;
}

function reserve()
{
    [[ $# -eq 0 ]] && { echo "Usage: reserve <path-to-reserve-file>"; return $EINVAL; }
    [[ ! -f $1 ]] && { log_note "File $1 not found. Skipping router reservation"; return $ENOENT; }

    local reserve_file=$1
    # Format in $reserve_file is: router duration start-time repeat
    while read router duration start repeat; do
        [[ "$router" == \#* ]] && { continue; }
        [[ -z $start ]] && { local start = "09:00"; }
        [[ -z $duration ]] && { local duration = "4h"; }
        log_note "Reserving Router $router";    # res sh $router;
        run res co -c "Testing" -P "scripting" -s "$(date -v+3d +"%Y-%m-%d") $start" -d $duration -r $repeat $router
    done < $reserve_file
}

function cleanup_update()
{
    [[ $# -eq 0 ]] && { echo "Usage: $FUNCNAME <dir-path>"; return $EINVAL; }
    cdie $1 && rm -f $DIFF_LOG;
    #[[ $? -ne 0 ]] && { log DEBUG "Cleanup fail at $1 ($DIFF_LOG)"; return $EINVAL; }
    log_note "Clean up successful at $1"; return 0;
}

function cleanup()
{
    local fname="$FUNCNAME";    # skip cleanup altogether
    [[ $# -ne 1 ]] && { echo "Usage: $FUNCNAME <list-file>"; return $EINVAL; }
    log_note "$FUNCNAME: Cleanup of repos list in file $1"
    cron_batch_func cleanup_update $1
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
    echo "  -n                  - kick-off nightly cron job (-bcder)"
    echo "  -r <device-list>    - reserve routers listed in given file"
    echo "  -s <crontab-file>   - start user cronjob with given crontab file"
    echo "  -t                  - stop the cronjob for user"
    echo "  -z                  - test the environment variables"
    echo "  -h                  - print this help message"
}

function main()
{
    local PARSE_OPTS="hb:c:d:e:lnr:s:tz"
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
    ((opt_m)) && { MAILTO="$optarg_m"; }
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
