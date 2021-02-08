#!/bin/bash
#  DETAILS: ubuntu quirks and it's remedies
#  CREATED: 04/05/18 10:34:37 PDT
# MODIFIED: 08/May/2020 16:49:04 IST
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

function list_serial_dev()
{
    for sysdevpath in $(find /sys/bus/usb/devices/usb*/ -name dev); do
        (
            syspath="${sysdevpath%/dev}"
            devname="$(udevadm info -q name -p $syspath)"
            [[ "$devname" == "bus/"* ]] && continue
            eval "$(udevadm info -q property --export -p $syspath)"
            [[ -z "$ID_SERIAL" ]] && continue
            echo "/dev/$devname - $ID_SERIAL"
        )
    done
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

function kernel_build()
{
    # https://wiki.ubuntu.com/Kernel/SourceCode
    # https://wiki.ubuntu.com/Kernel/BuildYourOwnKernel
    # https://www.howtoforge.com/roll_a_kernel_debian_ubuntu_way
    # https://wiki.ubuntu.com/Debug%20Symbol%20Packages

    # Open sources.list and uncomment all relevant deb-src lines
    #sudo vim /etc/apt/sources.list
    sudo apt-get update
    sudo apt update

    # Download source code of kernel running currently on Ubuntu system
    apt-get source linux-image-$(uname -r)                  # signing code only
    apt-get source linux-image-unsigned-$(uname -r)         # actual source code

    # OR directly clone using git, but you still need release SHA from linux-image-$(uname -r)
    # git clone git://kernel.ubuntu.com/ubuntu/ubuntu-xenial.git
    # cd ubuntu-xenial && git checkout 6cac304f7f239ac

    # To build, the build dependencies need to be installed as well
    sudo apt-get build-dep linux linux-image-$(uname -r)    # this does not install all
    sudo apt-get install libncurses-dev flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf git

    # Install debug-sym (ddeb) packages
    echo "deb http://ddebs.ubuntu.com $(lsb_release -cs) main restricted universe multiverse
    deb http://ddebs.ubuntu.com $(lsb_release -cs)-updates main restricted universe multiverse
    deb http://ddebs.ubuntu.com $(lsb_release -cs)-proposed main restricted universe multiverse" | \
    sudo tee -a /etc/apt/sources.list.d/ddebs.list
    sudo apt install ubuntu-dbgsym-keyring
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F2EDC64DC5AEE1F6B9C621F0C8CAB6595FDFF622
    sudo apt-get update

    # Logs:
    # deb http://ddebs.ubuntu.com bionic main restricted universe multiverse
    # deb http://ddebs.ubuntu.com bionic-updates main restricted universe multiverse
    # deb http://ddebs.ubuntu.com bionic-proposed main restricted universe multiverse
    # $ sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys
    # F2EDC64DC5AEE1F6B9C621F0C8CAB6595FDFF622
    # Executing: /tmp/apt-key-gpghome.EfSBZUuvGE/gpg.1.sh --keyserver
    # keyserver.ubuntu.com --recv-keys F2EDC64DC5AEE1F6B9C621F0C8CAB6595FDFF622
    #
    # gpg: key C8CAB6595FDFF622: 5 signatures not checked due to missing keys
    # gpg: key C8CAB6595FDFF622: "Ubuntu Debug Symbol Archive Automatic Signing Key (2016) <ubuntu-archive@lists.ubuntu.com>" 3 new signatures
    # gpg: Total number processed: 1
    # gpg:         new signatures: 3#
    #
}

# use ssh -Y -v user@host for X11 forwarding. Do not use -X flag?? (does not matter)
function x11_fwd_on()
{
    sudo systemctl status sshd
    sudo echo "X11Forwarding yes" >> /etc/ssh/sshd_config
    sudo echo "X11UseLocalhost no" >> /etc/ssh/sshd_config
    sudo systemctl restart sshd
    sudo systemctl status sshd
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
    echo "  -s              - list all serial devices on laptop"
    echo "  -u              - unmount NFS with given inputs (-l)"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="hci:l:p:mrsu"
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
    ((opt_s)) && { list_serial_dev $*; }
    ((opt_u)) && { umount_nfs $LCL_PATH; }

    exit 0;
}

if [ "ubuntu.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
