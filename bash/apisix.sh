#!/bin/bash
#  DETAILS: APISIX helper script 
#  CREATED: 24/09/24 06:22:29 AM +0530
# MODIFIED: 25/09/24 10:41:24 AM +0530
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2024, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin:/sbin"
APISIX_VERSION=3.10.0   # specify release version
APISIX_DISTRO=debian    # debian, redhat

function bail() { local e=$?; [[ $e -ne 0 ]] && { echo "$! failed w/ err: $e." >&2; exit $e; } || return 0; }

function run()
{
    # time cmd returns return value of child program. And time takes time as argument and still works fine
    [[ ! -z $TIMED_RUN ]] && { local HOW_LONG="time "; }
    [[ $(type -t "$1") == function ]] && { local fname=$1; shift; echo "$fname $*"; $HOW_LONG $fname "$*"; return $?; }
    local p; local a="$HOW_LONG"; for p in "$@"; do a="${a} \"${p}\""; done; test -z "$RUN_LOG" && { RUN_LOG=/dev/null; };
    echo "$a"; test -n "$DRY_RUN" && { return 0; } || eval "$a" 2>&1 | tee -a $RUN_LOG 2>&1; return ${PIPESTATUS[0]};
}

build_docker()
{
    [[ ! -z $CLONE_CODE ]] && { git clone https://github.com/apache/apisix-docker.git; bail; }
    cd apisix-docker && make build-on-$APISIX_DISTRO; bail;
}

build_source()
{
    [[ ! -z $CLONE_CODE ]] && { git clone --branch ${APISIX_VERSION} https://github.com/apache/apisix.git; bail; }
    cd apisix && make deps && make; #make install; bail;
}

usage()
{
    echo "Usage: apisix.sh [-h|]"
    echo "Options:"
    echo "  -h          - print this help"
    echo "  -c          - clone repo before building either w/ source or docker"
    echo "  -d          - build APISIX docker image using pre-build .deb files"
    echo "  -s          - build APISIX from source code and dependencies"
    echo "  -z          - dry run this script"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="hcdsz"
    local opts_found=0
    while getopts ":$PARSE_OPTS" opt; do
        case $opt in
        [a-zA-Z0-9])
            #log DEBUG "-$opt was triggered, Parameter: $OPTARG"
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

    ((opt_z)) && { DRY_RUN=1; LOG_TTY=1; }
    ((opt_c)) && { CLONE_CODE=1; }
    ((opt_d)) && { build_docker; }
    ((opt_s)) && { build_source; }
    ((opt_h)) && { usage; }

    exit 0;
}

if [ "apisix.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
