#!/bin/bash
#  DETAILS: Logger library for syslog style logging in bash scripts
#   https://github.com/nischithbm/bash-logger
#   http://sourceforge.net/projects/bash-logger
#  CREATED: 06/21/13 23:58:09 IST
# MODIFIED: 21/Apr/2018 02:41:10 PDT
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

#set -uvx               # Warn unset vars as error, Verbose (echo each command), Enable debug mode

# Logger Usage Guideline
#-----------------------
# 1. Load the source file:          source log_utils.sh
# 2. Init logger with new config:   log_init <LOG_LEVEL> <LOG_FILE>
# 3. Use logger api for logging:    log <LOG_LEVEL> "Your message here"

# Truncate last 6 digits: sed 's/......$//g' & sed 's/[0-9][0-9][0-9][0-9][0-9][0-9]$//g' same.
# [[ ! -z $LOG_DATE_ENABLE_MSEC ]] && { local date_time_msec=$(date +"$DATE_FMT"".%N" | sed 's/......$//g'); }

# Tunable Config Options (Defaults)
LOG_FILE="$SCRPT_LOGS/log_utils.log"
#LOG_TTY=TRUE                        # console logging

function export_log_funcs() { local FUNCS="log_init log"; export_func $FUNCS; }

# RFC 5424 defines 8 levels of severity
function log_init()
{
    [[ $# -eq 0 ]] && { return $EINVAL; } || { LOG_LEVEL=$1; [[ $# -eq 2 ]] && LOG_FILE="$2" || LOG_FILE="$(myname).log"; }

    mkfile $LOG_FILE && file_rotate $LOG_FILE; [[ $? -ne 0 ]] && return $?; # any problem writing to file, return.

    # LOG_LVLS_ON set is last step during init. log() depends on it.
    case "$LOG_LEVEL" in
        "EMERG") LOG_LVLS_ON=( "<EMERG>" ); ;;
        "ALERT") LOG_LVLS_ON=( "<ALERT>" "<EMERG>" ); ;;
        "CRIT")  LOG_LVLS_ON=( "<CRIT>" "<ALERT>" "<EMERG>" ); ;;
        "ERROR") LOG_LVLS_ON=( "<ERROR>" "<CRIT>" "<ALERT>" "<EMERG>" ); ;;
        "WARN")  LOG_LVLS_ON=( "<WARN>" "<ERROR>" "<CRIT>" "<ALERT>" "<EMERG>" ); ;;
        "NOTE")  LOG_LVLS_ON=( "<NOTE>" "<WARN>" "<ERROR>" "<CRIT>" "<ALERT>" "<EMERG>" ); ;;
        "INFO")  LOG_LVLS_ON=( "<INFO>" "<NOTE>" "<WARN>" "<ERROR>" "<CRIT>" "<ALERT>" "<EMERG>" ); ;;
        "DEBUG") LOG_LVLS_ON=( "<DEBUG>" "<INFO>" "<NOTE>" "<WARN>" "<ERROR>" "<CRIT>" "<ALERT>" "<EMERG>" ); ;;
        *) LOG_LVLS_ON=( "<INFO>" "<NOTE>" "<WARN>" "<ERROR>" "<CRIT>" "<ALERT>" "<EMERG>" ); ;; # Invalid log-level, reset to default (INFO)
    esac
    return 0;
}

# usage: log <LOG_LVL> <log-msg>. LOG_LVL=EMERG/ALERT/CRIT/ERROR/WARN/NOTE/INFO/DEBUG
function log()
{
    [[ $# -ne 2 ]] && { return $EINVAL; } || { local is_log_lvl_on; }
    [[ -z $LOG_LVLS_ON ]] && { return $ENOENT; } || { is_log_lvl_on=$(echo ${LOG_LVLS_ON[@]} | grep "<$1>"); } # If LOG_LVLS_ON set, log_init done
    [[ -z ${is_log_lvl_on} ]] && { return 0; } || { local is_crit=$(echo ${log_sev} | grep -E "EMERG|ALERT|CRIT"); } # return if below log-sev filter
    [[ ! -z $LOG_TTY || ! -z $is_crit ]] && { warn "$*" | tee -a $LOG_FILE; } || { prnt "$*" >> $LOG_FILE; } # log-sev prints in log(), not in prnt()
    return 0;
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
    local PARSE_OPTS="hi:l:r:"
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

    #log_init $LOG_FILE
    ((opt_i)) && { LOG_FILE="$*"; log_init $optarg_i $LOG_FILE; }
    ((opt_l)) && { log $optarg_l $*; }
    ((opt_r)) && { file_rotate $optarg_r; }
    ((opt_h)) && (usage; exit 0)

    exit 0
}

if [ "$(basename -- $0)" == "$(basename log_utils.sh)" ]; then
    main $*
else
    export_log_funcs
fi
# VIM: ts=4:sw=4
