#!/bin/bash
#  DETAILS: Helper script for Vagrant
#  CREATED: 16/01/24 10:33:18 PM +0530
# MODIFIED: 18/01/24 06:47:10 PM +0530
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2024, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

PATH="/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin:/sbin"

export VAGRANT_DEFAULT_PROVIDER=virtualbox
VGTENV=vgtenv

usage()
{
    echo "Usage: vagrant.sh [-h|-d|-g|-l|-p|-t|-u|-v|-z]"
    echo "Options:"
    echo "  -h          - print this help"
    echo "  -d          - destroy given VM (use -v option)"
    echo "  -g          - show vagrant global status"
    echo "  -l          - enable debug logging of vagrant op"
    echo "  -s          - ssh into guest VM (use -v option)"
    echo "  -t          - halt given VM (use -v option)"
    echo "  -u          - do vagrant up"
    echo "  -v <vm-sha> - SHA of VM to perform ops on"
    echo "  -z          - dry run this script"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="hdglstuv:z"
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

    [[ -f $VGTENV ]] && { source $VGTENV; } # cd $(dirname $0);
    ((opt_z)) && { DRY_RUN=1; LOG_TTY=1; }
    ((opt_l)) && { export VAGRANT_LOG=info; }
    ((opt_v)) && { VM_NAME=$optarg_v; }
    ((opt_d || opt_t)) && { [[ -z $VM_NAME ]] && usage; }
    ((opt_t)) && { vagrant halt $VM_NAME; }
    ((opt_d)) && { vagrant destroy $VM_NAME; }
    ((opt_u)) && { vagrant up; }
    ((opt_g)) && { vagrant global-status; }
    ((opt_u)) && { vagrant ssh $VM_NAME; }
    ((opt_h)) && { usage; }
    unset VAGRANT_LOG;

    exit 0;
}

if [ "vagrant.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
