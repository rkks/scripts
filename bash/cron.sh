#!/usr/bin/env bash
#  DETAILS: Runs the required scripts and jobs every time invoked.
#
#   AUTHOR: Ravikiran K.S. (ravikirandotks@gmail.com)
#  CREATED: 11/08/11 13:35:02 PST
# MODIFIED: 09/06/14 09:34:24 IST
# REVISION: 1.0

# Cron has defaults below. Redefining to suite yours(if & only if necessary).
# HOME=user-home-directory  # LOGNAME=user.s-login-id
# PATH=/usr/bin:/usr/sbin:. # BASH=/usr/bin/env bash    # USER=$LOGNAME

#set -uvx       # Treat unset variables as an error, verbose, debug mode

# Source .bashrc only if invoked as a sub-shell. Not if sourced.
if [[ "$(basename cron.sh)" == "$(basename $0)" ]] && [ -f $HOME/.bashrc ]; then
    source $HOME/.bashrc
    log_init INFO $SCRIPT_LOGS/cron.log
fi

function backup()
{
    [[ $# -eq 0 ]] && { echo "Usage: backup <list-with-backup-dir-names>"; return $EINVAL; }

    [[ ! -z "$(grep -w backup $CUSTOM_CONFS/cronskip)" ]] && return;  # skip if configured so

    local backup_list=$1
    while read dir; do
        [[ "$dir" == \#* || ! -d $dir ]] && { continue; } ||  { dir_list+=" $dir"; }
    done < $backup_list

    log INFO "Backing up: $dir_list";
    shell backup.sh "$dir_list";
}

function sync()
{
    log INFO "Syncing Conf & Tools to eng-shell";

    [[ ! -z "$(grep -w rsync $CUSTOM_CONFS/cronskip)" ]] && return;  # skip if configured so

    shell rsync.sh -c $HOME eng-shell1:
}

function nightly()
{
    log CRIT "Running cron for $(/bin/date +'%a %b/%d/%Y %T%p %Z')";

    [[ ! -z "$(grep -w cron $CUSTOM_CONFS/cronskip)" ]] && return;  # skip if configured so

    # take backup before SCM changes the contents
    backup $CUSTOM_CONFS/backup
    build $COMPANY_CONFS/workspaces
    [[ "$(date +'%a')" == "Fri" ]] && { reserve $COMPANY_CONFS/reserve; sync; }
    download
    report
}

function build()
{
    [[ $# -eq 0 ]] && { echo "Usage: build <[path1|path2|...]>"; return $EINVAL; }

    [[ ! -z "$(grep -w jbuild $CUSTOM_CONFS/cronskip)" ]] && return;  # skip if configured so

    local blddir_list=$1; local SVNLOG=svn.log; local STATUS=status.log
    while read dir; do
        [[ "$dir" == \#* || ! -d $dir ]] && { continue; } || { local conflicts=0; cdie $dir; }
        log INFO "Update & status check sandbox: $dir"
        shell jbuild.sh -w $dir;
        shell svn.sh -b $dir; shell svn.sh -s $dir; shell svn.sh -r $STATUS changes.log;
        [[ -f $SVNLOG ]] && { conflicts=$(cat $SVNLOG | grep "^\? "| cut -d " " -f 2 | wc -l | tr -d ' '); }
        [[ $conflicts -ne 0 ]] && { log ERROR "Conflicts found in $SVNLOG. Resolve & retry."; continue; }
        log INFO "Build cscope/ctags db for $dir"
        shell cscope_cgtags.sh -c $dir;
        log INFO "Build sandbox: $dir conflicts: $conflicts"
        shell jbuild.sh -j $dir;
    done < $blddir_list
}

function download()
{
    log INFO "Start pending downloads"

    [[ ! -z "$(grep -w download $CUSTOM_CONFS/cronskip)" ]] && return;  # skip if configured so

    shell download.sh $CUSTOM_CONFS/downlinks;
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

    [[ ! -z "$(grep -w reserve $CUSTOM_CONFS/cronskip)" ]] && return;  # skip if configured so

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
    echo "  -h                  - print this help message"
}

function main()
{
    local PARSE_OPTS="hb:c:d:lnr:s:t"
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

    ((opt_b)) && backup $optarg_b;
    ((opt_c)) && link-confs;
    ((opt_d)) && build $optarg_d;
    ((opt_l)) && crontab -l;
    ((opt_n)) && nightly;
    ((opt_r)) && reserve $optarg_r;
    ((opt_s)) && crontab $optarg_s;
    ((opt_t)) && crontab -r;
    ((opt_h)) && { usage; exit 0; }

    exit 0
}

# $0 is to account for the "-bash" type of strings in login_shell.
# login shell if [[ "$(shopt login_shell | cut -f 2)" == "off" ]]
if [ "$(basename $0)" == "$(basename cron.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4
