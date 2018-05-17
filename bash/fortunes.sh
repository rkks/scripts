#!/bin/bash
#  DETAILS: prints funny motd (message of the day) messages.
# Print on the login by calling this script from /etc/motd.tail or elsewhere by 
# calling this script directly. It also helps creates forture db out of txt file
#
#  CREATED: 04/06/18 13:38:31 PDT
# MODIFIED: 26/Apr/2018 16:30:31 PDT
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2018, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

# Fortune options
# /usr/games/fortune -f             // print list of files searched for quote
# /usr/games/fortune -c             // show cookie from which quote was picked
# /usr/games/fortune -e             // consider all files of equal size
#
# Steps to publish own quotes:
# - Write quotes into plain txt file in below format. default-file-name:fortune
# <quote>
# - <person>
# %                                 // quote separator
# Example:
# A day for firm decisions!!!!!  Or is it?
# - unknown
# %
#    - Refer to /usr/share/games/fortunes/fortunes for more
# - Create index file: $ strfile -c % <your-fortune-file> <your-fortune-file.dat>
# - Move both text and index files to /usr/share/games/fortunes/

PATH="/usr/games:/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin"

usage()
{
    echo "Usage: fortunes.sh [-h|]"
    echo "Options:"
    echo "  -h          - print this help"
}

function tell_fortune() { exec /usr/games/fortune | /usr/games/cowsay -n; return 0; }
function fortune_convert() { strfile -c % $1 $1.dat; return 0; }

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
        tell_fortune;
    fi

    ((opt_h)) && { usage; }

    exit 0;
}

if [ "fortunes.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
