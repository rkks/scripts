#!/bin/bash
#  DETAILS: Installer script for my tools. Downloads and installs locally.
#  CREATED: 09/23/14 09:31:11 IST
# MODIFIED: 10/07/14 15:48:42 IST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2014, Ravikiran K.S.


if [ "install.sh" == "$(basename $0)" ] && [ -f $HOME/.bashrc ]; then
    source $HOME/.bashrc
    log_init INFO $SCRIPT_LOGS/install.log
fi

set -x  # -uvx: Warn unset vars, Verbose (echo each cmd), Enable debug mode
DOWNLOADS=$HOME/downloads
TOOLS=$HOME/tools/$UNAMES
CFLAGS="-I$TOOLS/include"
LDFLAGS="-static -L$TOOLS/lib"

usage()
{
    echo "Usage: install.sh [-h|]"
    echo "Options:"
    echo "  -h          - print this help"
    echo "  -t          - install tmux"
}

function downld()
{
    [[ $# -ne 2 ]] && { echo "downld <file> <url>"; return; }
    [[ -e $1 ]] && { echo "File $1 already exists"; return; }
    local fname=$1; shift; wget -O $fname $*; fail_bail;
}

function untar()
{
    [[ $# -ne 2 ]] && { echo "untar <dir> <file>"; return; }
    [[ -e $1 ]] && { echo "Directory $1 already exists"; return; }
    mkdie $1; tar xvzf $2 -C $1 --strip-components=1; fail_bail;
}

function config() {
    local args="$*";
    [[ ! -e ./configure ]] && { ./autogen.sh; }
    ./configure --prefix=$TOOLS CFLAGS="$CFLAGS" CPPFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" $args; fail_bail;
} 

function build()
{
    [[ $# -lt 1 ]] && { echo "build <dir> [args]"; return; }
    local dir=$1; shift; cdie $dir*; config "$*"; make && make install; fail_bail; cd -; rm -rf $dir;
}

function sinstall()
{
    [[ $# -lt 3 ]] && { echo "install <dir> <file> <url> [conf-args]"; }
    local dir=$1; shift; local file=$1; shift; local url=$1; shift;
    downld $file $url; untar $dir $file; build $dir $*;
}

# download from https://github.com/downloads/libevent/libevent/libevent-xxx.tar.gz gives SSL error
function tmux_install()
{
    sinstall libtool libtool-2.4.tar.gz http://ftp.gnu.org/gnu/libtool/libtool-2.4.tar.gz
    sinstall autoconf autoconf-latest.tar.gz http://ftp.gnu.org/gnu/autoconf/autoconf-latest.tar.gz
    sinstall automake automake-1.14.tar.gz http://ftp.gnu.org/gnu/automake/automake-1.14.tar.gz
    sinstall gettext gettext-latest.tar.gz http://ftp.gnu.org/gnu/gettext/gettext-latest.tar.gz
#    --disable-shared
    sinstall libevent libevent-2.0.21.tar.gz http://sourceforge.net/projects/levent/files/libevent/libevent-2.0/libevent-2.0.21-stable.tar.gz
    sinstall ncurses ncurses-5.9.tar.gz ftp://ftp.gnu.org/gnu/ncurses/ncurses-5.9.tar.gz --without-ada
    CFLAGS+=" -I$HOME/tools/$UNAMES/include/ncurses";
    LDFLAGS+=" -L$HOME/tools/$UNAMES/include/ncurses -L$HOME/tools/$UNAMES/include"
    sinstall tmux tmux-1.9a.tar.gz http://downloads.sourceforge.net/tmux/tmux-1.9a.tar.gz
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="ht"
    local opts_found=0
    while getopts ":$PARSE_OPTS" opt; do
        case $opt in
            [a-zA-Z0-9])
            log DEBUG "-$opt was triggered, Parameter: $OPTARG";
            local "opt_$opt"=1 && local "optarg_$opt"="$OPTARG";
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

    [[ ! -d $TOOLS ]] && { mkdie $TOOLS; }
    [[ ! -d $DOWNLOADS ]] && { mkdie $DOWNLOADS; }

    cdie $DOWNLOADS;
    ((opt_t)) && { tmux_install; }
    ((opt_h)) && { usage; }

    exit 0;
}

if [ "install.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
