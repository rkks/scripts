#!/bin/bash
#  DETAILS: ubuntu quirks and it's remedies
#  CREATED: 04/05/18 10:34:37 PDT
# MODIFIED: 08/09/24 03:20:47 PM IST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2018, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

PATH=/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin

[[ "$(basename ubuntu.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

function create_user()
{
    sudo adduser $1;
    sudo usermod -aG sudo $1;
}

function delete_user()
{
    sudo deluser $1;
}

function modify_username()
{
    # You can not modify username & home dir while being logged in as the user.
    # Enable root login, then login as root and perform these operations.
    # sudo passwd root          # set passwd for root
    # sudo passwd -u root       # enable root login
    [[ $# -ne 2 ]] && { echo "Usage: $FUNCNAME <oldusername> <newusername>"; return $EINVAL; }
    # home directory rename does not need permissions change because file perms
    # are attached to user UID, not name. And UID remains same.
    usermod -l $2 -d /home/$2 -m $1;
    groupmod -n $2 $1;
    passwd $2   # modify passwd for new user
    #newgrp $2  # ex, 'newgrp docker' to enable new group in current shell
    # Disable root login now by
    # sudo passwd -l root
}

function enable_router()
{
    # For sysctl issues check hacks/ubuntu.md
    sudo sysctl -w net.ipv4.ip_forward=1
    # Below is topology. Create 2 route-tables, one for each ISP
    # LAN: eth0: 192.168.0.1/24
    # ISP1: eth1: 192.168.1.1/24, gateway: 192.168.1.2/24
    # ISP2: eth2: 192.168.2.1/24, gateway: 192.168.2.2/24
    echo "10 ISP1" | sudo tee -a /etc/iproute2/rt_tables
    echo "20 ISP2" | sudo tee -a /etc/iproute2/rt_tables
    sudo ip route show table main | grep -Ev '^default' | \
    while read ROUTE ; do
        sudo ip route add table ISP1 $ROUTE
    done
    # Default GW to respective ISPs
    sudo ip route add default via 192.168.1.2 table ISP1
    sudo ip route add default via 192.168.2.2 table ISP2
    # CONNMARK
    sudo iptables -t mangle -A PREROUTING -j CONNMARK --restore-mark
    sudo iptables -t mangle -A PREROUTING -m mark ! --mark 0 -j ACCEPT
    sudo iptables -t mangle -A PREROUTING -j MARK --set-mark 10
    sudo iptables -t mangle -A PREROUTING -m statistic --mode random --probability 0.5 -j MARK --set-mark 20
    sudo iptables -t mangle -A PREROUTING -j CONNMARK --save-mark
    # NATing
    sudo iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
    sudo iptables -t nat -A POSTROUTING -o eth2 -j MASQUERADE
    # Review all changes
    sudo iptables -L -v -n

    # To persist these changes, do:
    #echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf    # sysctl -p
}

function disable_router()
{
    sudo sysctl -w net.ipv4.ip_forward=0;
}

function dmi_decode_str()
{
    # list all serials
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

    local DMI_DECODE_FIELDS="bios-vendor bios-version bios-release-date system-manufacturer system-product-name system-version system-serial-number system-uuid baseboard-manufacturer baseboard-product-name baseboard-version baseboard-serial-number baseboard-asset-tag chassis-manufacturer chassis-type chassis-version chassis-serial-number chassis-asset-tag processor-family processor-manufacturer processor-version processor-frequency";
    local s;
    for s in $DMI_DECODE_FIELDS;
        do echo "$s: $(sudo dmidecode -s $s)";
    done;
}

function systemd_strongswan()
{
    sudo systemctl enable ipsec
    sudo systemctl status ipsec
}

function add_systemd_svc()
{
    [[ $# -ne 2 ]] && { echo "Usage: $FUNCNAME <svc-name> <svc-file-dir>"; return $EINVAL; }
    [[ ! -f "$2/$1@service" ]] && { echo "Unable to find $2/$1@service"; return $EINVAL; }

    # Sample template: ~/conf/ubuntu/etc/systemd/system/vncserver@.service
    sudo cp "$2/$1@.service" /etc/systemd/system/ &&
    sudo systemctl daemon-reload && sudo systemctl enable "$1@1.service" &&
    sudo systemctl start "$1@1.service" && sudo systemctl status "$1@1.service"
    journalctl -xe     # to debug issues
    journalctl -xeu $1.service
    #sudo echo VNCSERVERS=1:$USER > /etc/default/vncserver  # does not work
    #sudo update-rc.d vncserver defaults        # if needed
}

function disable_systemd_svc()
{
    [[ $# -ne 1 ]] && { echo "Usage: $FUNCNAME <svc-name>"; return $EINVAL; }
    sudo systemctl status $1; sudo systemctl stop $1 && sudo systemctl disable --now $1 && sudo systemctl mask $1 && sudo systemctl status $1;
}

function enable_systemd_svc()
{
    [[ $# -ne 1 ]] && { echo "Usage: $FUNCNAME <svc-name>"; return $EINVAL; }
    sudo systemctl status $1; sudo systemctl unmask $1 && sudo systemctl enable --now $1 && sudo systemctl restart $1 && sudo systemctl status $1;
}

function disable_netplan()
{
    # resolvconf is not used, as dns server is not static, it changes based on
    # whether laptop is connected to vpn or not. /etc/systemd/resolved.conf

    # check if pkg installed. user must update cfg like /etc/network/interfaces
    local pkgs="ifupdown dnsmasq";
    for pkg in "$pkgs"; do
        sudo dpkg -V $pkg;
        [[ $? -ne 0 ]] && { echo "pkg $pkg not installed"; return $EINVAL; }
    done
    enable_systemd_svc networking;
    local svcs="systemd-networkd.socket systemd-networkd networkd-dispatcher"
    svcs+=" systemd-networkd-wait-online systemd-resolved resolvconf.service"
    svcs+=" rdnssd.service"
    local svc;
    for svc in $svcs; do
        disable_systemd_svc $svc;
    done
    sudo systemctl disable NetworkManager-wait-online.service
    #sudo ifdown --force -a && sudo ifup -a
    #sudo invoke-rc.d dnsmasq restart
}

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
    echo "NA";
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

# https://help.ubuntu.com/community/UbuntuBonding
# https://www.ibm.com/docs/en/linux-on-systems?topic=recommendations-bonding-modes
# https://www.cyberciti.biz/faq/ubuntu-linux-bridging-and-bonding-setup/
bond_create()
{
    echo "bonding" | sudo tee -a /etc/modules;
    sudo stop networking
    sudo modprobe bonding
}

usage()
{
    echo "Usage: ubuntu.sh [-h|]"
    echo "Options:"
    echo "  -h              - print this help"
    echo "  -a <user-name>  - add sudo user with given name"
    echo "  -c              - cleanup apt install cache, broken links"
    echo "  -d <user-name>  - delete user with given name"
    echo "  -e              - laptop serial number (DMI) details"
    echo "  -i <nfs-ip>     - NFS server IP-addr/FQDN"
    echo "  -l <lcl-path>   - local path for NFS mount"
    echo "  -m              - mount NFS with given inputs (-i,-l,-p)"
    echo "  -n              - disable netplan, re-enable ifupdown, dns"
    echo "  -p <nfs-path>   - path on NFS server for NFS mount"
    echo "  -q <svc-name>   - enable systemd service of given name"
    echo "  -r <svc-name>   - disable systemd service of given name"
    echo "  -s              - list all serial devices on laptop"
    echo "  -u              - unmount NFS with given inputs (-l)"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="ha:cd:ei:l:mnp:q:r:su"
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
    ((opt_a)) && { create_user $optarg_a; }
    ((opt_d)) && { sudo deluser $optarg_d; }
    ((opt_c)) && { apt_cleanup $*; }
    ((opt_e)) && { dmi_decode_str; }
    ((opt_i)) && { NFS_IP=$optarg_i; }
    ((opt_l)) && { LCL_PATH=$optarg_l; }
    ((opt_p)) && { NFS_PATH=$optarg_p; }
    ((opt_m)) && { mount_nfs $NFS_IP $NFS_PATH $LCL_PATH; }
    ((opt_n)) && { disable_netplan; }
    ((opt_q)) && { enable_systemd_svc $optarg_q; }
    ((opt_r)) && { disable_systemd_svc $optarg_r; }
    ((opt_s)) && { list_serial_dev $*; }
    ((opt_u)) && { umount_nfs $LCL_PATH; }

    exit 0;
}

if [ "ubuntu.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
