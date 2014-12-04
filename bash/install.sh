#!/bin/bash
#  DETAILS: Installer script for my tools. Downloads and installs locally.
#  CREATED: 09/23/14 09:31:11 IST
# MODIFIED: 12/04/14 17:36:57 IST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2014, Ravikiran K.S.


if [ "install.sh" == "$(basename $0)" ] && [ -f $HOME/.bashrc ]; then
    source $HOME/.bashrc
    log_init INFO $SCRIPT_LOGS/install.log
fi

#set -x  # -uvx: Warn unset vars, Verbose (echo each cmd), Enable debug mode
CFLAGS="-I$TOOLS/include"
LDFLAGS="-static -L$TOOLS/lib"

usage()
{
    echo "Usage: install.sh [-h|-e|-p|-t|-w]"
    echo "Options:"
    echo "  -c     - install cscope+ctags"
    echo "  -e     - install expect"
    echo "  -m     - install pmtools"
    echo "  -o     - install openssl"
    echo "  -p     - install p7zip"
    echo "  -p     - install rsnapshot"
    echo "  -t     - install tmux"
    echo "  -w     - install wget"
    echo "  -h     - print this help"
}

function downld()
{
    [[ $# -ne 2 ]] && { echo "downld <file> <url>"; return $EINVAL; }
    [[ -e $1 ]] && { echo "File $1 already exists"; return $EEXIST; }
    local fname=$1; shift; wget -O $fname $*; fail_bail;
}

function untar()
{
    [[ $# -ne 1 ]] && { echo "untar <file>"; return; }
    # Avoid mkdir $1 && tar xvzf $2 -C $1 --strip-components=1; fail_bail;
    tar.sh -x $1; fail_bail;
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
    local dir=$(tar.sh -d $file);
    downld $file $url; untar $file; build $dir $*;
}

function wget_install()
{
    sinstall wget wget-1.15.tar.gz http://ftp.gnu.org/gnu/wget/wget-1.15.tar.gz
}

function p7zip_install()
{
    sinstall p7zip p7zip_9.20.1.tar.bz2 http://sourceforge.net/projects/p7zip/files/p7zip/9.20.1/p7zip_9.20.1_src_all.tar.bz2
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

function expect_install()
{
    sinstall expect expect5.45.tar.gz http://sourceforge.net/projects/expect/files/Expect/5.45/expect5.45.tar.gz
}

function pmtools_install()
{
    downld pmtools-2.0.0.tar.gz http://search.cpan.org/CPAN/authors/id/M/ML/MLFISHER/pmtools-2.0.0.tar.gz
    local dir=$(tar.sh -d pmtools-2.0.0.tar.gz);
    cd $TOOLS && untar $DOWNLOADS/pmtools-2.0.0.tar.gz && cd -;
}

function rsnapshot_install()
{
    downld rsnapshot.tar.gz http://www.rsnapshot.org/downloads/rsnapshot-latest.tar.gz
    local dir=$(tar.sh -d rsnapshot.tar.gz);
    cd $TOOLS && untar $DOWNLOADS/rsnapshot.tar.gz && cd -;
}

function cscope-tags_install()
{
    sinstall cscope cscope-15.8a.tar.gz http://sourceforge.net/projects/cscope/files/cscope/15.8a/cscope-15.8a.tar.gz
    sinstall ctags ctags-5.8.tar.gz http://prdownloads.sourceforge.net/ctags/ctags-5.8.tar.gz
}

function openssl_install()
{
    sinstall openssl openssl-1.0.1j.tar.gz https://www.openssl.org/source/openssl-1.0.1j.tar.gz
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="hcemoprtw"
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

    set -x;
    cdie $DOWNLOADS;
    ((opt_c)) && { cscope-tags_install; }
    ((opt_e)) && { expect_install; }
    ((opt_m)) && { pmtools_install; }
    ((opt_o)) && { openssl_install; }
    ((opt_p)) && { p7zip_install; }
    ((opt_r)) && { rsnapshot_install; }
    ((opt_t)) && { tmux_install; }
    ((opt_w)) && { wget_install; }
    ((opt_h)) && { usage; }

    exit 0;
}

if [ "install.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
