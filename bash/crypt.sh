#!/bin/bash
#  DETAILS: 
#  CREATED: 12/06/2017 12:44:14 AM PST
# MODIFIED: 12/06/17 01:45:24 PST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2017, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

usage()
{
    echo "Usage: crypt.sh [-h|]"
    echo "Options:"
    echo "  -h              - print this help"
    echo "  -b              - base64 encode/decode"
    echo "  -c <cipher>     - cipher to use"
    echo "  -d              - decrypt input"
    echo "  -e              - encrypt input"
    echo "  -i <in_file>    - input file path"
    echo "  -o <out_file>   - output file path"
    echo "  -p <pass>       - passphrase to use"
}

# -k : key/pass
function encrypt_file()
{
    [[ -z $OUT_FILE ]] && { OUT_FILE=$IN_FILE.enc; }
    openssl enc $CIPHER $BASE64 -salt -e -in $IN_FILE -out $OUT_FILE $PASS;
}

function decrypt_file()
{
    [[ -z $OUT_FILE ]] && { OUT_FILE=$IN_FILE.dec; }
    openssl enc $CIPHER $BASE64 -d -in $IN_FILE -out $OUT_FILE $PASS;
}

# -a : base64 encoded/decoded
# Any string with $ within should be passed as: encrypt 'str' <salt>
function encrypt_str()
{
    [[ $# -lt 1 ]] && { echo "usage: encrypt_str <str>"; return; }
    echo "$1" | openssl enc $CIPHER $BASE64 -e $PASS;
}

# Encoded key is Base64, so can be input as: decrypt <key> <salt>
function decrypt_str()
{
    [[ $# -lt 1 ]] && { echo "usage: decrypt_str <str>"; return; }
    echo "$1" | openssl enc $CIPHER $BASE64 -d $PASS;
}

function encrypt()
{
    [[ ! -z $IN_FILE ]] && { encrypt_file $*; } || { encrypt_str $*; }
}

function decrypt()
{
    [[ ! -z $IN_FILE ]] && { decrypt_file $*; } || { decrypt_str $*; }
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="hbc:i:o:p:ed"
    local opts_found=0
    while getopts ":$PARSE_OPTS" opt; do
        case $opt in
        [a-zA-Z0-9])
            #log DEBUG "-$opt was triggered, Parameter: $OPTARG"
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
    ((opt_b)) && { BASE64="-a"; } || { unset BASE64; }
    ((opt_c)) && { CIPHER=$optarg_c; } || { CIPHER="-des3"; }
    ((opt_i)) && { IN_FILE=$optarg_i; } || { unset IN_FILE; }
    ((opt_o)) && { OUT_FILE=$optarg_o; } || { unset OUT_FILE; }
    ((opt_p)) && { PASS="-k $optarg_p"; }
    #echo "PASS: $PASS CIPHER: $CIPHER IN: $IN_FILE BASE64: $BASE64";
    ((opt_e)) && { encrypt $*; }
    ((opt_d)) && { decrypt $*; }

    exit 0;
}

if [ "crypt.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
