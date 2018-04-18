#!/bin/bash
#  DETAILS: 
#  CREATED: 03/01/17 14:48:09 IST
# MODIFIED: 03/01/17 14:58:12 IST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2017, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

PATH=/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin

[[ "$(basename contrail.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

usage()
{
    echo "Usage: contrail.sh [-h|]"
    echo "Options:"
    echo "  -h          - print this help"
}

install_ubuntu()
{
    sudo apt-add-repository ppa:opencontrail/ppa
    sudo apt-get update
    sudo apt-get install -y autoconf automake bison debhelper flex libcurl4-openssl-dev \
    libexpat-dev libgettextpo0 libprotobuf-dev libtool libxml2-utils make protobuf-compiler \
    python-all python-dev python-lxml python-setuptools python-sphinx ruby-ronn scons unzip \
    vim-common libsnmp-python libipfix-dev librdkafka-dev librdkafka1
    sudo apt-get install -y libboost-dev libboost-chrono-dev libboost-date-time-dev \
    libboost-filesystem-dev libboost-program-options-dev libboost-python-dev libboost-regex-dev \
    libboost-system-dev libcurl4-openssl-dev google-mock libgoogle-perftools-dev liblog4cplus-dev \
    libtbb-dev libhttp-parser-dev libxml2-dev libicu-dev
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="h"
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

    ((opt_h)) && { usage; }

    exit 0;
}

if [ "contrail.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab

