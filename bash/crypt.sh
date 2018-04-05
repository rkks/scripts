#!/bin/bash
#  DETAILS: 
#  CREATED: 12/06/2017 12:44:14 AM PST
# MODIFIED: 04/04/18 18:45:28 PDT
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2017, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

# By default enable base64 encoding and salt inclusion in output
BASE64="-a";
SALT=" -salt";

usage()
{
    echo "Usage: crypt.sh [-h|]"
    echo "Options:"
    echo "  -h              - print this help"
    echo "  -c <cipher>     - cipher to use"
    echo "  -d              - decrypt input"
    echo "  -e              - encrypt input"
    echo "  -f              - file encode (not str)"
    echo "  -g              - generate random passphrase"
    echo "  -i <in_file>    - input file path"
    echo "  -o <out_file>   - output file path"
    echo "  -p <pass>       - passphrase file to use"
}

function sign()
{

# Sign a file with a private key using OpenSSL
# Encode the signature in Base64 format
#
# Usage: sign <file> <private_key>
#
# NOTE: to generate a public/private key use the following commands:
#
# openssl genrsa -aes128 -passout pass:<passphrase> -out private.pem 2048
# openssl rsa -in private.pem -passin pass:<passphrase> -pubout -out public.pem
#
# where <passphrase> is the passphrase to be used.

    filename=$1
    privatekey=$2

    if [[ $# -lt 2 ]] ; then
        echo "Usage: sign <file> <private_key>"
        exit 1
    fi

    openssl dgst -sha256 -sign $privatekey -out /tmp/$filename.sha256 $filename
    openssl base64 -in /tmp/$filename.sha256 -out signature.sha256
    rm /tmp/$filename.sha256
}

function decho() { [[ ! -z $DEBUG ]] && echo "$*"; }

# Any string with $ within should be passed as: encrypt 'str'
# Encoded key is Base64, so can be input as: decrypt <key>
function crypt()
{
    if [ ! -z $IN_FILE ]; then
        [[ ! -e $IN_FILE ]] && { echo "File: $IN_FILE does not exist"; return; }
    else
        [[ $# -ne 1 ]] && { echo "usage: crypt <str> or -i <file>"; return; }
        [[ ! -z $FILEENC ]] && { echo "usage: crypt -f -i <in-file>"; return; }
    fi

    [[ $# -eq 1 ]] && { local in="$1"; } || { local in="$(cat $IN_FILE | tr -d '\n')"; }

    decho "CIPHER:$CIPHER PASS:$PASS SALT:$SALT BASE64:$BASE64 OP:$OP IN:$IN_FILE OUT:$OUT_FILE";
    if [ ! -z $FILEENC ]; then
        [[ -z $OUT_FILE ]] && { OUT_FILE=$IN_FILE.$EXT; }
        openssl enc $CIPHER $PASS $SALT $BASE64 $OP -in $IN_FILE -out $OUT_FILE;
    else
        [[ -z $OUT_FILE ]] && { OUT_FILE=/dev/null; }
        echo "$in" | openssl enc $CIPHER $PASS $SALT $BASE64 $OP | tr -d '\n' | tee $OUT_FILE;
    fi
}

function generate_passphrase()
{
    openssl rand -base64 64 | sha256sum | base64
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="hc:degi:o:p:"
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
    ((opt_f)) && { FILEENC="1"; } || { unset FILEENC; } # input is file encoding or string?
    ((opt_c)) && { CIPHER=$optarg_c; } || { CIPHER="-des3"; }   # cipher algo to be used
    ((opt_i)) && { IN_FILE=$optarg_i; } || { unset IN_FILE; }
    ((opt_o)) && { OUT_FILE=$optarg_o; } || { unset OUT_FILE; }
    # -k is deprecated. pass:filepath points to password with which to encode
    ((opt_p)) && { [[ -e $optarg_p ]] && PASS="-pass pass:$optarg_p"; }
    #echo "PASS: $PASS CIPHER: $CIPHER IN: $IN_FILE BASE64: $BASE64";
    ((opt_e)) && { OP="-e"; EXT=enc; crypt $*; }
    ((opt_d)) && { OP="-d"; EXT=dec; crypt $*; }
    ((opt_g)) && { generate_passphrase; }

    exit 0;
}

if [ "crypt.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
