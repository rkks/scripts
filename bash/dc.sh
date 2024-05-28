#!/bin/bash
#  DETAILS: Docker Compose (dc) helper script to perform day-to-day tasks
#  Concatenated build is supported by docker-compose, example:
#  $ docker-compose -f docker-compose.yml -f docker-compose.dev.yml
#
#  CREATED: 18/12/23 07:08:21 UTC
# MODIFIED: 21/05/24 09:59:41 PM IST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2023, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

PATH="/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin:/sbin"

# Exposing port 5000 on host & directly referring it is unnecessary: hub.b4cloud.com:5000/v2/_catalog
DKR_REG_URLS="hub.b4cloud.com"  # space separated URLs
DC_CMD='docker -D compose --progress plain'
# If any files are removed after build, compress img. squash is obsolete option
#DC_BLD_ARGS='--squash'

# Push input docker image to pre-configured local registry.
# ${IMG_TAG/:/_} - replaces first occurrance of char ':'
# ${IMG_TAG//:/_} - replaces all occurrances of char ':'.
docker_reg_push()
{
    [[ $# -ne 1 ]] && { echo "Usage: $FUNCNAME <image:tag>"; return 1; }
    local reg;
    for reg in ${DKR_REG_URLS}; do
        docker tag $1 $reg/${1//\//_} && docker push $reg/${1//\//_}; bail;
    done
    return $?;
}

print_tag_digest()
{
    [[ $# -ne 2 ]] && { echo "Usage: $FUNCNAME <repo-name> <tag-name>"; return 2; }
    #curl -sS -H 'Accept: application/vnd.docker.distribution.manifest.v2+json'  \
    #    -o /dev/null -w '%header{Docker-Content-Digest}' $DKR_REG_URLS/v2/$1/manifests/$2;
    curl -sS -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' $DKR_REG_URLS/v2/$1/manifests/$2;
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
    echo "  -e <repo>   - external repo name (from -f o/p) to perform ops on registry"
    echo "  -f          - full catalog of all repos in registry"
    echo "  -g          - list all tags for (-e) repo in registry"
    echo "  -i          - list all docker images"
    echo "  -j <tag>    - print digest of tag (from -g o/p) of (-e) repo in registry"
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
    PARSE_OPTS="habcde:fgij:lm:np:r:st:uz"
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
    ((opt_f)) && { curl -sS $DKR_REG_URLS/v2/_catalog; }
    ((opt_e)) && { REPO_NM=$optarg_e; }
    ((opt_g || opt_j)) && { [[ -z $REPO_NM ]] && { echo "-d, -t option require repo name, use -r option"; exit -1; }; }
    ((opt_g)) && { curl -sS $REGISTRY_URL/v2/$REPO_NM/tags/list; }
    ((opt_j)) && { print_tag_digest $REPO_NM $optarg_j; }
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
    # docker compose down $* - Also deletes n/w, images, volumes, along w/ FS
    # rm removes FS, but requires container to have stopped first
    ((opt_r)) && { docker_stop_rm $optarg_r; bail; }
    ((opt_t)) && { docker attach $@; bail; }
    ((opt_h)) && { usage; }

    exit 0;
}

if [ "dc.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
