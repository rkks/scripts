#!/usr/bin/env bash
#  DETAILS: Find command wrappers
#  CREATED: 07/16/13 21:22:06 IST
# MODIFIED: 03/22/18 12:21:22 IST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

# Warn unset vars as error, Verbose (echo each command), Enable debug mode
#set -uvx

# Source .bashrc.dev only if invoked as a sub-shell.
[[ "$(basename find.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

function findcores() { find ${1:-.} -type f -name "*core*.gz"; }

# Find files belonging to removed users and user-groups on system
function find_nouser_nogroup_files()
{
    find / -nouser -o -nogroup 2> /dev/null
}

function clean_obj()
{
    local dir_path=${1:-.};
    local OBJ_PAT; local FINDOPT;

    [[ "$UNAMES" == "Linux" || "$UNAMES" == "SunOS" ]] && { OBJ_PAT=".*\.\([sklpP]o\|cmd\|obj\)"; }
    [[ "$UNAMES" == "FreeBSD" || "$UNAMES" == "Darwin" ]] && { OBJ_PAT=".*\.([skpP]o|cmd|obj)"; FINDOPT=-E; }

    [[ "" == "$OBJ_PAT" ]] && { echo "Unknown machine" && return; }

    find $FINDOPT $dir_path -type f -regex "$OBJ_PAT" -exec rm -f {} \;
}

function findgrep_code()
{
    [[ $# -eq 0 ]] && { echo "usage: findgrep_code <text>"; return $EINVAL; }

    local dpath=.; local findexclude=$dpath/.findexc

    [[ "$UNAMES" == "Linux" || "$UNAMES" == "SunOS" ]] && { SRC_PAT=".*\.\([cChHlxsSy]\|cpp\|[io]dl\|p[lmy]\|mib\|mk\|sh\)"; }
    [[ "$UNAMES" == "FreeBSD" || "$UNAMES" == "Darwin" ]] && { SRC_PAT=".*\.([cChHlxsSy]|cpp|[io]dl|p[lmy]|mib|mk|sh)"; FINDOPT=-E; }
    [[ "" == "$SRC_PAT" ]] && { echo "Unknown machine" && return; }
    FINDOPT+=" -type f -o -type l";

    [[ ! -f $findexclude ]] && { run find $dpath $FINDOPT -regex "$SRC_PAT" -exec grep -Hni "$@" {} \; 2>/dev/null; return; }

    # Recurse through all subdirectories to be included
    for dir in $(ls -d */); do
        # pruning unwanted stuff. "(^|[[:space:]])$dir($|[[:space:]])" doesn't work
        [[ -f $findexclude ]] && { local exclude=$(grep -w "$dir" $findexclude | wc -l); } || { local exclude=0; }
        # Passing $* to grep allows different grep options to be given
        [[ $exclude -eq 0 ]] && { run find $dpath/$dir $FINDOPT -regex "$SRC_PAT" -exec grep -Hn $@ {} \;; }
    done
    # To search files in base directory run find again with '-maxdepth 1'
    run find $FINDOPT $dpath -maxdepth 1 -regex "$SRC_PAT" -exec grep -Hn $* {} \;
}

function findtxt()
{
    [[ $# -eq 0 ]] && { echo "usage: findtxt <text>"; return $EINVAL; }

    local dpath=.; local findexclude=$dpath/.findexc;
    #local dpath="(^|[[:space:]])$dirpath($|[[:space:]])";

    [[ "$UNAMES" == "Linux" || "$UNAMES" == "SunOS" ]] && { FINDOPT+=" -type f -o -type l"; } # causes problem on LBT
    [[ "$UNAMES" == "FreeBSD" || "$UNAMES" == "Darwin" ]] && { FINDOPT=-E; }

    [[ ! -f $findexclude ]] && { run find $dpath $FINDOPT -exec grep -Hni "$@" {} \; 2>/dev/null; return; }

    # Recurse through all subdirectories to be included
    for dir in $(ls -d */); do
        # pruning unwanted stuff
        #local exclude=$(grep -Eo $dirpat $findexclude | wc -l);
        [[ -f $findexclude ]] && { local exclude=$(grep -w "$dir" $findexclude | wc -l); } || { local exclude=0; }
        # Passing $* to grep allows different grep options to be given
        [[ $exclude -eq 0 ]] && { run find $dpath/$dir -name "*" -exec grep -Hni '$*' {} \; 2>/dev/null; }
    done
    # To search files in base directory run find again with '-maxdepth 1'
    run find $FINDOPT $dpath -maxdepth 1 -name "*" -exec grep -Hn $* {} \; 2>/dev/null;
}

function findexe()
{
    local dir_path=${1:-.};

    FIND_PAT="application/x-executable|application/x-object"
    # For additional options and pruning unwanted stuff
    if [ -f $dir_path/.findinc ]; then
        # Recurse through all subdirectories to be included
        for dir in $(cat $dir_path/.findinc); do
            find . -type f -exec file -i '{}' \; | grep -E "$FIND_PAT" | awk -F : '{print $1}'
        done
        # To search files in base directory add . as an entry to .findinc. Alternately, run find again with '-maxdepth 1'
    else
        find . -type f -exec file -i '{}' \; | grep -E "$FIND_PAT" | awk -F : '{print $1}'
    fi
}

usage()
{
    echo "usage: find.sh <-h|<-c|-e|-o> [path]|<-g|-t pattern>>"
    echo "Options:"
    echo "  -c [path]   - recursively clear objects in given path [path] or current directory"
    echo "  -e [path]   - find executables recursively under given path [path] or current directory"
    echo "  -o [path]   - find coredumps recursively under given path [path] or current directory"
    echo "  -g <pat>    - search recursively for pattern <pat> in source code under current directory"
    echo "  -t <pat>    - search recursively for pattern <pat> in all text files under current directory"
    echo "  -h          - print this help"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="hcegot"
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

    ((opt_c)) && clean_obj $*;
    ((opt_e)) && findexe $*;
    ((opt_g)) && findgrep $*;
    ((opt_o)) && findcores $*;
    ((opt_t)) && findtxt $*;
    ((opt_h)) && { usage; exit 0; }

    exit 0
}

if [ "$(basename -- $0)" == "$(basename find.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab

