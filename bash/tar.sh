#!/usr/bin/env bash
#  DETAILS: Tar wrappers
#  CREATED: 07/17/13 15:53:58 IST
# MODIFIED: 10/20/14 10:59:10 IST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

# Warn unset vars as error, Verbose (echo each command), Enable debug mode
#set -uvx

# Source .bashrc only if invoked as a sub-shell.
if [[ "$(basename tar.sh)" == "$(basename -- $0)" ]] && [ -f $HOME/.bashrc ]; then
    source $HOME/.bashrc
    log_init INFO $SCRIPT_LOGS/tar.log
fi

function archive()
{
    test -e $2 && echo "archiving $2 into $2.$1" || { echo "'$2' is not a valid path"; return $EINVAL; }
    case $1 in
        7z)   7za a -t7z -mx9 $2.$1 $2   ;;
        bz2)  tar cvjf -X $CUSTOM_CONFS/tarexclude $2.$1 $2    ;;
        gz)   tar cvzf -X $CUSTOM_CONFS/tarexclude $2.$1 $2    ;;
        tar)  tar cvf -X $CUSTOM_CONFS/tarexclude $2.$1 $2     ;;
        tbz2) tar cvjf -X $CUSTOM_CONFS/tarexclude $2.$1 $2    ;;
        tgz)  tar cvzf -X $CUSTOM_CONFS/tarexclude $2.$1 $2    ;;
        rar)  rar x $2    ;;
        zip)  zip $2      ;;
        Z)    compress $2 ;;
        *)    echo "'$1' cannot be compressed via archive()"        ;;
    esac
}

function extract()
{
    local file=$(basename $1); local fpath=$1; local dname=$(untar_dname $fpath)
    [[ -e $fpath ]] && echo "extract $fpath into $dname/" || { echo "File $fpath not found"; return $EINVAL; }
    case $fpath in
        *.7z)       7za x $fpath      ;;
        *.tar.bz2)  tar xvjf $fpath   ;;
        *.tar.gz)   tar xvzf $fpath   ;;
        *.bz2)      bunzip2 $fpath    ;;
        *.rar)      unrar x $fpath    ;;
        *.gz)       gunzip $fpath     ;;
        *.tar)      tar xvfp $fpath   ;;
        *.tbz2)     tar xvjf $fpath   ;;
        *.tgz)      tar xvzf $fpath   ;;
        *.zip)      unzip $fpath      ;;
        *.Z)        uncompress $fpath ;;
        *)          echo "$fpath can not be extracted via extract()" ;;
    esac
    fail_bail;
}

function list()
{
    local filename=$(basename $1);
    test -e $1 && echo "listing $1 contents" || { echo "'$1' is not a valid file"; return $EINVAL; }
    case $1 in
        *.7z)       7za l $1        ;;
        *.tar.bz2)  tar tvjf $1     ;;
        *.tar.gz)   tar tvzf $1     ;;
        *.rar)      rar l $1        ;;
        *.gz)       gzip -l $1      ;;
        *.tar)      tar tvf $1      ;;
        *.tbz2)     tar tvjf $1     ;;
        *.tgz)      tar tvzf $1     ;;
        *.zip)      unzip -l $1     ;;
        *.Z)        zcat $1         ;;
        *)          echo "'$1' cannot be listed via list()" ;;
    esac
}

function untar_dname()
{
    case $1 in
        *.tar.bz2|*.tar.gz|*.tar.tar)  echo "${file%.*.*}"  ;;
        *.7z|*.bz2|*.rar|*.gz|*.tar|*.tbz2|*.tgz|*.zip|*.Z) echo "${file%.*}"  ;;
        *)  ;;
    esac
}

usage()
{
    echo "Usage: tar.sh <-c <archive-type> <files|dir>|-l <archive-file>|-x <archive-file>>"
    echo "Options:"
    echo "  -c <archive-type> <files|dir>   - create archive of given type using given list of files/dir"
    echo "  -d <archive-file>               - give dir-name resulting from extract"
    echo "  -l <archive-file>               - list given archive-file contents"
    echo "  -x <archive-file>               - extract given archive-file contents"
    echo "  -h                              - print this help message"
    echo "Supported archive-type: 7z, gz, bz2, tgz, tbz2, tar, rar, Z"

}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    local PARSE_OPTS="hc:dlx"
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

    ((opt_c)) && archive $optarg_c $1;
    ((opt_d)) && untar_dname $1;
    ((opt_l)) && list $1;
    ((opt_x)) && extract $1;
    ((opt_h)) && { usage; exit 0; }

    exit 0
}

if [ "$(basename -- $0)" == "$(basename tar.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab

