#!/bin/bash
#  DETAILS: Helper script for VPP install/testing
#  CREATED: 15/11/23 08:58:34 AM IST
# MODIFIED: 10/01/24 10:37:40 PM +0530 +0530
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2023, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

PATH="/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin:/sbin"

[[ "$(basename vpp.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

apt_clean()
{
    sudo rm -rf /var/lib/apt/lists/*; unset APT_UPDATED; return 0;
}

# Expects NOPASSWD sudo
apt_install()
{
    [[ -z $APT_UPDATED ]] && { sudo apt update && APT_UPDATED=1 || return -1; }
    sudo apt install -y --no-install-recommends $@;
    return $?;
}

install_vagrant()
{
    apt_install vagrant && vagrant plugin install vagrant-cachier; return $?;
}

install_vpp()
{
    apt_install curl
    # Setup apt repository to pull vpp debian pkgs. LTS pkgs are named YYMM (Ex: 23/10)
    # If script does not work, manual steps:
    # - Installs GPG keyring /etc/apt/keyrings/fdio_2310-archive-keyring.gpg
    # $ sudo apt-get install curl gnupg apt-transport-https
    # $ curl -fsSL https://packagecloud.io/fdio/2310/gpgkey > 2310-gpgkey
    # $ gpg --dearmor < 2310-gpgkey > fdio_2310-archive-keyring.gpg
    # $ sudo mv fdio_2310-archive-keyring.gpg /etc/apt/keyrings/fdio_2310-archive-keyring.gpg
    # - Install apt deb ppa pkg-src to https://packagecloud.io/fdio/2310/ubuntu
    # $ sudo vim /etc/apt/sources.list.d/fdio_2310.list
    # $ cat /etc/apt/sources.list.d/fdio_2310.list
    # deb [signed-by=/etc/apt/keyrings/fdio_2310-archive-keyring.gpg] https://packagecloud.io/fdio/2310/ubuntu jammy main
    # deb-src [signed-by=/etc/apt/keyrings/fdio_2310-archive-keyring.gpg] https://packagecloud.io/fdio/2310/ubuntu jammy main
    curl -s https://packagecloud.io/install/repositories/fdio/2310/script.deb.sh | sudo bash
    apt_install vpp vpp-plugin-core vpp-plugin-dpdk;    # core vpp packages
    # optional vpp packages
    apt_install python3-vpp-api vpp-dbg vpp-dev vpp-plugin-devtools
    apt_install vpp-ext-deps
    echo "Relevant configs & files installed"
    sudo ls -l /etc/apt/sources.list.d/fdio*.list /etc/apt/keyrings/fdio*.gpg
    cat /usr/lib/systemd/system/vpp.service
    # vpp installer creates new "vpp" usergroup, add current user & session to it
    sudo usermod -a -G vpp $(id -nu)
    newgrp vpp
}

uninstall_vpp()
{
    # Searches give RE pattern in apt-cache & then deletes all matching pkgs
    sudo apt autoremove --purge -y "vpp*"
    sudo apt autoremove --purge -y "python3-vpp-api"
    # Clear GPG keyring & apt deb ppa pkg-src
    sudo rm -f /etc/apt/sources.list.d/fdio*.list /etc/apt/keyrings/fdio*.gpg
}

usage()
{
    echo "Usage: vpp.sh [-h|]"
    echo "Options:"
    echo "  -h          - print this help"
    echo "  -i          - install VPP from packagecloud"
    echo "  -u          - uninstall all VPP packages from system"
    echo "  -v          - install vagrant and its dependencies"
    echo "  -z          - dry run this script"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="hiuvz"
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
    ((opt_i)) && { install_vpp; }
    ((opt_u)) && { uninstall_vpp; }
    ((opt_v)) && { install_vagrant; }
    ((opt_h)) && { usage; }

    exit 0;
}

if [ "vpp.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
