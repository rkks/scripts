#!/bin/bash
#  DETAILS: Helper script for Vagrant
#  CREATED: 16/01/24 10:33:18 PM +0530
# MODIFIED: 28/05/24 10:15:10 PM IST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2024, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

#PATH="/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin:/sbin"

export VAGRANT_DEFAULT_PROVIDER=virtualbox
export VAGRANT_NO_PARALLEL=yes
export VAGRANT_LOG=warn
export VAGRANT_VAGRANTFILE=$(pwd)/Vagrantfile
VGT_OPTS="--color"

function run()
{
    # time cmd returns return value of child program. And time takes time as argument and still works fine
    [[ ! -z $TIMED_RUN ]] && { local HOW_LONG="time "; }
    [[ $(type -t "$1") == function ]] && { local fname=$1; shift; echo "$fname $*"; $HOW_LONG $fname "$*"; return $?; }
    local p; local a="$HOW_LONG"; for p in "$@"; do a="${a} \"${p}\""; done; test -z "$RUN_LOG" && { RUN_LOG=/dev/null; };
    echo "$a"; test -n "$DRY_RUN" && { return 0; } || eval "$a" 2>&1 | tee -a $RUN_LOG 2>&1; return ${PIPESTATUS[0]};
}

usage()
{
    echo "Usage: vagrant.sh [-h|-a|-c|-d|-e|-f|-g|-l|-r|-s|-t|-u|-v|-z]"
    echo "Options:"
    echo "  -h          - print this help"
    echo "  -a          - display vagrant status (use -f option)"
    echo "  -b          - list all vagrant boxes available"
    echo "  -c          - display vagrant ssh config (use -f option)"
    echo "  -d          - destroy given VM (use -v option)"
    echo "  -e          - check Vagrantfile for any errors (use -f option)"
    echo "  -f <fpath>  - relative path of Vagrantfile"
    echo "  -g          - show vagrant global-status (use -v option)"
    echo "  -l          - enable debug logging of vagrant op"
    echo "  -r          - reload guest VM applying Vagrantfile again (use -v option)"
    echo "  -s          - ssh into guest VM (use -v option)"
    echo "  -t          - halt given VM (use -v option)"
    echo "  -u          - do vagrant up (use -f option)"
    echo "  -v <vm-sha> - SHA of VM to perform ops on"
    echo "  -z          - dry run this script"
    echo "-f input is must for -a|-c|-u, use either -v or -f input for the rest"
    echo "log-lvl: info(-v)/debug(-vv), warn/error(quiet)"
    return 0;
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="habcdef:gl:rstuv:z"
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
    ((opt_f)) && { export VAGRANT_VAGRANTFILE=$optarg_f; }
    ((opt_l)) && { export VAGRANT_LOG=$optarg_l; }  # override vgtenv
    ((opt_v)) && { VM_NAME=$optarg_v; }
    ((opt_b)) && { run vagrant $VGT_OPTS box list; }
    ((opt_e)) && { run vagrant $VGT_OPTS validate; }
    ((opt_r)) && { run vagrant $VGT_OPTS reload --provision $VM_NAME; } # VM_NAME is optional
    ((opt_s)) && { run vagrant $VGT_OPTS ssh $VM_NAME; }
    ((opt_t)) && { run vagrant $VGT_OPTS halt $VM_NAME; }
    ((opt_d)) && { run vagrant $VGT_OPTS destroy -f $VM_NAME; GS_OPTS="--prune"; } # -f optional
    ((opt_g)) && { run vagrant $VGT_OPTS global-status $GS_OPTS $VM_NAME; } # VM_NAME is optional
    ((opt_a || opt_u)) && { [[ ! -e $VAGRANT_VAGRANTFILE ]] && echo "Input valid -f <vagrantfile-path>" && exit $EINVAL; }
    [[ -f "$(dirname $VAGRANT_VAGRANTFILE)/vgtenv" ]] && { source "$(dirname $VAGRANT_VAGRANTFILE)/vgtenv"; } # override default
    ((opt_u)) && { run vagrant $VGT_OPTS up; }    # no need of --debug option, $VAGRANT_LOG set
    ((opt_a)) && { run vagrant $VGT_OPTS status; }
    ((opt_c)) && { run vagrant $VGT_OPTS ssh-config; }
    ((opt_h)) && { usage; }
    unset VAGRANT_LOG;

    exit 0;
}

if [ "vagrant.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
