#!/usr/bin/env bash
#  DETAILS: Cscope Utils
#  CREATED: 06/25/13 11:05:14 IST
# MODIFIED: 05/14/17 01:17:10 PDT
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

# Warn unset vars as error, Verbose (echo each command), Enable debug mode
#set -uvx

# Source .bashrc.dev only if invoked as a sub-shell. Not if sourced.
[[ "$(basename cscope_cgtags.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

export PATH="$HOME/tools/$UNAMES/bin:$PATH";
SRC_FILES=src.list

# Do not use cscope-indexer. This is slow but flexible.
function findsrc()
{
    local dpath=.; local findexclude=$dpath/findexclude

    # -follow -name "<pattern>" doesn't work
    if [ "$UNAMES" = "Linux" -o "$UNAMES" = "SunOS" ]; then
        local SRC_PAT=".*\.\([cChHlxsSy]\|cpp\|[io]dl\|p[lmy]\|mk\|sh\|inc\)"; local FINDOPT=
    elif [ "$UNAMES" = "FreeBSD" ]; then
        local SRC_PAT=".*\.([cChHlxsSy]|cpp|[io]dl|p[lmy]|mk|sh|inc)"; local FINDOPT=-E
    else
        echo "Unknown machine $UNAMES" && return
    fi

    truncate_file $SRC_FILES
    log DEBUG "Find source files from $PWD"
    for dir in $(ls -d */); do
        [[ -f $findexclude ]] && { local exclude=$(grep -Eo "(^|[[:space:]])$dir($|[[:space:]])" $findexclude | wc -l); } || { local exclude=0; }
        [[ $exclude -eq 0 ]] && { run find $FINDOPT $dpath/$dir -type f -regex "$SRC_PAT" -print >> $SRC_FILES; }
    done
    # look for files in base directory
    run find $FINDOPT $dpath -type f -maxdepth 1 -regex "$SRC_PAT" -print >> $SRC_FILES
}

function cscope_db_clean()
{
    (own cscope) || { echo "cscope binary not found in PATH"; return 0; };
    log DEBUG "Clean cscope db in $PWD"
    run rm -f cscope.*;
}

function cscope_db_create()
{
    [[ ! -z $(ls cscope* 2> /dev/null) ]] && { echo "Cscope db exists. Clean using cscope_db_clean"; return; }

    log DEBUG "Create cscope db in $PWD"
    cscope_db_update;
}

function cscope_db_update()
{
    (own cscope) || { echo "cscope binary not found in PATH"; return 0; };
    [[ ! -f $SRC_FILES ]] && { echo "$PWD/$SRC_FILES doesn't exist. Use findsrc to build file list"; return; }

    # -qUbe for inverted index, -cUbe for normal index. -k to refer kernel headers. 
    log DEBUG "Build cscope database for $PWD using $(which cscope)"
    run cscope -cUbe -k -i $SRC_FILES    #> /dev/null 2>&1
}

function global_db_clean()
{
    (own gtags) || { echo "gtags binary not found in PATH"; return 0; };
    log DEBUG "Clean GNU global db in $PWD"
    run rm -f G*TAGS GPATH;
}

function global_db_create()
{
    [[ ! -z $(ls G*TAGS 2> /dev/null) ]] && { echo "GNU global db exist. Clean using global_db_clean"; return; }

    log DEBUG "Create global db in $PWD"
    global_db_update;
}

function global_db_update()
{
    (own gtags) || { echo "gtags binary not found in PATH"; return 0; };
    [[ ! -f $SRC_FILES ]] && { echo "$PWD/$SRC_FILES doesn't exist. Use findsrc to build file list"; return; }

    log DEBUG "Build global database for $PWD using $(which gtags)"
    run gtags -f $SRC_FILES    #> /dev/null 2>&1
}

function ctags_db_clean()
{
    (own ctags) || { echo "ctags binary not found in PATH"; return 0; };
    log DEBUG "Clean ctags db in $PWD"
    run rm -f tags TAGS;
}

function ctags_db_create()
{
    [[ -f tags ]] && { echo "Ctags db exists. Clean using ctags_db_clean"; return; }

    log DEBUG "Create ctags db in $PWD"
    ctags_db_update
}

# copy exuberant ctags to every machine. Otherwise '--declarations -d --globals -I --members -T' opts wouldn't work.
function ctags_db_update()
{
    (own ctags) || { echo "ctags binary not found in PATH"; return 0; };
    [[ ! -f $SRC_FILES ]] && { echo "$PWD/$SRC_FILES doesn't exist. Use findsrc to build file list"; return; }

    log DEBUG "Build ctags database for $PWD using $(which ctags)"
    run ctags --extra=+q --fields=afmikKlnsSz --sort -IATTR_PACKED,ATTR_UNUSED --c-types=+p -a -L $SRC_FILES    #> /dev/null 2>&1
}

function csc_run()
{
    field=$1; shift
    case $field in
    '7')
        run cscope -L -d -$field $* | awk '{print $1}'
        ;;
    *)
        #cscope -L -d -$field $* | awk '{print $1 " +" $3 " " $4}'      # special case for -4 didnt work.
        run cscope -L -d -$field $*
        ;;
    esac
}

usage()
{
    echo "usage: cscope_cgtags.sh <-a|-b|-c|-d|-e|-f|-l|-s|-t|-u|-x [<src-path>]|-h|-g <cscope-num> <pattern>>"
    echo "Options:"
    echo "  -a    - append/update all existing source databases"
    echo "  -b    - build all new (cscope/global/ctags) databases (clean)"
    echo "  -c    - create new cscope database (clean)"
    echo "  -d    - do update existing cscope database"
    echo "  -e    - extend/update existing GNU global database"
    echo "  -f    - form new GNU global database (clean)"
    echo "  -g <cscope-num> <pattern> - grep for pattern using line-oriented cscope"
    echo "  -l    - make list of source files under given path (recursive)"
    echo "  -s    - disable source files list update/create (recursive)"
    echo "  -t    - create ctags database from scratch (clean)"
    echo "  -u    - update existing ctags database"
    echo "  -x    - delete all databases under given path"
    echo "  -h    - print this help message"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="habcdefg:lstux"
    local opts_found=0
    while getopts ":$PARSE_OPTS" opt; do
        case $opt in
            [a-zA-Z0-9])
                log DEBUG "-$opt was triggered, Parameter: $OPTARG"
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

    ((opt_g)) && { csc_run $optarg_g $*; return; }

    [[ $# -ne 0 ]] && { cdie $1; shift; }
    ((!opt_s && !opt_h && !opt_g && !opt_x )) && findsrc;
    ((opt_b || opt_c || opt_x)) && cscope_db_clean;
    ((opt_b || opt_f || opt_x)) && global_db_clean;
    ((opt_b || opt_t || opt_x)) && ctags_db_clean;
    ((opt_b || opt_c)) && cscope_db_create;
    ((opt_b || opt_f)) && global_db_create;
    ((opt_b || opt_t)) && ctags_db_create;
    ((opt_a || opt_d)) && cscope_db_update;
    ((opt_a || opt_e)) && global_db_update;
    ((opt_a || opt_u)) && ctags_db_update;
    ((opt_h)) && (usage; exit 0)

    exit 0
}

if [ "$(basename -- $0)" == "$(basename cscope_cgtags.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4
