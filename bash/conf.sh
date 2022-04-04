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
UNAMES=$(uname -s)      # machine type: Linux, FreeBSD, Darwin, SunOS
UBUNTU_OS=$(uname -v | grep -i ubuntu | wc -l)  # distro: ubuntu, fedora

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

    local CONFS="elinks links vim"
    CONFS+=" alias bashrc bash_profile bash_logout profile shrc"
    CONFS+=" login login_conf cshrc Xdefaults"
    CONFS+=" cvsignore cvspass svnignore gitignore gitattributes gitconfig"
    CONFS+=" mailrc pinerc screenrc toprc tmux.conf gvimrc vimrc indent.pro"
    CONFS+=" cookies mail_aliases rhosts gdbinit hushlogin"

    link_files DOT $HOME/conf $HOME $CONFS
    link_files DOT $HOME/conf/custom $HOME bashrc.dev
    link_files REG $HOME/conf/vnc $HOME/.vnc xstartup xstartup_safe

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

install_virt()
{
    # qemu - hw emulator, libvirt - VM manager, brctl - bridge mgmt
    # virtinst - cmdline tools for VM mgmt, virt-manager - GUI tool for VM mgmt
    VIRT_SW="qemu-kvm libvirt-bin bridge-utils virtinst virt-manager"
    sudo apt install -y $VIRT_SW &&
    sudo usermod -aG libvirt $USER && sudo usermod -aG kvm $USER && return $?;
}

install_tools()
{
    [[ $# -eq 0 ]] && { echo "Usage: $FUNCNAME <dev|lap|svr>"; return $EINVAL; }
    [[ "$UNAMES" != "Linux" ]] && { echo "$FUNCNAME: Only linux supported"; return $EINVAL; }
    [[ $UBUNTU_OS -eq 0 ]] && { echo "$FUNCNAME: Only ubuntu supported"; return $EINVAL; }

    # Tried & junked: libcharon-standard-plugins libstrongswan-extra-plugins
    # resolvconf wpasupplicant
    # extra: openvpn kmplayer audacious vnc4server
    # python-is-python3 python3-pip libxmlsec1-dev jq dnsniff tcpkill
    # sudo apt install auditd   # To monitor which proc is modifying given file

    # common development tools
    local UBUNTU_DEV_SW="git exuberant-ctags cscope vim autocutsel tmux expect"
    UBUNTU_DEV_SW+=" fortune-mod cowsay toilet p7zip-full ifupdown net-tools"

    # common laptop software
    local UBUNTU_LAP_SW="strongswan libcharon-extra-plugins strongswan-swanctl"
    UBUNTU_LAP_SW+=" minicom dnsmasq pptp-linux wireshark openfortivpn gpaint"
    UBUNTU_LAP_SW+=" ttf-mscorefonts-installer ubuntu-restricted-extras"
    UBUNTU_LAP_SW+=" libavcodec-extra vlc"

    # common server software
    UBUNTU_SVR_SW="vagrant ansible"

    sudo apt-get update; local ret=$?; [[ $ret -eq 0 ]] && return $EPERM;
    #sudo add-apt-repository "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) main universe";
    case
    'dev')
        sudo apt-get install -y $UBUNTU_DEV_SW;
        ;;
    'lap')
        sudo apt-get install -y $UBUNTU_LAP_SW;
        ;;
    'svr')
        install_virt && sudo apt-get install -y $UBUNTU_SVR_SW;
        ;;
    *)
        echo "Invalid input $*";
        ;;
    esac
    return $?;
}

stop_cron()
{
    echo "Configuring Cron - Stop"
    $HOME/scripts/bin/cron.sh -l -t
    echo "Configuring Cron - Done"
}

start_cron()
{
    echo "Configuring Cron - Start"
    $HOME/scripts/bin/cron.sh -l -s $HOME/conf/custom/crontab
    $HOME/scripts/bin/cron.sh -l
    echo "Configuring Cron - Done"
}

pull_github()
{
    [[ $# -ne 1 ]] && { echo "usage: pull_github <repo-name>"; return; }
    git clone https://github.com/rkks/$1.git
    cd $1 && git remote set-url origin git@github.com:rkks/$1.git && cd -
}

pull_conf()
{
    pull_github conf;
    pull_github scripts;
}

pull_extra()
{
    pull_github rkks.github.io;
    pull_github wiki;
    pull_github notes;
    pull_github refer;
}

function usage()
{
    echo "Usage: conf.sh <-a|-c|-h|-l|-n|-s|-t>"
    echo "Options:"
    echo "  -c              - start cron job of user"
    echo "  -i [dev|lap|svr]- install tools on ubuntu"
    echo "  -l              - create scripts log directory"
    echo "  -n              - create symlink of conf files"
    echo "  -p              - pull conf, scripts from github"
    echo "  -s              - create symlink of scripts"
    echo "  -t              - stop cron job of user"
    echo "  -h              - print this help message"
    echo "NOTE: to do everything and start cron (-cilnst)"
}

main()
{
    PARSE_OPTS="hcilnpst"
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

    ((opt_p)) && pull_conf;
    ((opt_n)) && link_confs;
    # Do not link any files: bash_history gdb_history history lesshst
    ((opt_l)) && mkdir -pv $HOME/.logs;
    ((opt_s)) && link_scripts;
    ((opt_i)) && install_tools $*;
    ((opt_t)) && stop_cron;
    ((opt_c)) && start_cron;
    ((opt_h)) && { usage; }

    exit 0
}

if [ "$(basename -- $0)" == "$(basename conf.sh)" ]; then
    main $*
fi

