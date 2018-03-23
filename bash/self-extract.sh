#!/bin/bash
CKSUM=@CKSUM@

#  DETAILS: self-compressing, extracting script.
#  CREATED: 03/22/18 17:05:09 IST
# MODIFIED: 03/23/18 10:30:42 IST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2018, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

PATH=$PATH:/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin

VERSION="@PKGVER@"
PKGSTART=@PKGSTART@
PKGDATE="@PKGDATE@"

SUDO=
PKG=tar
CAT=cat
ENFLATE="czpf"
DEFLATE="xzpf"
PKGEXT="tar.gz"
SHEXT="sh"
DELIM=@

function die()
{
    echo "$*"; exit 1;
}

function show_banner()
{
    tty >/dev/null 2>/dev/null && IS_TTY=1
    BANNER=$(mktemp);

    cat >$BANNER <<_BANNER_END
This is banner for self-extract script
____________________________________________________________

Please select script action:

 1) Exit the script
 2) Extract pkg file in script
____________________________________________________________
_BANNER_END

    [ $? -ne 0 ] && die 'Error while extracting banner'

    ACTION=-1
    while [ $ACTION -eq -1 ]; do
        printf 'To select, enter 1 or 2: '
        read SEL
        [ -z "$SEL" ] && SEL=1
        case $SEL in
            1) ACTION=1
                ;;
            2) ACTION=2
                ;;
        esac
    done
    [[ $ACTION -eq 1 ]] && { die "Exiting ...."; }
}

# extracts self contents
function self_extract()
{
    local fcksum=$(tail -n +3 "$0" | cksum | cut -d' ' -f1)
    [[ "$fcksum" -ne "$CKSUM" ]] && { die "cksum mismatch, corrupt pkg"; }

    local dpath="$(mktemp -d)";
    local PKGNAME="$(basename $0)";
    PKGNAME=${PKGNAME%.sh};
    local PKGPATH="$dpath/${PKGNAME}.$PKGEXT";
    local PKGOPTS="$DEFLATE $PKGPATH $PKGNAME"
    tail -n +$PKGSTART "$0" | base64 -d > $PKGPATH
    local oldpath=$PWD;
    cd $dpath;
    $SUDO $PKG $PKGOPTS;
    cd $oldpath;
    if [ ! -e $(dirname $0)/$PKGNAME ]; then
        mv -f $dpath/$PKGNAME $(dirname $0);
        echo "pkg is extracted at $(dirname $0)/$PKGNAME";
        rm -rf $dpath;
    else
        echo "already $(dirname $0)/$PKGNAME present";
        echo "pkg is extracted at $dpath/$PKGNAME";
    fi
}

function self_pkg_create()
{
    [[ ! -e $1 ]] && { die "input $1 not found"; }
    local input="$1";
    local dpath="$(mktemp -d)";
    local cdate="$(/bin/date +'%d/%m/%Y %T %Z')";
    local nlines=$(wc -l $0 | awk '{print $1}');
    nlines=$(expr $nlines + 1);             # next line
    local PKGNAME="$(basename $input)"
    local PKGPATH="$dpath/${PKGNAME%/}.$PKGEXT";
    local PKGOPTS="$ENFLATE $PKGPATH $PKGNAME"
    local output="$dpath/${PKGNAME%/}.$SHEXT"
    sed -e "s;@PKGSTART$DELIM;$nlines;" \
        -e "s;@PKGVER$DELIM;$PKGVER;" \
        -e "s;@PKGDATE$DELIM;$cdate;" \
        -e "s;@SCRIPT$DELIM;$(basename $output);" \
        $0 > $output;
    local oldpath=$PWD;
    cd $(dirname $1);
    $SUDO $PKG $PKGOPTS;
    $SUDO $CAT $PKGPATH | base64 >> $output;
    cd $oldpath;
    local fcksum=$(tail -n +3 "$output" | cksum | cut -d' ' -f1);
    sed -e "s;@CKSUM$DELIM;$fcksum;" \
        $output > $output.final;
    chmod +x $output.final;
    if [ ! -e "$(dirname $input)/$(basename $output)" ]; then
        mv -f $output.final "$(dirname $input)/$(basename $output)";
        echo "pkg is created at $(dirname $input)/$(basename $output)";
        rm -rf $dpath;
    else
        echo "already $(dirname $input)/$(basename $output) present";
        echo "new pkg is created at $output.final";
    fi
}

usage()
{
    echo "Usage: self-extract.sh [-h|]"
    echo "Options:"
    echo "  -h                  - print this help"
    echo "  -c <input-path>     - input file/dir path to compress"
    echo "  -x                  - self-extract into file/dir"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="hc:x"
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

    # [[ $(id -u) -ne 0 ]] && { die "Error: Admin privileges required"; }
    umask 022

    ((opt_h)) && { usage; }
    ((opt_v)) && { PKGVER="$optarg_v"; } || { PKGVER="1.0"; }
    ((opt_c)) && { self_pkg_create $optarg_c; }
    ((opt_x)) && { self_extract $optarg_x; }

    exit 0;
}

if [ "self-extract.sh" == "$(basename $0)" -o "@SCRIPT@" == "$(basename $0)" ];
then
    main $*
fi

# This exit is mandatory to avoid bash from looking further into blob
exit 0;
# VIM: ts=4:sw=4:sts=4:expandtab
