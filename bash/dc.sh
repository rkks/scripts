#!/bin/bash
#  DETAILS: Docker Compose (dc) helper script to perform day-to-day tasks
#  Concatenated build is supported by docker-compose, example:
#  $ docker-compose -f docker-compose.yml -f docker-compose.dev.yml
#
#  CREATED: 18/12/23 07:08:21 UTC
# MODIFIED: 30/09/24 11:05:27 PM IST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2023, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

PATH="/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin:/sbin:$PATH"

#[[ "$(basename dc.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

# Exposing port 5000 on host & directly referring it is unnecessary: hub.b4cloud.com:5000/v2/_catalog
DC_CMD='docker -D compose --progress plain'
# If any files are removed after build, compress img. squash is obsolete option
#DC_BLD_ARGS='--squash'
DKR_NET_KLM=macvlan
DKR_IF_NM=dkrif

function bail() { local e=$?; [[ $e -ne 0 ]] && { echo "$! failed w/ err: $e." >&2; exit $e; } || return 0; }

# $DC_CMD stop $@; -- docker stop & docker-compose stop are identical
docker_stop()
{
    docker stop $@ || docker kill $@; return $?;
}

docker_stop_all()
{
    [[ -z $DKR_LST ]] && { echo "Empty docker instances list"; return $EINVAL; }
    local dkr;
    for dkr in $DKR_LST; do
        docker_stop $dkr; bail;
    done
    return 0;
}

docker_rm_all()
{
    [[ -z $DKR_LST ]] && { echo "Empty docker instances list"; return $EINVAL; }
    local dkr;
    for dkr in $DKR_LST; do
        docker rm $dkr; bail;
    done
    return 0;
}

add_dkr_vnet()
{
    [[ $# -ne 1 ]] && { echo "usage: $FUNCNAME <ipvlan-ip>"; exit -1; }
    [[ -z $DKR_HOST_INF || -z $DKR_GUEST_IP ]] && { echo "-o and -w options are required"; exit -1; }
    [[ $DKR_HOST_INF =~ br? ]] && { echo "bridge interface not accepted for mac/ipvlan inf"; exit -1; }

    local phyifbridged=$(sudo brctl show | grep $DKR_HOST_INF | wc -l);
    [[ $phyifbridged -ne 0 ]] && { echo "interface $DKR_HOST_INF is bridged, choose unbridged one"; exit -1; }

    local dkrifexists=$(ip addr | grep $DKR_IF_NM | wc -l); local ipa=$1;
    if [ $dkrifexists -eq 0 ]; then
        local typ="";
        [[ $DKR_NET_KLM =~ macvlan ]] && typ="macvlan mode bridge" || typ="ipvlan mode l2"; # up ip link add dkrif link br0 type ipvlan mode l2
        sudo ip link add $DKR_IF_NM link $DKR_HOST_INF type $typ && \
        sudo ip addr add $ipa/32 dev $DKR_IF_NM && sudo ip link set $DKR_IF_NM up; bail;
        echo "Add below lines after interface settings in /etc/network/interfaces"
        echo "up ip link add $DKR_IF_NM link $DKR_HOST_INF type $typ"	# up ip link add dkrif link br0 type macvlan mode bridge
        echo "up ip addr add $ipa/32 dev $DKR_IF_NM";			# up ip addr add 192.168.1.60/32 dev dkrif
        echo "up ip link set $DKR_IF_NM up"				# up ip link set dkrif up
        # IMP: DO NOT ADD docker network create to /etc/network/interfaces. parent accepts br0, but does not work.
#up docker network create --driver=ipvlan --subnet=192.168.1.0/24 --gateway=192.168.1.1 --opt parent=enp0s31f6 b4cnet
        # '-o ipvlan_mode=l2' not needed, default mode for ipvlan. https://docs.docker.com/network/drivers/macvlan/
        docker network prune --force; bail;
        docker network create --driver=$DKR_NET_KLM --subnet=192.168.1.0/24 --gateway=192.168.1.1 --opt parent=$DKR_HOST_INF b4cnet
    fi

    local rtexists=$(ip route | grep $DKR_GUEST_IP | wc -l);
    if [ $rtexists -eq 0 ]; then
        sudo ip route add $DKR_GUEST_IP/32 dev $DKR_IF_NM; bail; # 192.168.1.61
    fi
    return $?;
}

del_dkr_vnet()
{
    [[ $# -ne 1 ]] && { echo "usage: $FUNCNAME <dkr-guest-ip>"; exit -1; }

    local dgip=$1;
    local rtexists=$(ip route | grep $dgip | wc -l);
    if [ $rtexists -ne 0 ]; then
        sudo ip route del $dgip/32 dev $DKR_IF_NM; bail; # 192.168.1.61
    fi
    local infrtexists=$(ip route | grep $DKR_IF_NM | wc -l);
    if [ $infrtexists -eq 0 ]; then
        sudo ip link del $DKR_IF_NM; bail;   # no route exists for $DKR_IF_NM
        docker network prune --force;
    fi
    return $?;
}

usage()
{
    echo "Usage: dc.sh [-h|]"
    echo "Options:"
    echo "  -h              - print this help"
    echo "  -a <svc/sha>    - do docker attach to given container"
    echo "  -b [svc]        - run docker compose build"
    echo "  -c              - list all running/stopped containers (docker ps -a)"
    echo "  -d [svc]        - run docker compose up in daemon mode"
    echo "  -e <img/sha>    - remove the given docker image"
    echo "  -f <dc-fpath>   - file path to use in 'docker compose -f <fpath>'"
    echo "  -i              - list all docker images"
    echo "  -k              - delete docker route, ipvlan inf if no routes (use -o)"
    echo "  -l [svc]        - show docker compose up logs"
    echo "  -m              - use ipvlan driver/mode for docker n/w (default: macvlan)"
    echo "  -n [prune]      - without any args, list docker networks, else prune them"
    echo "  -o <dkr-ip>     - docker guest IP address for -k, -v options"
    echo "  -q              - run docker compose build (-b) with --no-cache"
    echo "  -r <svc-sha|all>- run docker stop & docker rm, on single or all"
    echo "  -s <svc-sha|all>- run docker compose stop, proc stopped, FS still kept"
    echo "  -t [img]        - show docker history for given container image"
    echo "  -u [svc]        - run docker compose up in interactive mode for test"
    echo "  -v <hip>        - add ipvlan inf & docker guest route (pass -o, -w)"
    echo "  -w <phy-inf>    - physical interface name for -v option"
    echo "  -x <svc/sha>    - run docker exec -it bash for given container"
    echo "  -z              - dry run this script"
    echo "NOTE: [svc] is optional, by default applies to all services"
    echo "EXAMPLE: dc.sh -v 192.168.1.60 -w enp0s31f6 -o 192.168.1.64"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="ha:bcde:f:iklmno:p:qrst:uv:w:x:z"
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
    ((opt_o)) && { DKR_GUEST_IP=$optarg_o; }
    ((opt_k)) && { del_dkr_vnet $DKR_GUEST_IP; }
    ((opt_f)) && { DC_CMD="$DC_CMD -f $optarg_f"; }
    ((opt_w)) && { DKR_HOST_INF=$optarg_w; }
    ((opt_m)) && { DKR_NET_KLM=ipvlan; }
    ((opt_n)) && { [[ $# -ne 0 ]] && docker network $@ || docker network ls; }
    ((opt_v && !opt_k)) && { add_dkr_vnet $optarg_v; }
    ((opt_a)) && { docker attach $optarg_a; bail; }
    ((opt_x)) && { docker exec -it $optarg_x bash; bail; }
    ((opt_l)) && { $DC_CMD logs --no-color $@; bail; }
    ((opt_i)) && { docker images; bail; }
    ((opt_e)) && { docker rmi $optarg_e; bail; }
    ((opt_q)) && { DC_BLD_ARGS+=" --no-cache"; }
    ((opt_b)) && { $DC_CMD build $DC_BLD_ARGS $@; bail; }
    ((opt_d)) && { DC_UP_ARGS="-d --remove-orphans"; }
    ((opt_d || opt_u)) && { $DC_CMD up $DC_UP_ARGS $@; bail; }
    ((opt_d || opt_c)) && { docker ps -a; } # docker ps == docker container ps
    ((opt_r || opt_s)) && { [[ $# -ne 1 ]] && { echo "-s and -r require either <svc-sha> or 'all' keyword"; exit -1; }; }
    ((opt_r || opt_s)) && { [[ $1 == all ]] && DKR_LST=$(docker ps -a | grep -v CREATED | awk '{print $1}'); }
    # stop kills container proc, but FS is kept, you can do docker commit w/ it
    ((opt_r || opt_s)) && { [[ $1 != all ]] && docker_stop $1 || docker_stop_all; bail; }
    # rm removes FS, but requires container to have stopped first
    ((opt_r)) && { [[ $1 != all ]] && docker rm $1 || docker_rm_all; bail; }
    # docker compose down $* - Also deletes n/w, images, volumes, along w/ FS
    ((opt_t)) && { docker attach $@; bail; }
    ((opt_h)) && { usage; }

    exit 0;
}

if [ "dc.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
