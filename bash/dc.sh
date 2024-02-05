#!/bin/bash
#  DETAILS: Docker Compose (dc) helper script to perform day-to-day tasks
#  CREATED: 18/12/23 07:08:21 UTC
# MODIFIED: 10/01/24 10:41:59 PM +0530
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2023, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

PATH="/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin:/sbin"

DKR_REG_URLS="hub.b4cloud.com"  # space separated URLs
DC_CMD='docker -D compose --progress plain'
# If any files are removed after build, compress img. squash is obsolete option
#DC_BLD_ARGS='--squash'

# Push input docker image to pre-configured registry
docker_reg_push()
{
    [[ $# -ne 1 ]] && { echo "Usage: $FUNCNAME <image:tag>"; return 1; }
    local reg;
    for reg in ${DKR_REG_URLS}; do
        docker tag $1 $reg/${1//\//_} && docker push $reg/${1//\//_}; bail;
    done
    return $?;
}

docker_stop_rm()
{
    [[ $1 != all ]] && { docker stop $1 && docker rm $1; return $?; }
    local dkr;
    for dkr in $(docker ps -a | grep -v CREATED | awk '{print $1}'); do
        docker stop $dkr && docker rm $dkr; bail;
    done
    return 0;
}

usage()
{
    echo "Usage: dc.sh [-h|]"
    echo "Options:"
    echo "  -h          - print this help"
    echo "  -a <svc/sha>- do docker attach to given container"
    echo "  -b [svc]    - run docker compose build"
    echo "  -c          - list all running/stopped containers (docker ps -a)"
    echo "  -d [svc]    - run docker compose up in daemon mode"
    echo "  -i          - list all docker images"
    echo "  -l [svc]    - show docker compose up logs"
    echo "  -m <img/sha>- remove the given docker image"
    echo "  -n          - do not use cache during docker compose build"
    echo "  -p <img:tag>- push given docker image:tag to docker registry"
    echo "  -r <sha|all>- run docker stop & docker rm, on single or all"
    echo "  -s [svc]    - run docker compose stop, proc stopped, FS still kept"
    echo "  -t [img]    - show docker history for given container image"
    echo "  -u [svc]    - run docker compose up in interactive mode for test"
    echo "  -z          - dry run this script"
    echo "NOTE: [svc] is optional, by default applies to all services"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="habcdilm:np:r:st:uz"
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
    ((opt_a)) && { docker attach $@; bail; }
    ((opt_l)) && { $DC_CMD logs --no-color $@; bail; }
    ((opt_i)) && { docker images; bail; }
    ((opt_m)) && { docker rmi $optarg_m; bail; }
    ((opt_n)) && { DC_BLD_ARGS+=" --no-cache"; }
    ((opt_b)) && { $DC_CMD build $DC_BLD_ARGS $@; bail; }
    ((opt_d)) && { DC_UP_ARGS="-d --remove-orphans"; }
    ((opt_d || opt_u)) && { $DC_CMD up $DC_UP_ARGS $@; bail; }
    ((opt_d || opt_c)) && { docker ps -a; } # docker ps == docker container ps
    # stop kills container proc, but FS is kept, you can do docker commit w/ it
    ((opt_s)) && { $DC_CMD stop $@; bail; }
    ((opt_p)) && { docker_reg_push $optarg_p; bail; }
    # rm removes the FS, but it requires container to have stopped first
    ((opt_r)) && { docker_stop_rm $optarg_r; bail; }
    ((opt_t)) && { docker attach $@; bail; }
    ((opt_h)) && { usage; }

    exit 0;
}

if [ "dc.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
