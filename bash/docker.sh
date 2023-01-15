#!/bin/bash
#  DETAILS: Docker helper script
#   - Quickly try out some tool/installer, without changes to main laptop OS
#   - Have isolated environment for quick development and testing of software
#
#  CREATED: 01/04/22 03:27:25 PM IST IST
# MODIFIED: 20/04/2022 09:50:50 AM IST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2022, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

PATH="/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin:/sbin"

[[ "$(basename docker.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

DKR_PFX=_ns

function docker_bld()
{
    echo "Docker build $DKR_TGT_NM using $DKRFILE_PATH" && docker build -d ./$DKRFILE_PATH -t $DKR_TGT_NM $DKR_DPATH
}

function docker_run()
{
    echo "Docker run $1" && docker run -dit --name $DKR_TGT_NM$DKR_PFX $DKR_TGT_NM
}

function docker_cnct()
{
    echo "Docker connect to $DKR_TGT_NM" && docker exec -it $DKR_TGT_NM$DKR_PFX $(which bash)
}

function docker_lst()
{
    echo "Docker images:" && docker image ls
    echo "Docker instances:" && docker ps -a
}

function docker_del()
{
    echo "Delete Docker container $1" && docker rm $1 && docker rmi $1; # 'rm -f' for force
}

usage()
{
    echo "Usage: docker.sh [-h|-b|-c|-d|-l|-r]"
    echo "Options:"
    echo "  -b          - build container with Dockerfile (-f), tgt-nm (-t)"
    echo "  -c          - connect to running instance of given tgt-nm (-t)"
    echo "  -d          - stop instance, delete img of given tgt-nm (-t)"
    echo "  -f <fpath>  - specify Dockerfile path for build operation"
    echo "  -l          - list all running instances and local images"
    echo "  -p <dpath>  - specify start directory for the instance"
    echo "  -t <tgt-nm> - specify target-name for various operations"
    echo "  -h          - print this help"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="hbcdf:lp:t:"
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
    ((opt_l)) && { docker_lst $*; }
    ((opt_f)) && { DKRFILE_PATH="$optarg_f"; } || { DKRFILE_PATH="./Dockerfile"; }
    ((opt_p)) && { DKR_DPATH="$optarg_p"; } || { DKR_DPATH="."; }
    ((opt_t)) && { DKR_TGT_NM="$optarg_t"; }
    ((opt_b || opt_c || opt_d)) && [[ -z $DKR_TGT_NM ]] && { echo "Provide -t <tgt-name>"; return $EINVAL; }
    ((opt_b)) && { docker_bld $*; }
    ((opt_c)) && { docker_cnct $*; }
    ((opt_d)) && { docker_del $*; }

    exit 0;
}

if [ "docker.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
