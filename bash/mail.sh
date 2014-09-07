#!/usr/bin/env bash
#  DETAILS: Send mail to pre-defined email addresses
#  CREATED: 11/19/12 14:14:03 IST
# MODIFIED: 09/05/14 21:49:55 IST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2012, Ravikiran K.S.

#set -uvx               # Treat unset variables as an error, verbose, debug mode

# Source .bashrc only if invoked as a sub-shell.
if [[ "$(basename mail.sh)" == "$(basename $0)" ]] && [ -f $HOME/.bashrc ]; then
    source $HOME/.bashrc
    log_init INFO $SCRIPT_LOGS/mail.log
    # Global defines. (Re)define ENV only if necessary.
fi

# ravikirandotks@gmail.com mrksravikiran@gmail.com friends4web@gmail.com
MAILADDRS=raviks@juniper.net

mail-send()
{
    args=$#
    if [ $args -ne 2 ]; then
        echo "usage: mail-send <subject> <content-file>"
        exit 1
    fi

    box=$(hostname_short)
    content="$2"
    for email in $MAILADDRS; do
        # no 'run' for mailx. Gets confused.
        mailx -s "[$1] From $box" $email < $content
    done
}

usage()
{
    echo "usage: mail.sh <-b <build-log>|-c|-f <file>|-h>"
    echo "Options:"
    echo "  -b <build-log>  - mail the build log provided"
    echo "  -c              - mail the log from cron job"
    echo "  -f <file>       - mail the file provided"
    echo "  -h              - print this help message"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="hb:cf:"
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

    ((opt_b)) && mail-send "BUILD" $optarg_b
    ((opt_c)) && mail-send "CRON" $SCRIPT_LOGS/cron.log
    ((opt_f)) && mail-send "AUTO" $optarg_f
    ((opt_h)) && (usage; exit 0)

    exit 0
}

if [ "$(basename $0)" == "$(basename mail.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4

