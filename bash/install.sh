#!/bin/bash
#  DETAILS: Installer script for my tools. Downloads and installs locally.
#  CREATED: 09/23/14 09:31:11 IST
# MODIFIED: 25/Apr/2018 15:08:15 PDT
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2014, Ravikiran K.S.

#set -x  # -uvx: Warn unset vars, Verbose (echo each cmd), Enable debug mode

# Never install: p7zip -- unable to delete afterwards
# Work Tools: curl ncdu rsync git wget ncurses tmux lighttpd resin
# Dev Tools: ant gmake libevent ctags cscope global splint vim jdk sloccount

[[ "$(basename install.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

CFLAGS="-I$TOOLS/include"
LDFLAGS="-static -L$TOOLS/lib"

usage()
{
    echo "Usage: install.sh [-h|-e|-p|-t|-w]"
    echo "Options:"
    echo "  -a <arch>   - compile for arch"
    echo "  -c          - install cscope+ctags"
    echo "  -e          - install expect"
    echo "  -g          - install global"
    echo "  -m          - install pmtools"
    echo "  -o          - install openssl"
#    echo "  -p         - install p7zip"
    echo "  -r          - install rsnapshot"
    echo "  -t          - install tmux"
    echo "  -w          - install wget"
    echo "  -h          - print this help"
}

# misc curl opts: --connect-timeout 30 --create-dirs --keepalive-time 10 --max-redirs 50
function downld()
{
    [[ $# -ne 2 ]] && { echo "downld <file> <url>"; return $EINVAL; }
    [[ -e $PWD/tar/$1 ]] && { echo "File $1 already exists"; return $EEXIST; }
    [[ -e $DOWNLOADS/$1 ]] && { echo "File $DOWNLOADS/$1 already exists"; return $EEXIST; }
    [[ -e $1 ]] && { echo "File $1 already exists"; mv $1 $DOWNLOADS/; return $EEXIST; }
    local fname=$1; shift;
    (own wget) && { wget --limit-rate=1m -O $fname $*; } || { curl --limit-rate 1m -# -L -o $fname $*; }
    fail_bail; mv $fname $DOWNLOADS/ ;
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
    local d=$1; shift; cdie $d*; config "$*"; make && make install; fail_bail; d=$(basename $PWD); cd -; rm -rf $d;
}

function sinstall()
{
    [[ $# -lt 2 ]] && { echo "sinstall <file> <url> [conf-args]"; }
    local file=$1; shift; local url=$1; shift; local dir=$(tar.sh -d $file);
    downld $file $url; untar $file; build $dir $*;
}

function wget_install()
{
    sinstall wget.tar.gz http://ftp.gnu.org/gnu/wget/wget-1.15.tar.gz
}

function ginstall()
{
    [[ $# -lt 2 ]] && { echo "ginstall <url> <dir-name> [conf-args]"; return $EINVAL; }
    local url=$1; shift; local dir=$2; shift; git clone $url $dir; build $dir $*;
}

#function p7zip_install()
#{
#    sinstall p7zip.tar.bz2 http://sourceforge.net/projects/p7zip/files/p7zip/9.20.1/p7zip_9.20.1_src_all.tar.bz2
#}

# download from https://github.com/downloads/libevent/libevent/libevent-xxx.tar.gz gives SSL error
function tmux_install()
{
    #sinstall libtool.tar.gz http://ftp.gnu.org/gnu/libtool/libtool-2.4.tar.gz
#    sinstall autoconf.tar.gz http://ftp.gnu.org/gnu/autoconf/autoconf-latest.tar.gz
#    sinstall automake.tar.gz http://ftp.gnu.org/gnu/automake/automake-1.14.tar.gz
#    sinstall gettext.tar.gz http://ftp.gnu.org/gnu/gettext/gettext-latest.tar.gz
#    --disable-shared
#    sinstall libevent.tar.gz http://sourceforge.net/projects/levent/files/libevent/libevent-2.0/libevent-2.0.21-stable.tar.gz
#    sinstall ncurses.tar.gz ftp://ftp.gnu.org/gnu/ncurses/ncurses-5.9.tar.gz --without-ada
    CFLAGS+=" -I$HOME/tools/$UNAMES/include/ncurses -I$HOME/tools/$UNAMES/include";
    LDFLAGS+=" -L$HOME/tools/$UNAMES/lib/ncurses -L$HOME/tools/$UNAMES/lib"
    sinstall tmux.tar.gz https://github.com/tmux/tmux/releases/download/1.9a/tmux-1.9a.tar.gz
    ginstall https://codeload.github.com/twaugh/patchutils/zip/master patchutils;       # for diff between patch files for incremental patch
}

function expect_install()
{
    sinstall expect.tar.gz http://sourceforge.net/projects/expect/files/Expect/5.45/expect5.45.tar.gz
}

function global_install()
{
    sinstall global.tar.gz http://tamacom.com/global/global-6.5.4.tar.gz
}

function pmtools_install()
{
    downld pmtools.tar.gz http://search.cpan.org/CPAN/authors/id/M/ML/MLFISHER/pmtools-2.0.0.tar.gz
    local dir=$(tar.sh -d pmtools.tar.gz); cd $TOOLS && untar pmtools.tar.gz && cd -;
}

function rsnapshot_install()
{
    downld rsnapshot.tar.gz http://www.rsnapshot.org/downloads/rsnapshot-latest.tar.gz
    cd $TOOLS && untar rsnapshot.tar.gz && cd -;
}

function cscope-tags_install()
{
    sinstall cscope.tar.gz http://sourceforge.net/projects/cscope/files/cscope/15.8a/cscope-15.8a.tar.gz
    sinstall ctags.tar.gz http://prdownloads.sourceforge.net/ctags/ctags-5.8.tar.gz
}

function openssl_install()
{
    local wflag='--no-check-certificate'; local file='openssl-1.0.1j.tar.gz'; local dir=$(tar.sh -d $file);
    [[ ! -e $file ]] && { wget $wflag -O $file https://www.openssl.org/source/openssl-1.0.1j.tar.gz; fail_bail; }
    untar $file; cd $dir && ./config --prefix=$TOOLS; fail_bail;
    make && make install && cd - && rm -rf $dir
}

function set_arch()
{
    CFLAGS="-m$1 $CFLAGS";
    LDFLAGS="-m$1 $LDFLAGS";
}

function elk_install()
{
    downld logstash.tar.gz https://artifacts.elastic.co/downloads/logstash/logstash-5.0.0.tar.gz
    downld kibana.tar.gz https://artifacts.elastic.co/downloads/kibana/kibana-5.0.0-darwin-x86_64.tar.gz
    downld elasticsearch.tar.gz https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.0.0.tar.gz
    untar logstash.tar.gz && mv logstash/ $TOOLS/;
    untar kibana.tar.gz && mv kibana/ $TOOLS/;
    untar elasticsearch.tar.gz && mv elasticsearch/ $TOOLS/;
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="ha:ceglmoprtw"
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

    ((own wget) || (own curl)) || { echo "wget/curl not found"; exit $EINVAL; }
    [[ ! -d $TOOLS ]] && { mkdie $TOOLS; }
    [[ ! -d $DOWNLOADS ]] && { mkdie $DOWNLOADS; }

    cdie $DOWNLOADS;
    ((opt_a)) && { set_arch $optarg_a; }
    ((opt_c)) && { cscope-tags_install; }
    ((opt_e)) && { expect_install; }
    ((opt_g)) && { global_install; }
    ((opt_m)) && { pmtools_install; }
    ((opt_l)) && { elk_install; }
    ((opt_o)) && { openssl_install; }
#    ((opt_p)) && { p7zip_install; }
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
