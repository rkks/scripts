#!/usr/bin/env bash
#  DETAILS: Create directory structure based on need
#  CREATED: 03/21/13 11:01:09 IST
# MODIFIED: 10/06/14 14:21:08 IST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

#set -uvx               # Treat unset variables as an error, verbose, debug mode

# Source .bashrc.dev only if invoked as a sub-shell.
if [[ "$(basename mkdir.sh)" == "$(basename -- $0)" ]] && [ -f $HOME/.bashrc.dev ]; then
    source $HOME/.bashrc.dev
    # define new ENV only if necessary.
fi

AUTHOR="Ravikiran K.S."
AUTHOR_EMAIL="ravikirandotks@gmail.com"
CREATED=$(/bin/date +'%d/%m/%Y %T %Z')
COPYRIGHT="Copyright (c) $(/bin/date +'%Y'), $AUTHOR"
DETAIL="...details here..."
DEVEL_TEMPS=$HOME/conf/template     # development templates

make_pr_dir()
{
    [[ "$#" != "1" ]] && (usage; exit $EINVAL)

    PR=$(basename $1)
    mkdie $PR && cdie $PR && mkdir -p logs mails tests
    sed -e "s;@AUTHOR@;$AUTHOR;" \
        -e "s;@AUTHOR_EMAIL@;$AUTHOR_EMAIL;" \
        -e "s;@CREATED_DATE@;$CREATED;" \
        -e "s;@COPYRIGHT@;$COPYRIGHT;" \
        $DEVEL_TEMPS/debug-checklist > ./$PR.txt
}

make_rli_dir()
{
    [[ "$#" != "1" ]] && (usage; exit $EINVAL)

    RLI=$(basename $1)
    mkdie $RLI && cdie $RLI && mkdir -p docs logs mails src tests
    sed -e "s;@AUTHOR@;$AUTHOR;" \
        -e "s;@AUTHOR_EMAIL@;$AUTHOR_EMAIL;" \
        -e "s;@CREATED_DATE@;$CREATED;" \
        -e "s;@COPYRIGHT@;$COPYRIGHT;" \
        $DEVEL_TEMPS/devel-checklist > ./RLI$RLI.txt
}

make_proj_dir()
{
    [[ "$#" != "1" ]] && (usage; exit $EINVAL)

    PROJ=$(basename $1)
    [[ -d $PROJ ]] && { echo "PROJ directory $PROJ already exists" && exit 1; }
    PROJ_UPPER=$(echo PROJ | tr '[:lower:]' '[:upper:]')
    mkdie $PROJ && cdie $PROJ && cp $DEVEL_TEMPS/Makefile Makefile
    sed -e "s;@AUTHOR@;$AUTHOR;" \
        -e "s;@AUTHOR_EMAIL@;$AUTHOR_EMAIL;" \
        -e "s;@CREATED_DATE@;$CREATED;" \
        -e "s;@COPYRIGHT@;$COPYRIGHT;" \
        -e "s;@DETAIL@;$DETAIL;" \
        -e "s;@FILE@;$PROJ;" \
        $DEVEL_TEMPS/template.c > ./$PROJ.c
    sed -e "s;@AUTHOR@;$AUTHOR;" \
        -e "s;@AUTHOR_EMAIL@;$AUTHOR_EMAIL;" \
        -e "s;@CREATED_DATE@;$CREATED;" \
        -e "s;@COPYRIGHT@;$COPYRIGHT;" \
        -e "s;@DETAIL@;$DETAIL;" \
        -e "s;@FILE_HEAD@;$PROJ_UPPER;" \
        $DEVEL_TEMPS/template.h > ./$PROJ.h
}

usage()
{
    echo "usage: mkdir.sh <-p <pr-num>|-r <rli-num>|-j <proj-name>>"
    echo "Options:"
    echo "  -j <proj-name>  - create template project directory with given project name"
    echo "  -p <pr-num>     - create template PR directory with given PR number"
    echo "  -r <rli-num>    - create template RLI directory with given RLI number"
    echo "  -h              - print this help message"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="hj:p:r:"
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

    ((opt_j)) && make_proj_dir $optarg_j
    ((opt_p)) && make_pr_dir $optarg_p
    ((opt_r)) && make_rli_dir $optarg_r
    ((opt_h)) && (usage; exit 0)

    exit 0
}

if [ "$(basename -- $0)" == "$(basename mkdir.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4

