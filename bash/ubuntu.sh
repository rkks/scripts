#!/bin/bash
#  DETAILS: ubuntu quirks and it's remedies
#  CREATED: 04/05/18 10:34:37 PDT
# MODIFIED: 13/Aug/2018 22:01:33 IST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2018, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

PATH=/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin

[[ "$(basename ubuntu.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

function apt_cleanup()
{
    # remove third-party pkg repos, they cause problems
    sudo apt update
    sudo apt clean
    sudo apt autoclean
    sudo dpkg --get-selections > packages
    sudo dpkg --clear-selections
    sudo apt autoremove -f
    [[ $# -ne 0 ]] && { sudo dpkg --remove --force-remove-reinstreq $*; sudo apt-get install --force-reinstall true $*; }
}

function reinstall_unity()
{
    sudo apt-get autoremove
    sudo apt-get install unity
    sudo apt-get install --reinstall ubuntu-desktop
    sudo apt-get update
    rm -rf .compiz/
    rm -rf .config/
}

usage()
{
    echo "Usage: ubuntu.sh [-h|]"
    echo "Options:"
    echo "  -h              - print this help"
    echo "  -c              - cleanup apt install cache, broken links"
    echo "  -r              - reinstall unity"
    echo "  -i <nfs-ip>     - NFS server IP-addr/FQDN"
    echo "  -l <lcl-path>   - local path for NFS mount"
    echo "  -p <nfs-path>   - path on NFS server for NFS mount"
    echo "  -m              - mount NFS with given inputs (-i,-l,-p)"
    echo "  -u              - unmount NFS with given inputs (-l)"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="hci:l:p:mru"
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

    #[[ $EUID -ne 0 ]] && { die "This script must be run as sudo/root"; }
    ((opt_h)) && { usage; }
    ((opt_c)) && { apt_cleanup $*; }
    ((opt_i)) && { NFS_IP=$optarg_i; }
    ((opt_l)) && { LCL_PATH=$optarg_l; }
    ((opt_p)) && { NFS_PATH=$optarg_p; }
    ((opt_m)) && { mount_nfs $NFS_IP $NFS_PATH $LCL_PATH; }
    ((opt_r)) && { reinstall_unity $*; }
    ((opt_u)) && { umount_nfs $LCL_PATH; }

    exit 0;
}

if [ "ubuntu.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
