#!/usr/bin/env bash
#===============================================================================
#
#          FILE:  conf.sh
#
#         USAGE:  ./conf.sh
#
#   DESCRIPTION:  Link all the configuration files to appropriate places.
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Ravikiran K.S (ravikirandotks@gmail.com)
#       VERSION:  1.0
#       CREATED:  11/08/11 18:15:05 PST
#===============================================================================

#set -uvx               # Treat unset variables as an error, verbose, debug mode

# .bashrc.dev not sourced as it creates cyclic dependencies during first time setting up of environment.
UNAMES=$(uname -s)      # OS name: Linux, FreeBSD, Darwin, SunOS. $(uname -v | grep -i ubuntu)
DISTRO_NM=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')  # distro: ubuntu, fedora
DISTRO_VER=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g') # 20.04, 18.04
VGT_PROVIDER=vbox

function apt_clean() { sudo rm -rf /var/lib/apt/lists/*; unset APT_UPDATED; return 0; }

function apt_update()
{
    sudo apt update && APT_UPDATED=1 || return -1; return 0;
}

# Expects NOPASSWD sudo
function apt_install()
{
    [[ -z $APT_UPDATED ]] && { apt_update || return -1; }
    sudo apt install -y --no-install-recommends --no-install-suggests $@; return $?;
}

function apt_upd_install()
{
    apt_update && apt_install $@; return $?;
}

function link_files()
{
    [[ $# -lt 3 ]] && { echo "Usage: link_files <flag> <src-dir> <dst-dir> [files-list]"; echo "  flag = DOT|NORMAL"; return; }

    local FLAG=$1; shift; local SRC_DIR=$1; shift; local DST_DIR=$1; shift;
    #[[ ! -d $SRC_DIR ]] && { echo "[ERROR] src: $SRC_DIR doesnt exist"; exit 1; }
    [[ ! -d $DST_DIR ]] && { echo "[INFO] dst: $DST_DIR doesnt exist. Creating new one."; mkdir -p $DST_DIR; }
    if [ $# -eq 3 ]; then
        cd $SRC_DIR || { echo "Unable to change directory to $SRC_DIR"; exit 1; }
        local FILES=$(find -P . -maxdepth 1 ! -path . -type f -name \* | sed 's/..//');
        local DIRS=$(find -P . -maxdepth 1 ! -path . -type d -name \* | sed 's/..//');
        local LIST="$DIRS $FILES";
    else
        local LIST="$*";
    fi
    for item in $LIST; do
        [[ ! -e $SRC_DIR/$item || -h "$SRC_DIR/$item" ]] && { echo "$SRC_DIR/$item not found or symlink"; continue; }
        [[ "$FLAG" == "DOT" ]] && { dst=.$item; } || { dst=$item; }
        [[ -h "$DST_DIR/$dst" ]] && { echo "Unlink symlink $DST_DIR/$dst"; unlink $DST_DIR/$dst; }
        [[ -e "$DST_DIR/$dst" ]] && { mkdir -p ~/tdir; echo "Move $DST_DIR/$dst => ~/tdir/"; mv $DST_DIR/$dst ~/tdir/; }
        [[ ! -e "$DST_DIR/$dst" ]] && { echo "Link $SRC_DIR/$item => $DST_DIR/$dst"; ln -s $SRC_DIR/$item $DST_DIR/$dst; }
    done
}

# Don't link: diffexclude rsyncexclude tarexclude dir_colors_dark/light
# downlinks doxygen.cfg gdb_history logrotate.conf
# Latest Ubuntu does not need ~/.xprofile, Solaris hangs with ~/Xdefaults file.
link_confs()
{
    echo "Linking Configuration Files/Directories - Start"

    # screenrc: deprecated, moved to tmux, does not work for console access
    local CONFS="vim gvimrc vimrc"
    CONFS+=" alias bashrc bash_profile bash_logout profile shrc cshrc"
    CONFS+=" login login_conf hushlogin toprc tmux.conf"
    CONFS+=" gitignore gitattributes gitconfig indent.pro gdbinit"
    #CONFS+=" elinks links cvsignore cvspass svnignore mailrc pinerc screenrc "
    #CONFS+=" Xdefaults cookies mail_aliases rhosts"

    link_files DOT $HOME/conf $HOME $CONFS
    link_files DOT $HOME/conf/custom $HOME bashrc.dev backup
    link_files REG $HOME/conf/vnc $HOME/.vnc xstartup xstartup_safe
    link_files REG $HOME/conf/ssh $HOME/.ssh config README

    echo "Linking Configuration Files/Directories - Done"
}

link_scripts()
{
    [[ ! -d ~/scripts ]] && { echo "$HOME/scripts doesnt exist."; return; }

    echo "Linking Script Files - Start"

    [[ ! -d ~/scripts/bin ]] && { mkdir -p ~/scripts/bin; }

    local SCRIPTS="awk bash expect perl";
    SCRIPTS+=" down/bash down/perl down/python down/ruby"

    for dir in $SCRIPTS; do
        [ -d "$HOME/scripts/$dir" ] && link_files REG $HOME/scripts/$dir $HOME/scripts/bin $(cd $HOME/scripts/$dir/ && ls *)
    done

    echo "Linking Script Files - Done"
}

link_tools()
{
    [[ ! -d ~/tools ]] && { echo "$HOME/tools doesnt exist."; return; }

    echo "Linking Tool binary Files - Start"

    [[ ! -d ~/tools/$UNAMES/bin ]] && mkdir -p ~/tools/$UNAMES/bin;

    # autoconf, automake, sloccount, splint, global, gmake, lighttpd, ncdu,
    # 7za, rsync, tmux, vim, doxygen, strace, resin (web-svr), javac, rsnapshot
    local tool;
    local COMMON_TOOLS=" "
    for tool in $COMMON_TOOLS; do
        ln -s $HOME/tools/$UNAMES/$tool $HOME/tools/$UNAMES/bin/;
    done

    if [ "$UNAMES" == "Linux" ]; then
        local LINUX_TOOLS=" "
        for tool in $LINUX_TOOLS; do
            ln -s $HOME/tools/$UNAMES/$tool $HOME/tools/$UNAMES/bin/;
        done
    fi

    echo "Linking Tool binary Files - Done"
}

uninstall_vpp()
{
    # Searches give RE pattern in apt-cache & then deletes all matching pkgs
    sudo apt autoremove --purge -y "vpp*"
    sudo apt autoremove --purge -y "python3-vpp-api"
    # Clear GPG keyring & apt deb ppa pkg-src
    sudo rm -f /etc/apt/sources.list.d/fdio*.list /etc/apt/keyrings/fdio*.gpg
}

uninstall_vbox()
{
    sudo apt autoremove --purge -y "virtualbox*"; return $?;
}

uninstall_kvm()
{
    local VIRT_SW="qemu qemu-kvm libvirt-daemon libvirt-clients virtinst virt-manager"
    local VAGRANT_LIBVIRT_SW="libvirt-dev libvirt-daemon-system ruby-dev ruby-libvirt"
    sudo apt autoremove -y $VIRT_SW $VAGRANT_LIBVIRT_SW; return $?;
}

uninstall_vagrant()
{
    VGT_PLUGINS="vagrant-vbguest vagrant-cachier vagrant-docker-compose"
    vagrant plugin uninstall $VGT_PLUGINS && sudo apt autoremove --purge -y vagrant; return $?;
}

uninstall_docker()
{
    sudo systemctl disable docker.service containerd.service &&  \
    rm -f ~/.docker/cli-plugins/docker-compose && sudo apt autoremove docker*;
    return $?;
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

# https://www.dedoimedo.com/computers/virtualbox-kernel-driver-gcc-12.html
install_vbox()
{
    apt_install gcc-12 build-essential;    # mandatory to compile drivers locally
    # '| sudo apt-key add' is deprecated
    wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo gpg --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg --dearmor
    # sudo apt-add-repository does not work?
    local pkg_exists=$(cat /etc/apt/sources.list | grep virtualbox | wc -l)
    [[ $pkg_exists -eq 0 ]] && { echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" | sudo tee -a /etc/apt/sources.list; }
    apt_upd_install virtualbox-6.1; return $?; # sudo apt info virtualbox &&
    #apt_install virtualbox; return $?;
}

install_kvm()
{
    local ver=$(lsb_release -rs); local uver=${ver%.*};
    [[ $DISTRO_VER < 20.04 ]] && { echo "Ubuntu below 20.X not supported" && return $EINVAL; }
    # qemu - hw emulator, libvirt - VM manager. libvirt-bin in 18.04 & before.
    # virtinst - cmdline tools for VM mgmt, virt-manager - GUI tool for VM mgmt
    local VIRT_SW="qemu qemu-kvm libvirt-daemon libvirt-clients virtinst virt-manager bridge-utils"
    local VAGRANT_LIBVIRT_SW="libxslt-dev libxml2-dev zlib1g-dev libvirt-dev"
    VAGRANT_LIBVIRT_SW+=" libvirt-daemon-system ebtables dnsmasq-base jq"
    VAGRANT_LIBVIRT_SW+=" bridge-utils ruby-dev ruby-libvirt"
    #VAGRANT_LIBVIRT_SW+=" libguestfs-tools sshpass tree" # TODO: Check if needed
    apt_install $VIRT_SW $VAGRANT_LIBVIRT_SW && sudo usermod -aG libvirt $USER && sudo usermod -aG kvm $USER && \
    sudo systemctl enable libvirtd && sudo systemctl start libvirtd;
    # vagrant-libvirt plugin head is not stable, way too many dependencies
    #LIBVIRT_PLUGIN_VER=0.4.1
    #local exists=$(vagrant plugin list | grep $LIBVIRT_PLUGIN_VER | grep vagrant-libvirt)
    #[[ -z "$exists" ]] && vagrant plugin install vagrant-libvirt --plugin-version=$LIBVIRT_PLUGIN_VER
    return $?;
}

install_vagrant()
{
    #Old: curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    #Old, Does not work: sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    #Old, You can directly install by URL: apt_install https://releases.hashicorp.com/vagrant/2.2.19/vagrant_2.2.19_x86_64.deb
    apt_update
    # Instead of plugin 'vagrant-scp', just copy file to Vagrantfile dir on Host & access through /vagrant dir on VM
    local VGT_PLUGINS="vagrant-vbguest vagrant-cachier vagrant-docker-compose"
    apt_install vagrant && vagrant plugin install $VGT_PLUGINS && \
    return $?;
}

# docker-ce comes pre-compiled w/ all dependent libs within. docker.io is stock
# debian w/ all libs external, independent. Keeps you safe from lib version hell
# https://stackoverflow.com/questions/45023363/what-is-docker-io-in-relation-to-docker-ce-and-docker-ee-now-called-mirantis-k
install_docker_ce()
{
    sudo apt remove docker docker-engine docker.io containerd runc
    apt_install ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt_upd_install docker-ce docker-ce-cli containerd.io; return $?;
}

install_docker()
{
    # If group is already created by installer, do not stop proceed further.
    [[ $1 =~ *ce ]] && install_docker_ce || apt_install docker.io; [[ $? -ne 0 ]] && return $?;
    sudo groupadd docker; sudo usermod -aG docker $USER; sudo chmod 0660 /var/run/docker.sock;
    sudo systemctl enable docker.service containerd.service &&  \
    [[ ! -f ~/.docker/cli-plugins/docker-compose ]] && mkdir -p ~/.docker/cli-plugins/ &&   \
    curl -SL https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-linux-x86_64 \
    -o ~/.docker/cli-plugins/docker-compose && chmod +x ~/.docker/cli-plugins/docker-compose;
    return $?;
}

install_containerlab()
{
    sudo bash -c "$(curl -sL https://get.containerlab.dev)"
    #echo "deb [trusted=yes] https://apt.fury.io/netdevops/ /" | sudo tee -a /etc/apt/sources.list.d/netdevops.list
    ## Log out, Log back in, Run 'netlab test clab'
    #apt_upd_install containerlab
}

install_tools()
{
    [[ $# -eq 0 ]] && { local mode=dev; } || { local mode=$1; }
    [[ "$UNAMES" != "Linux" ]] && { echo "$FUNCNAME: Only linux supported"; return $EINVAL; }
    [[ $DISTRO_NM != "ubuntu" ]] && { echo "$FUNCNAME: Only ubuntu supported"; return $EINVAL; }
    [[ $DISTRO_VER < 18.04 ]] && { echo "$FUNCNAME: Only Ubuntu18.04 or above supported"; return $EINVAL; }

    # Tried & junked: libcharon-standard-plugins libstrongswan-extra-plugins
    # resolvconf wpasupplicant
    # apt_install auditd   # To monitor which proc is modifying given file

    # common development tools
    local UBUNTU_DEV_SW="git exuberant-ctags cscope vim autocutsel tmux expect"
    UBUNTU_DEV_SW+=" fortune-mod cowsay toilet ifupdown net-tools dnsmasq twm"
    UBUNTU_DEV_SW+=" finger cifs-utils openssh-server"
    #UBUNTU_DEV_SW+=" bpftrace dnsniff tcpkill ss sysstat auditd ifenslave"

    # common laptop software
    local UBUNTU_LAP_SW="strongswan libcharon-extra-plugins strongswan-swanctl"
    UBUNTU_LAP_SW+=" minicom pptp-linux wireshark gpaint p7zip-full wakeonlan"
    UBUNTU_LAP_SW+=" ttf-mscorefonts-installer ubuntu-restricted-extras"
    UBUNTU_LAP_SW+=" numlockx asciinema pandoc texlive-latex-recommended"
    #UBUNTU_LAP_SW+=" libavcodec-extra vlc audacious openfortivpn kmplayer"
    #UBUNTU_LAP_SW+=" vnc4server"

    # common server software. NOTE: ansible is buggy, use it?
    UBUNTU_SVR_SW="bridge-utils"
    #UBUNTU_SVR_SW+=" openvswitch-switch virtualbox vagrant openvpn"

    UBUNTU_PYTHON_DEV="python-is-python3 python3-pip "
    UBUNTU_WEB_DEV="libxmlsec1-dev jq"

    sudo apt update; local ret=$?; [[ $ret -ne 0 ]] && return $EPERM;
    #sudo add-apt-repository "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) main universe";
    case $mode in
    dev)
        apt_install $UBUNTU_DEV_SW;
        ;;
    lap)
        apt_install $UBUNTU_LAP_SW;
        ;;
    svr)
        apt_install $UBUNTU_SVR_SW;
        ;;
    dkr)
        install_docker;
        ;;
    kvm)
        # when Docker has out-of-box isolation, packaging, migration & registry,
        # unless a workload needs OS isolation, no need of KVM/libvirt overhead
        install_kvm;
        ;;
    vbox)
        install_vbox;
        ;;
    vgt)
        # vagrant natively supports only virtualbox. kvm plugin does not work.
        # virtualbox is slow, buggy, cumbersome. If you must, use KVM instead.
        install_vagrant;
        ;;
    vpp)
        install_vpp;
        ;;
    *)
        echo "Invalid input $*";
        ;;
    esac
    return $?;
}

uninstall_tools()
{
    case $1 in
    dev)
        sudo apt autoremove -y $UBUNTU_DEV_SW;
        ;;
    lap)
        sudo apt autoremove -y $UBUNTU_LAP_SW;
        ;;
    svr)
        sudo apt autoremove -y $UBUNTU_SVR_SW;
        ;;
    dkr)
        uninstall_docker;
        ;;
    kvm)
        # when Docker has out-of-box isolation, packaging, migration & registry,
        # unless a workload needs OS isolation, no need of KVM/libvirt overhead
        uninstall_kvm;
        ;;
    vbox)
        uninstall_vbox;
        ;;
    vgt)
        # vagrant natively supports only virtualbox. kvm plugin does not work.
        # virtualbox is slow, buggy, cumbersome. If you must, use KVM instead.
        uninstall_vagrant;
        ;;
    vpp)
        uninstall_vpp;
        ;;
    *)
        echo "Invalid input $*";
        ;;
    esac
}

stop_cron()
{
    local tmpfile=$(mktemp)
    $HOME/scripts/bin/cron.sh -l > $tmpfile
    $HOME/scripts/bin/cron.sh -t
    echo "Stop Cron - Existing contents saved into $tmpfile"
}

start_cron()
{
    local tmpfile=$(mktemp)
    $HOME/scripts/bin/cron.sh -l > $tmpfile
    cat $HOME/conf/custom/crontab >> $tmpfile
    $HOME/scripts/bin/cron.sh -s $tmpfile
    echo "Started Cron w/ content"
    cat $tmpfile && rm -f $tmpfile
}

pull_github()
{
    [[ $# -ne 1 ]] && { echo "usage: pull_github <repo-name>"; return; }
    git clone https://github.com/rkks/$1.git
    cd $1 && git remote set-url origin git@github.com:rkks/$1.git && cd -
}

pull_repo()
{
    case $1 in
    extra)
        pull_github rkks.github.io;
        pull_github wiki;
        pull_github notes;
        pull_github refer;
        ;;
    *)
        pull_github conf;
        pull_github scripts;
        ;;
    esac
}

function usage()
{
    echo "Usage: conf.sh <-a|-c|-h|-l|-n|-s|-t>"
    echo "Options:"
    echo "  -h              - print this help message"
    echo "  -c              - start cron job of user"
    echo "  -i <pkg-sets>   - install tools on ubuntu"
    echo "  -l              - create scripts log directory"
    echo "  -n              - create symlink of conf files"
    echo "  -p              - pull conf/scripts repos from github"
    echo "  -s              - create symlink of scripts"
    echo "  -t              - stop cron job of user"
    echo "  -u <pkg-sets>   - uninstall tools from system"
    echo "  -z              - dry run this script"
    echo "pkg-sets: dev|lap|svr|vbox|kvm|dkr|vpp|vgt"
    echo "NOTE: to do everything and start cron (-cilnst)"
}

main()
{
    PARSE_OPTS="hci:lnpstu:"
    local opts_found=0
    while getopts ":$PARSE_OPTS" opt; do
        case $opt in
            [a-zA-Z0-9])
                #echo "-$opt was triggered, Parameter: $OPTARG"
                local "opt_$opt"=1 && local "optarg_$opt"="$OPTARG"
                ;;
            \?)
                echo "Invalid option: -$OPTARG"; usage; exit $EINVAL;
                ;;
            :)
                echo "[ERROR] Option -$OPTARG requires an argument";
                usage; exit $EINVAL;
                ;;
        esac
        shift $((OPTIND-1)) && OPTIND=1 && local opts_found=1;
    done

    if ((!opts_found)); then
        usage && exit $EINVAL;
    fi

    ((opt_z)) && { DRY_RUN=1; LOG_TTY=1; }
    ((opt_u)) && uninstall_tools $optarg_u;
    ((opt_i)) && install_tools $optarg_i;
    ((opt_p)) && pull_repo $*;
    ((opt_n)) && link_confs;
    # Do not link any files: bash_history gdb_history history lesshst
    ((opt_l)) && mkdir -pv $HOME/.logs;
    ((opt_s)) && link_scripts;
    ((opt_t)) && stop_cron;
    ((opt_c)) && start_cron;
    ((opt_h)) && { usage; }

    exit 0
}

if [ "$(basename -- $0)" == "$(basename conf.sh)" ]; then
    main $*
fi
