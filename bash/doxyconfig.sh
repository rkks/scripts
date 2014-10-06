#!/usr/bin/env bash
#  DETAILS: Generates Doxygen Configuration using pre-defined template.
#  CREATED: 03/05/13 10:23:23 IST
# MODIFIED: 10/06/14 14:20:17 IST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

#set -uvx               # Treat unset variables as an error, verbose, debug mode

# Source .bashrc only if invoked as a sub-shell.
if [[ "$(basename doxyconfig.sh)" == "$(basename -- $0)" ]] && [ -f $HOME/.bashrc ]; then
    source $HOME/.bashrc
    log_init INFO $SCRIPT_LOGS/doxyconfig.log
    # Global defines. (Re)define ENV only if necessary.
fi

OUTPUT=$(basename -- $(pwd))

# Doxygen Defaults
DEF_PRJ_NAME="$OUTPUT Project"
DEF_PRJ_NUM=0.1
DEF_PRJ_BRIEF="$OUTPUT Project Description"
DEF_GEN_HTML=YES
DEF_GEN_LATEX=YES
DEF_UML_LOOK=YES
DEF_HAVE_DOT=YES
DEF_CALL_GRAPH=YES
DEF_PERL_PATH=$(which perl)

usage()
{
    echo "usage: doxyconfig.sh <path> [PRJ_NUM GEN_HTML GEN_LATEX UML_LOOK HAVE_DOT CALL_GRAPH]"
    echo "[PRJ_NUM]       - Project version number"
    echo "[GEN_HTML]      - Generate HTML files - YES/NO"
    echo "[GEN_LATEX]     - Generate LATEX file - YES/NO"
    echo "[UML_LOOK]      - Generate UML files  - YES/NO"
    echo "[HAVE_DOT]      - Generate DOT file   - YES/NO"
    echo "[CALL_GRAPH]    - Generate Callgraph  - YES/NO"
}

# Variable names should be input without $ sign
print_vars()
{
    for var in $*; do
        log NOTE "[${var}] = [${!var}]"
    done
}

doxy_config()
{
    if [ -f ./.$OUTPUT-doxygen.cfg ]; then
        echo "Skipping .$OUTPUT-doxygen.cfg generation. Already exists."
        return
    fi

    if [ $# -eq 0 ]; then
        log DEBUG "No Options provided. Using defaults"
        use_default=1;
    elif [ $# -eq 6 ]; then          # && [ "$#" != "0" ]
        log DEBUG "Using new options provided for doxyconfig"
        use_default=0;
    else
        log DEBUG "$# Params provided, 6 needed. Using defaults"
        use_default=1;
    fi

    if [ $use_default -eq 1 ]; then
        PRJ_NUM=$DEF_PRJ_NUM; GEN_HTML=$DEF_GEN_HTML; GEN_LATEX=$DEF_GEN_LATEX;
        UML_LOOK=$DEF_UML_LOOK; HAVE_DOT=$DEF_HAVE_DOT; CALL_GRAPH=$DEF_CALL_GRAPH;
        PRJ_NAME=$DEF_PRJ_NAME; PRJ_BRIEF=$DEF_PRJ_BRIEF; PERL_PATH=$DEF_PERL_PATH;
    else
        PRJ_NUM=$1; GEN_HTML=$2; GEN_LATEX=$3; UML_LOOK=$4; HAVE_DOT=$5; CALL_GRAPH=$6;
        PRJ_NAME=$DEF_PRJ_NAME; PRJ_BRIEF=$DEF_PRJ_BRIEF; PERL_PATH=$DEF_PERL_PATH;
    fi

    log DEBUG "Doxyconfig options used are:"
    print_vars PRJ_NAME PRJ_NUM PRJ_BRIEF GEN_HTML GEN_LATEX UML_LOOK HAVE_DOT CALL_GRAPH PERL_PATH

    sed -e "s;@PROJECT_NAME@;$PRJ_NAME;" \
        -e "s;@PROJECT_NUM@;$PRJ_NUM;" \
        -e "s;@PROJECT_BRIEF@;$PRJ_BRIEF;" \
        -e "s;@GEN_HTML@;$GEN_HTML;" \
        -e "s;@GEN_LATEX@;$GEN_LATEX;" \
        -e "s;@UML_LOOK@;$UML_LOOK;" \
        -e "s;@HAVE_DOT@;$HAVE_DOT;" \
        -e "s;@CALL_GRAPH@;$CALL_GRAPH;" \
        -e "s;@PERL_PATH@;$PERL_PATH;" \
        $CUSTOM_CONFS/doxygen.cfg > ./.$OUTPUT-doxygen.cfg

    log DEBUG "Update ./.$OUTPUT-doxygen.cfg with correct PROJECT_NAME and PROJECT_BRIEF"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    [[ "$#" == "0" ]] && (usage; exit $EINVAL)

    dir_path=$1; shift;
    cdie $dir_path;
    doxy_config $*

    exit 0
}

if [ "$(basename -- $0)" == "$(basename doxyconfig.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4

