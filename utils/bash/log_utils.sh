#!/bin/bash
#  DETAILS: Logger library for syslog style logging in bash scripts
#   https://github.com/nischithbm/bash-logger
#   http://sourceforge.net/projects/bash-logger
#  CREATED: 06/21/13 23:58:09 IST
# MODIFIED: 10/06/14 14:24:35 IST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

#set -uvx               # Warn unset vars as error, Verbose (echo each command), Enable debug mode

# Load and Use logger
# --------------------
#   source log_utils.sh
#   LOG_FILE_PATH=./test.log
#   log_init <LOG_LEVEL>
#   log <LOG_LEVEL> "Your message here"
#
#Customization Steps
#-------------------
#    1. Load the source file
#    source log_utils.sh
#    2. Customize the logger
#    LOG_LEVEL=DEBUG
#    3. Init logger with new config
#    log_init $LOG_LEVEL

# Date in MSEC is not supported on all platforms. Like FreeBSD. So, removing support in logs
# Truncate last 6 digits: sed 's/......$//g' & sed 's/[0-9][0-9][0-9][0-9][0-9][0-9]$//g' same.
# [[ ! -z $LOG_DATE_ENABLE_MSEC ]] && { local local_date_time=$(date +"$LOG_DATE_FORMAT"".%N" | sed 's/......$//g'); }

: ${PATH=/usr/local/bin:/usr/sbin:/usr/bin:/bin}

# Default Values for Tunable Config Options
LOG_FILE_PATH="$SCRIPT_LOGS/log_utils.log"
LOG_LEVEL=INFO
LOG_DATE_FORMAT="%Y-%m-%d %H:%M:%S"
LOG_MSG_FORMAT="%s %s\n"
LOG_MAX_FILE_SIZE=10000              # In KB
LOG_MAX_BACKUPS=1
#LOG_TO_TTY=TRUE                 # Set variable for logging to console
LOG_MAIL_OLD_LOGS=TRUE
LOG_EMAIL_ID=raviks@juniper.net

# create directory path (if doesn't exist). Otherwise just update timestamp.
function verify_create_dirs()
{
    [[ $# -lt 1 ]] && { echo "usage: verify_create_dirs [<dir1> <dir2> ...]"; return; }
    local dir;
    for dir in $*; do      # no checks necessary, as: [[ -e $dir ]] && { continue; }
        mkdir -pv "$dir" && chmod 740 "$dir" && chown $USER "$dir"
    done
}

# create file and path (if doesn't exist). Otherwise just update timestamp.
function verify_create_files()
{
    [[ $# -lt 1 ]] && { echo "usage: verify_create_files [<file1> <file2> ...]"; return; }
    local file;
    for file in $*; do      # no checks necessary, as: [[ -e $file ]] && { continue; }
        verify_create_dirs "$(dirname $file)"
        touch "$file" && chmod 640 "$file" && chown $USER "$file"
    done
}

function log_env_verify_update()
{
    [[ -z $LOG_HOSTNAME ]]      && export LOG_HOSTNAME=$(hostname_short)         # solaris doesnt support -s
    [[ -z $LOG_PROCID ]]        && export LOG_PROCID=$(echo $$)
    [[ -z $LOG_SCRIPTNAME ]]    && export LOG_SCRIPTNAME=$(basename -- $(echo $0))
}

# RFC 5424 defines 8 levels of severity
function log_init()
{
    [[ "" != "$1" ]] && LOG_LEVEL=$1
    [[ "" != "$2" ]] && LOG_FILE_PATH=$2

    verify_create_files $LOG_FILE_PATH;

    log_rotate $LOG_FILE_PATH;

    log_env_verify_update

    # LOG_LEVELS_ENABLED setting should be last thing during init. Other functions depend on it.
    case "$LOG_LEVEL" in
        "EMERG")
            LOG_LEVELS_ENABLED=( "<EMERG>" )
            ;;
        "ALERT")
            LOG_LEVELS_ENABLED=( "<ALERT>" "<EMERG>" )
            ;;
        "CRIT")
            LOG_LEVELS_ENABLED=( "<CRIT>" "<ALERT>" "<EMERG>" )
            ;;
        "ERROR")
            LOG_LEVELS_ENABLED=( "<ERROR>" "<CRIT>" "<ALERT>" "<EMERG>" )
            ;;
        "WARN")
            LOG_LEVELS_ENABLED=( "<WARN>" "<ERROR>" "<CRIT>" "<ALERT>" "<EMERG>" )
            ;;
        "NOTE")
            LOG_LEVELS_ENABLED=( "<NOTE>" "<WARN>" "<ERROR>" "<CRIT>" "<ALERT>" "<EMERG>" )
            ;;
        "INFO")
            LOG_LEVELS_ENABLED=( "<INFO>" "<NOTE>" "<WARN>" "<ERROR>" "<CRIT>" "<ALERT>" "<EMERG>" )
            ;;
        "DEBUG")
            LOG_LEVELS_ENABLED=( "<DEBUG>" "<INFO>" "<NOTE>" "<WARN>" "<ERROR>" "<CRIT>" "<ALERT>" "<EMERG>" )
            ;;
        *)
            # Default Log level is INFO
            echo "Unsupport log level $LOG_LEVEL. Setting log level to default -- INFO"
            LOG_LEVELS_ENABLED=( "<INFO>" "<NOTE>" "<WARN>" "<ERROR>" "<CRIT>" "<ALERT>" "<EMERG>" )
            ;;
    esac
}

