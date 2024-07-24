#!/bin/bash
#  DETAILS: Manages image/artefact registry (push, pull, list, ...)
#  CREATED: 16/07/24 04:11:43 AM +0530
# MODIFIED: 16/07/24 04:26:37 AM +0530
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2024, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin:/sbin"

DKR_REG_URLS="hub.b4cloud.com"  # space separated URLs

function bail() { local e=$?; [[ $e -ne 0 ]] && { echo "$! failed w/ err: $e." >&2; exit $e; } || return 0; }

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
    [[ $# -ne 1 ]] && { echo "Usage: $FUNCNAME <tag-name>"; return 2; }
    #curl -sS -H 'Accept: application/vnd.docker.distribution.manifest.v2+json'  \
    #    -o /dev/null -w '%header{Docker-Content-Digest}' $DKR_REG_URLS/v2/$1/manifests/$2;
    local reg;
    for reg in ${DKR_REG_URLS}; do
        curl -sS -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' $reg/v2/$REPO_NM/manifests/$1;
    done
}

docker_reg_full_catalog()
{
    local reg;
    for reg in ${DKR_REG_URLS}; do curl -sS $reg/v2/_catalog; bail; done;
    return $?;
}

docker_reg_list_tags()
{
    [[ -z $REPO_NM ]] && { echo "$FUNCNAME: repo name not found"; return 1; }
    local reg;
    for reg in ${DKR_REG_URLS}; do curl -sS $reg/v2/$REPO_NM/tags/list; bail; done;
    return $?;
}

usage()
{
    echo "Usage: registry.sh [-h|-e|-f|-g|-j|-p|-z]"
    echo "Options:"
    echo "  -h              - print this help"
    echo "  -e <repo>       - external repo name (from -f o/p) to perform ops on registry"
    echo "  -f              - full catalog of all repos in registry"
    echo "  -g              - list all tags for (-e) repo in registry"
    echo "  -j <tag>        - print digest of tag (from -g o/p) of (-e) repo in registry"
    echo "  -p <img:tag>    - push given docker image:tag to docker registry"
    echo "  -z              - dry run this script"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="he:fgj:p:z"
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
    ((opt_f)) && { docker_reg_full_catalog; }
    ((opt_e)) && { REPO_NM=$optarg_e; }
    ((opt_g || opt_j)) && { [[ -z $REPO_NM ]] && { echo "-g, -j options require repo name, use -e option"; exit -1; }; }
    ((opt_g)) && { docker_reg_list_tags; }
    ((opt_j)) && { print_tag_digest $optarg_j; }
    ((opt_p)) && { docker_reg_push $optarg_p; bail; }
    ((opt_h)) && { usage; }

    exit 0;
}

if [ "registry.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
