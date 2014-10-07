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

# .bashrc not sourced as it creates cyclic dependencies during first time setting up of environment.

link-files()
{
    args=$#
    if [ $args -le 3 ]; then
        echo "usage: link-files <flag> <src-dir> <dst-dir> <files-list>"
        echo "  flag = DOT|NORMAL"
        echo "Ex. link-files DOT $HOME/conf $HOME alias bashrc profile"
        return;
    fi
    FLAG=$1; shift;
    SRC_DIR=$1; shift;
    DST_DIR=$1; shift;
    FILES=$*

    [[ ! -d $SRC_DIR ]] && { echo "[ERROR] src: $SRC_DIR doesnt exist"; exit 1; }
    [[ ! -d $DST_DIR ]] && { echo "[INFO] dst: $DST_DIR doesnt exist. Creating new one."; mkdir -p $DST_DIR; }

    for file in $FILES; do
        case $FLAG in
            "DOT")
                dstfile=.$file
                ;;
            *)
                dstfile=$file
                ;;
        esac
        if [ -h "$DST_DIR/$dstfile" -o -e "$DST_DIR/$dstfile" ]; then
	    if [ -h "$SRC_DIR/$file" -o -e "$SRC_DIR/$file" ]; then
	        { echo "Unlinking $DST_DIR/$dstfile"; }	# unlink $DST_DIR/$dstfile;
	    else
	        { echo "Moving $DST_DIR/$dstfile"; mv $DST_DIR/$dstfile $SRC_DIR/$file; }
	    fi
	fi
        { echo "Linking $DST_DIR/$file"; ln -s $SRC_DIR/$file $DST_DIR/$dstfile; }
    done
}

# Don't link: diffexclude rsyncexclude tarexclude dir_colors_dark/light downlinks doxygen.cfg gdb_history logrotate.conf
# Not applicable for all machines. Solaris hangs with this file. Xdefaults
link-confs()
{
    echo "Linking Configuration Files/Directories - Start"

    CONFS="elinks links vim vnc"
    CONFS+=" alias bashrc bash_profile bash_logout cshrc login login_conf profile shrc"
    CONFS+=" cvsignore gitignore svnignore"
    CONFS+=" mailrc pinerc screenrc toprc gvimrc vimrc tmux.conf"
    CONFS+=" gdbinit gitattributes gitconfig indent.pro"
    CONFS+=" cookies cvspass mail_aliases rhosts"
    CONFS+=" hushlogin"

    link-files DOT $HOME/conf $HOME $CONFS

    echo "Linking Configuration Files/Directories - Done"
}

# Do not link: bash_history gdb_history history lesshst
link-logs()
{
    echo "Linking Log Files/Directories - Start"

    LOGS=" "

    link-files DOT $HOME/.logs $HOME $LOGS

    echo "Linking Log Files/Directories - Done"
}

link-scripts()
{
    [[ ! -d ~/scripts ]] && { echo "$HOME/scripts doesnt exist."; return; }

    echo "Linking Script Files - Start"

    [[ ! -d ~/scripts/bin ]] && { mkdir -p ~/scripts/bin; }

    SCRIPTS="awk bash expect perl ruby"
    SCRIPTS+=" 3rd-party/bash 3rd-party/perl 3rd-party/python 3rd-party/ruby"

    for dir in $SCRIPTS; do
        [ -d "$HOME/scripts/$dir" ] && link-files REG $HOME/scripts/$dir $HOME/scripts/bin $(cd $HOME/scripts/$dir/ && ls *)
    done

    echo "Linking Script Files - Done"
}

link-tools()
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

stop-cron()
{
    echo "Configuring Cron - Stop"
    $HOME/scripts/bin/cron.sh -l
    $HOME/scripts/bin/cron.sh -t
    echo "Configuring Cron - Done"
}

start-cron()
{
    echo "Configuring Cron - Start"
    $HOME/scripts/bin/cron.sh -s $HOME/conf/custom/crontab
    $HOME/scripts/bin/cron.sh -l
    echo "Configuring Cron - Done"
}

function usage()
{
    echo "Usage: conf.sh <-a|-c|-h|-l|-n|-s|-t>"
    echo "Options:"
    echo "  -a - link all files and start cron (-clnst)"
    echo "  -c - start cron job of user"
    echo "  -d - delete cron job of user"
    echo "  -l - create symlink of user log files"
    echo "  -n - create symlink of user conf files"
    echo "  -s - create symlink of user script files"
    echo "  -t - create symlink of user tool binaries"
    echo "  -h - print this help message"
}

main()
{
    PARSE_OPTS="hacdlnst"
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

    ((opt_a)) && (link-confs; link-logs; link-scripts; link-tools; stop-cron; start-cron; exit 0)
    ((opt_n)) && link-confs
    ((opt_l)) && link-logs
    ((opt_s)) && link-scripts
    ((opt_t)) && link-tools
    ((opt_c)) && start-cron
    ((opt_d)) && stop-cron
    ((opt_h)) && (usage; exit 0)

    exit 0
}

if [ "$(basename -- $0)" == "$(basename conf.sh)" ]; then
    main $*
fi