function log_rotate()
{
    [[ $# -ne 1 ]] && (echo "usage: log_rotate <log-file>"; return $EINVAL)

    local logFile="$1";
    verify_create_files $logFile;

    if [ $(wc -l "$logFile" | awk '{print $1}') -gt 0 ]; then
        echo "================================================================================" >> $logFile.0
        cat $logFile >> $logFile.0 && cat /dev/null > $logFile;
    fi

    touch $logFile.0;
    # do nothing if either size is below limit OR new (0 size) file. du -k isn't reliable for small files.
    [[ $(wc -l "$logFile.0" | awk '{print $1}') -lt $LOG_MAX_FILE_SIZE ]] && return;

    local length=$((${#logFile} + 1))   # filename length + 1 (to account for . as in log.1 log.2)
    local max=0; local f; local num;

    # Find out upto which sequence logFile.0..9 the archive has grown
    for f in ${logFile}.[0-$LOG_MAX_BACKUPS]*; do
        # ${f:$length} extracts the last value in filename. Ex. 3 for log.3
        [ -f "$f" ] && num=${f:$length} && [ $num -gt $max ] && max=$num
    done

    if [ $max -ge $LOG_MAX_BACKUPS -a -f "$logFile.$(($max + 1))" -a "$LOG_MAIL_OLD_LOGS" == "TRUE" ]; then
        local oldFile="$logFile.$(($max + 1))"; gzip $oldFile; local archFile="$oldFile.gz";
        # uuencode 2nd arg is attachment filename (as appears in mail). mutt isn't available on all machines.
        uuencode $archFile $(basename $archFile) | mail -s "[ARCHIVE] Old logs" $LOG_EMAIL_ID
        rm -f ${oldFile} ${archFile}
    fi

    local i;
    for ((i = $max;i >= 0;i -= 1)); do
        [ -f "$logFile.$i" ] && mv -f $logFile.$i "$logFile.$(($i + 1))" > /dev/null 2>&1
    done
}

function log()
{
    if [ $# -ne 2 ]; then
        echo "usage: log <LOG_LEVEL> <log-message>\nLOG_LEVEL=EMERG/ALERT/CRIT/ERROR/WARN/NOTE/INFO/DEBUG";
        return;
    fi

    # If LOG_LEVELS_ENABLED is enabled, all initializations are done.
    [[ -z $LOG_LEVELS_ENABLED ]] && { return; }

    local is_log_level_enabled=$(echo ${LOG_LEVELS_ENABLED[@]} | grep "<$1>")
    [[ -z ${is_log_level_enabled} ]] && { return; }

    local log_severity=$1; shift;
    local local_date_time=$(date +"$LOG_DATE_FORMAT")
    local log_prefix="$local_date_time $LOG_HOSTNAME $LOG_SCRIPTNAME[$LOG_PROCID] $log_severity:"
    local is_crit_log=$(echo ${log_severity} | grep -E "EMERG|ALERT|CRIT")
    printf "$LOG_MSG_FORMAT" "$log_prefix" "$*" >> $LOG_FILE_PATH;
    [[ ! -z ${LOG_TO_TTY} || ! -z ${is_crit_log} ]] && { printf "$LOG_MSG_FORMAT" "$log_prefix" "$*" 1>&2; }
}

usage()
{
    echo "Usage: log_utils.sh <-h|-l <log-level> <log-message>|-r <log-file>>"
    echo "Options:"
    echo "  -l <log-level> <log-message>- log given message at given log-level"
    echo "  -r <log-file>               - rotate given log file"
    echo "  -h                          - print this help message"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    # save current settings. log_init function can be called to reinitialse the logger
    log_rotate $LOG_FILE_PATH && log_init

    local PARSE_OPTS="hl:r:"
    local opts_found=0; local opt;
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

    ((opt_l)) && log $optarg_l $*
    ((opt_r)) && log_rotate $optarg_r
    ((opt_h)) && (usage; exit 0)

    exit 0
}

if [ "$(basename -- $0)" == "$(basename log_utils.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4

