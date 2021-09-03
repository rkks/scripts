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

function create_user()
{
    sudo adduser $1;
    sudo usermod -aG sudo $1;
}

function delete_user()
{
    sudo deluser $1;
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

# Don't link: diffexclude rsyncexclude tarexclude dir_colors_dark/light downlinks doxygen.cfg gdb_history logrotate.conf
# Not applicable for all machines. Solaris hangs with this file. Xdefaults
link_confs()
{
    echo "Linking Configuration Files/Directories - Start"

    CONFS="elinks links vim"
    CONFS+=" alias bashrc bash_profile bash_logout cshrc login login_conf profile shrc"
    CONFS+=" cvsignore gitignore svnignore"
    CONFS+=" mailrc pinerc screenrc toprc gvimrc vimrc tmux.conf"
    CONFS+=" gdbinit gitattributes gitconfig indent.pro"
    CONFS+=" cookies cvspass mail_aliases rhosts"
    CONFS+=" hushlogin xprofile"

    link_files DOT $HOME/conf $HOME $CONFS
    link_files DOT $HOME/conf/custom $HOME bashrc.dev
    link_files REG $HOME/conf/vnc $HOME/.vnc xstartup xstartup_safe

    echo "Linking Configuration Files/Directories - Done"
}

# Do not link: bash_history gdb_history history lesshst
link_logs()
{
    echo "Linking Log Files/Directories - Start"

    LOGS=" "

    link_files DOT $HOME/.logs $HOME $LOGS

    echo "Linking Log Files/Directories - Done"
}

link_scripts()
{
    [[ ! -d ~/scripts ]] && { echo "$HOME/scripts doesnt exist."; return; }

    echo "Linking Script Files - Start"

    [[ ! -d ~/scripts/bin ]] && { mkdir -p ~/scripts/bin; }

    SCRIPTS="awk bash expect perl ruby"
    SCRIPTS+=" 3rd-party/bash 3rd-party/perl 3rd-party/python 3rd-party/ruby"

    for dir in $SCRIPTS; do
        [ -d "$HOME/scripts/$dir" ] && link_files REG $HOME/scripts/$dir $HOME/scripts/bin $(cd $HOME/scripts/$dir/ && ls *)
    done

    echo "Linking Script Files - Done"
}

link_tools()
{
    [[ ! -d ~/tools ]] && { echo "$HOME/tools doesnt exist."; return; }

    echo "Linking Tool binary Files - Start"

    [[ ! -d ~/tools/bin/linux ]] && mkdir -p ~/tools/bin/linux;
    [[ ! -d ~/tools/bin/freebsd ]] && mkdir -p ~/tools/bin/freebsd;

    COMMON_TOOLS="p7zip/bin/7za"
    COMMON_TOOLS+=" autoconf/bin/autoconf automake/bin/automake autoconf/bin/autoreconf"
    COMMON_TOOLS+=" cscope/bin/cscope ctags/bin/ctags"
    COMMON_TOOLS+=" git/bin/git sloccount/bin/sloccount splint/bin/splint"
    COMMON_TOOLS+=" global/bin/global global/bin/gtags global/bin/htags"
    COMMON_TOOLS+=" gmake/bin/make"
    COMMON_TOOLS+=" lighttpd/sbin/lighttpd"
    COMMON_TOOLS+=" ncdu/bin/ncdu rsync/bin/rsync tmux/bin/tmux"
    COMMON_TOOLS+=" vim/bin/vim vim/bin/vimdiff"
    for tool in $COMMON_TOOLS; do
        ln -s $HOME/tools/linux/$tool $HOME/tools/bin/linux/;
        ln -s $HOME/tools/freebsd/$tool $HOME/tools/bin/freebsd/;
    done

    LINUX_TOOLS=" doxygen/bin/doxygen strace/bin/strace resin/bin/resin.sh"
    LINUX_TOOLS+=" jdk/bin/java jdk/bin/javac resin/bin/resin.sh resin/bin/resinctl"
    for tool in $LINUX_TOOLS; do
        ln -s $HOME/tools/linux/$tool $HOME/tools/bin/linux/;
    done

    ln -s $HOME/tools/rsnapshot/bin/rsnapshot $HOME/tools/bin/
    ln -s $HOME/tools/rsnapshot/bin/rsnapshot-diff $HOME/tools/bin/

    echo "Linking Tool binary Files - Done"
}

stop_cron()
{
    echo "Configuring Cron - Stop"
    $HOME/scripts/bin/cron.sh -l
    $HOME/scripts/bin/cron.sh -t
    echo "Configuring Cron - Done"
}

start_cron()
{
    echo "Configuring Cron - Start"
    $HOME/scripts/bin/cron.sh -s $HOME/conf/custom/crontab
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

install_tools()
{
    sudo add-apt-repository "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) main universe";
    sudo apt-get update &&  \
    sudo apt-get install -y git exuberant-ctags vim toilet autocutsel cscope\
        fortune-mod cowsay toilet tmux net-tools ifupdown dnsmasq expect;
    #sudo apt install -y build-essential dnsniff tcpkill vnc4server;
    #sudo apt install -y auditd  # To monitor which process is modifying given file
    #sudo apt install -y python-is-python3 python3-pip build-essential minicom
    #sudo apt install -y ttf-mscorefonts-installer audacious openfortivpn p7zip-full
    #sudo apt install -y ubuntu-restricted-extras libavcodec-extra gpaint wireshark
    #sudo apt install -y strongswan libcharon-extra-plugins pptp-linux vlc kmplayer
    #openvpn resolvconf wpasupplicant libxmlsec1-dev jq
}

install_virt()
{
    # qemu - hw emulator, libvirt - VM manager, brctl - bridge mgmt
    # virtinst - cmdline tools for VM mgmt, virt-manager - GUI tool for VM mgmt
    sudo apt install qemu-kvm libvirt-bin bridge-utils virtinst virt-manager &&
    sudo usermod -aG libvirt $USER && sudo usermod -aG kvm $USER
}

function usage()
{
    echo "Usage: conf.sh <-a|-c|-h|-l|-n|-s|-t>"
    echo "Options:"
    echo "  -a - link all files and start cron (-clnst)"
    echo "  -c - start cron job of user"
    echo "  -d - delete cron job of user"
    echo "  -i - install all development tools on ubuntu"
    echo "  -l - create symlink of user log files"
    echo "  -n - create symlink of user conf files"
    echo "  -p - pull github dev setup files"
    echo "  -s - create symlink of user script files"
    echo "  -t - create symlink of user tool binaries"
    echo "  -u <username> - create user of given name"
    echo "  -v <username> - delete user of given name"
    echo "  -h - print this help message"
}

main()
{
    PARSE_OPTS="hacdilnpstu:v:"
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

    ((opt_a)) && (link_confs; link_logs; link_scripts; link_tools; install_tools; stop_cron; start_cron; exit 0)
    ((opt_n)) && link_confs
    ((opt_i)) && install_tools
    ((opt_l)) && link_logs
    ((opt_p)) && pull_conf
    ((opt_s)) && link_scripts
    ((opt_t)) && link_tools
    ((opt_c)) && start_cron
    ((opt_d)) && stop_cron
    ((opt_u)) && create_user $optarg_u
    ((opt_v)) && delete_user $optarg_v
    ((opt_h)) && (usage; exit 0)

    exit 0
}

if [ "$(basename -- $0)" == "$(basename conf.sh)" ]; then
    main $*
fi

