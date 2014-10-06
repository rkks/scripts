#!/bin/bash
#  DETAILS: Converstion utilities: base conversion, ASCII conversion
#  CREATED: 07/16/13 21:06:10 IST
# MODIFIED: 10/06/14 14:19:53 IST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

# Warn unset vars as error, Verbose (echo each command), Enable debug mode
#set -uvx

# Mathematical conversion functions
# convert from hex to decimal
function h2d() { printf '%d\n' 0x$@; }      # alternate: echo "ibase=16; obase=10; $@" | bc

# convert from decimal to hex
function d2h() { printf '%x\n' $@; }        # alternate: echo "ibase=10; obase=16; $@" | bc

# convert from hex to octal
function h2o() { printf '%o\n' 0x$@; }      # alternate: echo "ibase=16; obase=8; $@" | bc

# convert from decimal to hex
function o2h() { printf '%x\n' 0$@; }       # alternate: echo "ibase=8; obase=16; $@" | bc

# convert from hex to octal
function d2o() { printf '%o\n' $@; }        # alternate: echo "ibase=10; obase=8; $@" | bc

# convert from decimal to hex
function o2d() { printf '%o\n' 0$@; }       # alternate: echo "ibase=8; obase=10; $@" | bc

# convert from hex to binary
function h2b() { echo "ibase=16; obase=2; $@" | bc; }

# convert from decimal to binary
function d2b() { echo "ibase=10; obase=2; $@" | bc; }

# convert from octal to binary
function o2b() { echo "ibase=8; obase=2; $@" | bc; }

# convert from binary to hex
function b2h() { echo "ibase=2; obase=16; $@" | bc; }

# convert from binary to decimal
function b2d() { echo "ibase=2; obase=10; $@" | bc; }

# convert from binary to octal
function b2o() { echo "ibase=2; obase=8; $@" | bc; }

# PHP function equivalents for bash
# return character for input ASCII value (0x41 for A, etc). Inverse of ord()
function chr() { printf $(printf '\\%03o\\n' "$1"); }

# return ASCII value of input character
function ord() { printf "0x%x\n" "'$1"; }

# for ((i=; i<$1; i++))
function oneton() { [[ $# -eq 1 && $1 -le 9 ]] && { for i in $(eval echo {$1..0}); do printf "$i"; done; printf "\n"; }; }

usage()
{
    echo "usage: convert.sh [-h] -f <from-type> -t <to-type> <value>"
    echo "Options:"
    echo "  -f <from-type>      - source value type to be converted"
    echo "  -t <to-type>        - target value type to which convert"
    echo "  -h                  - print this help message"
    echo "types: [ascii(a)|binary(b)|character(c)|decimal(d)|hexadecimal(h)|octal(o)]"
    echo "Supported: a->c, c->a, b->d, b->h, b->o, d->b, d->h, d->o, h->b, h->d, h->o, o->b, o->d, o->h"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    local PARSE_OPTS="hf:t:n:"
    local opts_found=0
    while getopts ":$PARSE_OPTS" opt; do
        case $opt in
            [a-zA-Z0-9])
                #echo DEBUG "-$opt was triggered, Parameter: $OPTARG"
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

    ((!opts_found)) && { usage; exit $EINVAL; }

    ((opt_h)) && { usage; exit 0; }
    ((opt_n)) && { oneton $optarg_n; exit 0; }

    [[ $# -ne 1 ]] && { usage; exit $EINVAL; }

    case $optarg_f in
        a)
            case $optarg_t in
                c)
                    chr $1;
                    ;;
                *)
                    echo "Upsupported conversion option $optarg_t"
                    ;;
            esac
            ;;
        b)
            case $optarg_t in
                d)
                    b2d $1;
                    ;;
                h)
                    b2h $1;
                    ;;
                o)
                    b2o $1;
                    ;;
                *)
                    echo "Upsupported conversion option $optarg_t"
                    ;;
            esac
            ;;
        c)
            case $optarg_t in
                a)
                    ord $1;
                    ;;
                *)
                    echo "Upsupported conversion option $optarg_t"
                    ;;
            esac
            ;;
        d)
            case $optarg_t in
                b)
                    d2b $1;
                    ;;
                h)
                    d2h $1;
                    ;;
                o)
                    d2o $1;
                    ;;
                *)
                    echo "Upsupported conversion option $optarg_t"
                    ;;
            esac
            ;;
        h)
            case $optarg_t in
                b)
                    h2b $1;
                    ;;
                d)
                    h2d $1;
                    ;;
                o)
                    h2o $1;
                    ;;
                *)
                    echo "Upsupported conversion option $optarg_t"
                    ;;
            esac
            ;;
        o)
            case $optarg_t in
                b)
                    o2b $1;
                    ;;
                d)
                    o2d $1;
                    ;;
                h)
                    o2h $1;
                    ;;
                *)
                    echo "Upsupported conversion option $optarg_t"
                    ;;
            esac

            ;;
        *)
            echo "Upsupported conversion option $optarg_f"
            ;;
    esac

    exit 0
}

if [ "$(basename -- $0)" == "$(basename convert.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab

