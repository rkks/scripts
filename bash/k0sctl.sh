#!/bin/bash
#  DETAILS: k0sctl helper script 
#  CREATED: 28/05/24 05:25:23 PM IST IST
# MODIFIED: 29/05/24 03:37:23 PM IST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2024, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

PATH="/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin:/sbin"

[[ "$(basename k0sctl.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

usage()
{
    echo "Usage: k0sctl.sh [-h|]"
    echo "Options:"
    echo "  -h              - print this help"
    echo "  -c <cfg-path>   - relative/absolute path to k0sctl config"
    echo "  -k              - dump kubeconfig of given (-c) k0sctl config"
    echo "  -s              - start cluster with given (-c) k0sctl config"
    echo "  -t              - teardown cluster with given (-c) k0sctl config"
    echo "  -z              - dry run this script"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="hc:kstz"
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
    ((opt_c)) && { K0SCTL_CFG=$optarg_c; }
    ((opt_t)) && { k0sctl reset --config $K0SCTL_CFG; echo "Run rm -rf /var/lib/kubelet on all nodes, reboot them"; }
    ((opt_s)) && { k0sctl apply --config $K0SCTL_CFG; }
    ((opt_k)) && { k0sctl kubeconfig --config $K0SCTL_CFG; }
    ((opt_h)) && { usage; }

    exit 0;
}

if [ "k0sctl.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
