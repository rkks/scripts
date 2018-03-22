#!/bin/bash
#  DETAILS: 
#  CREATED: 12/06/2017 12:44:14 AM PST
# MODIFIED: 03/21/18 12:55:30 IST
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
    echo "  -a              - auto-name output file"
    echo "  -b              - base64 encode/decode"
    echo "  -c <cipher>     - cipher to use"
    echo "  -d              - decrypt input"
    echo "  -e              - encrypt input"
    echo "  -f              - file encode (not str)"
    echo "  -g              - generate random passphrase"
    echo "  -i <in_file>    - input file path"
    echo "  -o <out_file>   - output file path"
    echo "  -p <pass>       - passphrase file to use"
    echo "  -s              - include salt in output"
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

function drun()
{
    echo "$*";
    $*;
}

# -k : salt
function encrypt_file()
{
    [[ -z $OUT_FILE ]] && { OUT_FILE=$IN_FILE.enc; }
    openssl enc $CIPHER $PASS $SALT $BASE64 -e -in $IN_FILE -out $OUT_FILE;
}

function decrypt_file()
{
    [[ -z $OUT_FILE ]] && { OUT_FILE=$IN_FILE.dec; }
    openssl enc $CIPHER $PASS $SALT $BASE64 -d -in $IN_FILE -out $OUT_FILE;
}

# -a : base64 encoded/decoded
# Any string with $ within should be passed as: encrypt 'str'
function encrypt_str()
{
    [[ $# -eq 1 ]] && { local input="$1"; } || { local input="$(cat $IN_FILE)"; }
    if [ ! -z $OUT_FILE ]; then
        echo "$input" | openssl enc $CIPHER $PASS $SALT $BASE64 -e > $OUT_FILE;
    else
        echo "$input" | openssl enc $CIPHER $PASS $SALT $BASE64 -e;
    fi
}

# Encoded key is Base64, so can be input as: decrypt <key>
function decrypt_str()
{
    [[ $# -eq 1 ]] && { local input="$1"; } || { local input="$(cat $IN_FILE)"; }
    if [ ! -z $OUT_FILE ]; then
        echo "$input" | openssl enc $CIPHER $PASS $SALT $BASE64 -d > $OUT_FILE;
    else
        echo "$input" | openssl enc $CIPHER $PASS $SALT $BASE64 -d | tr -d '\n';
    fi
}

function encrypt()
{
    if [ ! -z $IN_FILE ]; then
        [[ ! -z $AUTONAME ]] && [[ -z $OUT_FILE ]] && OUT_FILE="$IN_FILE.enc";
        [[ ! -e $IN_FILE ]] && { echo "File: $IN_FILE does not exist"; return; }
    else
        [[ $# -ne 1 ]] && { echo "usage: encrypt <str> or -i <file>"; return; }
        [[ ! -z $FILEENC ]] && { echo "usage: encrypt -f -i <in-file>"; return; }
    fi
    [[ ! -z $FILEENC ]] && { encrypt_file $*; } || { encrypt_str $*; }
}

function decrypt()
{
    if [ ! -z $IN_FILE ]; then
        [[ ! -z $AUTONAME ]] && [[ -z $OUT_FILE ]] && OUT_FILE="$IN_FILE.dec";
        [[ ! -e $IN_FILE ]] && { echo "File: $IN_FILE does not exist"; return; }
    else
        [[ $# -ne 1 ]] && { echo "usage: encrypt <str> or -i <file>"; return; }
        [[ ! -z $FILEENC ]] && { echo "usage: encrypt -f -i <in-file>"; return; }
    fi
    [[ ! -z $FILEENC ]] && { decrypt_file $*; } || { decrypt_str $*; }
}

function generate_passphrase()
{
    openssl rand -base64 64 | sha256sum | base64
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="habc:degi:o:p:s"
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
    ((opt_a)) && { AUTONAME="1"; } || { unset AUTONAME; }  # auto-names output file-name
    ((opt_b)) && { BASE64="-a"; } || { unset BASE64; }  # base64 encoding of output or not?
    ((opt_s)) && { SALT=" -salt"; } || { unset SALT; }  # include salt in output or not?
    ((opt_f)) && { FILEENC="1"; } || { unset FILEENC; } # input is file encoding or string?
    ((opt_c)) && { CIPHER=$optarg_c; } || { CIPHER="-des3"; }   # cipher algo to be used
    ((opt_i)) && { IN_FILE=$optarg_i; } || { unset IN_FILE; }
    ((opt_o)) && { OUT_FILE=$optarg_o; } || { unset OUT_FILE; }
    # -k is deprecated. pass:filepath points to password with which to encode
    ((opt_p)) && { [[ -e $optarg_p ]] && PASS="-pass pass:$optarg_p"; }
    #echo "PASS: $PASS CIPHER: $CIPHER IN: $IN_FILE BASE64: $BASE64";
    ((opt_e)) && { encrypt $*; }
    ((opt_d)) && { decrypt $*; }
    ((opt_g)) && { generate_passphrase; }

    exit 0;
}

if [ "crypt.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
