#!/bin/bash
#  DETAILS: 
#  CREATED: Sunday 11 April 2021 10:33:30  PDT PDT
# MODIFIED: 11/Apr/2021 23:29:43 PDT
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2021, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

PATH=/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin:/sbin

[[ "$(basename analyze.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

function analyze_core()
{
    if [ "$#" == "0" ]; then
        usage
        exit 1
    fi

    bin=$1
    core=$2
    log="$core-gdb.log"

    run gdb -batch \
        -ex "set logging file $log" \
        -ex "set logging on" \
        -ex "set pagination off" \
        -ex "printf \"**\n** Process info for $bin - $core \n** Generated `date`\n\"" \
        -ex "printf \"**\n** $(ls -l $bin) \n** $(ls -l $core)\n**\n\"" \
        -ex "file $bin" \
        -ex "core-file $core" \
        -ex "bt" \
        -ex "info proc" \
        -ex "printf \"*\n* Libraries \n*\n\"" \
        -ex "info sharedlib" \
        -ex "printf \"*\n* Memory map \n*\n\"" \
        -ex "info target" \
        -ex "printf \"*\n* Registers \n*\n\"" \
        -ex "info registers" \
        -ex "printf \"*\n* Current instructions \n*\n\"" -ex "x/16i \$pc" \
        -ex "printf \"*\n* Threads (full) \n*\n\"" \
        -ex "info threads" \
        -ex "bt" \
        -ex "thread apply all bt full" \
        -ex "printf \"*\n* Threads (basic) \n*\n\"" \
        -ex "info threads" \
        -ex "thread apply all bt" \
        -ex "printf \"*\n* Done \n*\n\"" \
        -ex "quit"

    exit 0
}

function generate_core()
{
    if [ "$#" == "0" ]; then
        usage
        exit 1
    fi

    pid=$1
    gdblogfile="analyze-$pid.log"
    corefile="core-$pid.core"

    run gdb -batch \
        -ex "set logging file $gdblogfile" \
        -ex "set logging on" \
        -ex "set pagination off" \
        -ex "printf \"**\n** Process info for PID=$pid \n** Generated `date`\n\"" \
        -ex "printf \"**\n** Core: $corefile \n**\n\"" \
        -ex "attach $pid" \
        -ex "bt" \
        -ex "info proc" \
        -ex "printf \"*\n* Libraries \n*\n\"" \
        -ex "info sharedlib" \
        -ex "printf \"*\n* Memory map \n*\n\"" \
        -ex "info target" \
        -ex "printf \"*\n* Registers \n*\n\"" \
        -ex "info registers" \
        -ex "printf \"*\n* Current instructions \n*\n\"" -ex "x/16i \$pc" \
        -ex "printf \"*\n* Threads (full) \n*\n\"" \
        -ex "info threads" \
        -ex "bt" \
        -ex "thread apply all bt full" \
        -ex "printf \"*\n* Threads (basic) \n*\n\"" \
        -ex "info threads" \
        -ex "thread apply all bt" \
        -ex "printf \"*\n* Done \n*\n\"" \
        -ex "generate-core-file $corefile" \
        -ex "detach" \
        -ex "quit"

    exit 0
}

usage()
{
    echo "Usage: analyze.sh [-h|]"
    echo "Options:"
    echo "  -h              - print this help"
    echo "  -a <core-path>  - analyze corefile, log it to file"
    echo "  -g <pid>        - generate corefile, log it to file"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="ha:g:"
    local opts_found=0
    while getopts ":$PARSE_OPTS" opt; do
        case $opt in
        [a-zA-Z0-9])
            log DEBUG "-$opt was triggered, Parameter: $OPTARG"
            local "opt_$opt"=1 && local "optarg_$opt"="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG"; usage; exit $EINVAL
            ;;
        :)
            echo "[ERROR] Option -$OPTARG requires an argument";
            usage; exit $EINVAL
            ;;
        esac
        shift $((OPTIND-1)) && OPTIND=1 && local opts_found=1;
    done

    if ((!opts_found)); then
        usage && exit $EINVAL;
    fi

    ((opt_h)) && { usage; }
    ((opt_a)) && { analyze_core $optarg_a; }
    ((opt_g)) && { generate_core $optarg_g; }

    exit 0;
}

if [ "analyze.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
