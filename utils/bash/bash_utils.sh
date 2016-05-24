#!/bin/bash
#  DETAILS: Bash Utility Functions.
#  CREATED: 06/25/13 10:30:22 IST
# MODIFIED: 05/16/16 09:37:07 PDT
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

#set -uvx                   # Warn unset vars as error, Verbose (echo each command), Enable debug mode

# Error codes from Solaris /usr/include/sys/errno.h
export EPERM=1       # Not a super user
export ENOENT=2      # No such file or directory
export E2BIG=7       # Arg list too long
export ENOEXEC=8     # No exec permissions
export EAGAIN=11     # Resource temporarily unavailable
export ENOMEM=12     # Not enough memory
export EACCES=13     # Permission denied
export EEXIST=17     # File already exists
export ENOTDIR=20    # Not a directory
export EISDIR=21     # Is a directory
export EINVAL=22     # Invalid argument
export ERANGE=34     # Math range error
export ECANCELED=47  # Operation cancelled
export ENOTSUP=48    # Operation not supported
export EOVERFLOW=79  # variable overflow
export ETIMEDOUT=145 # Operation timedout
export EASSERT=199   # Assertion failed

# {} - used for command grouping. if all commands are on single line, last command should end with a semi-colon ';'
# invoke any program with 'env -i <prog>' for clearing all ENV variables while invoking program

# export functions using 'export -f' option. $FUNCNAME has current function name in bash
function export_func() { local func; export -f $FUNCNAME; for func in $*; do export -f $func; done; }

function export_bash_funcs()
{
    local FUNCS="run shell own have cdie mkdie hostname_short fail_bail up die via"
    FUNCS="bash_trace bash_untrace becho decho term assert pause ret_chk $FUNCS"
    FUNCS="puniq ppop pvalid prm pappend pprepend pshift pls source_script $FUNCS"
    export_func $FUNCS;
}

# usage: run <cmd> <args>
function run() { [[ "yes" == "$SHDEBUG" ]] && echo "$*"; $*; return $?; }

# usage: shell <cmd> <args>
function shell() { [[ "yes" == "$SHDEBUG" ]] && echo "$(pwd)\$ $*" || "$SHELL $*"; return $?; }

# usage: (own ls) && echo true || echo flase
function own { which "$1" &>/dev/null; }        # Error moved to /dev/null because on Solaris, 'which' cmd emits stty error

# usage: (have ls) && echo true || echo flase
function have { type -t "$1" &>/dev/null; }

# usage: cdie <path>
function cdie { [[ -d $1 ]] && cd $1 || die $EINVAL "Path $1 doesn't exist. Quitting!"; }

# usage: mkdie <path>
function mkdie { [[ -e $1 ]] && die $EINVAL "Path $1 already exists" || mkdir -pv $1; }

# Bash tracing functions
# begin bash tracing
function bash_trace() { set -x; }

# end bash tracing
function bash_untrace() { set +x; }

# verified copy
function cpv()
{
    [[ -f $1 && -e $2 ]] && cp -v $1 $2; local src="$1";
    [[ -d $2 ]] && { local tgt="$2/$1"; } || { local tgt="$2"; }
    echo -n "md5sum of $src, $tgt does";
    [[ "$(md5sum $src)" != "$(md5sum $tgt)" ]] && { echo " not match"; } || { echo " match"; }
}

function hostname_short() { [[ $UNAMES == *SunOS* ]] && { echo $(hostname); } || echo $(hostname -s); }

# bail-out if last command returned error. success == 0
function fail_bail() { [[ $? -ne 0 ]] && { die $? "$! returns error $?"; } || return; }

# no more cd ../../../../ just -- up 4
function up() { local d=""; for ((i=1;i<=$1;i++)); do d=../$d; done; echo "cd $d"; cd $d; }

# Coloring functions
# Colors - Enable colors for ls, etc.
function bash_dircolors()
{
    [[ -z $PS1_COLOR ]] && { echo "ps1_prompt: PS1_COLOR not set"; return 1; }
    local d="$CUST_CONFS/dir_colors_$PS1_COLOR"; [[ ! -f $d ]] && { return 1; }
    (own dircolors) && { eval $(dircolors -b $d); return 0; }
}

function ps1_prompt()
{
    [[ -z $PS1_COLOR ]] && { echo "ps1_prompt: PS1_COLOR not set"; return 1; }
    # B=BLACK, W=WHITE, Y=YELLOW, R=RED, G=GREEN, P=PURPLE, U=BLUE, C=CYAN, N=NO COLOR
    local N="\[\033[0m\]";
    case $PS1_COLOR in
    dark)
        local B="\[\033[1;30m\]"; local R="\[\033[1;31m\]"; local G="\[\033[1;32m\]"; local Y="\[\033[1;33m\]";
        local U="\[\033[1;34m\]"; local P="\[\033[1;35m\]"; local C="\[\033[1;36m\]"; local W="\[\033[1;37m\]";
        ;;
    *)
        local B="\[\033[0;30m\]"; local R="\[\033[0;31m\]"; local G="\[\033[0;32m\]"; local Y="\[\033[0;33m\]";
        local U="\[\033[0;34m\]"; local P="\[\033[0;35m\]"; local C="\[\033[0;36m\]"; local W="\[\033[0;37m\]";
        ;;
    esac
    # default/long PS1. To know hex-code for UFT-8 char, do: echo <char> | hexdump -C; First byte is always e2.
    # `echo -e '\xe2\x86\x92'` causes more problems on terminal. Not every terminal/bash is UTF-8 capable.
    [[ $# -eq 0 ]] && { export PS1="$B[$U\D{%d/%b/%Y} \t$B|$P\u$Y@$P\h$B:$G\w$B!$C$?$B]\r\n$R\$$N "; return 0; }

    export PS1="$B[$U\D{%b/%d} \t$B|$G\w$B]\$$N "; return 0;    # short PS1
}

# toggle PS1
function ps1_toggle()
{
    [[ "$PS1_COLOR" == "light" ]] && { export PS1_COLOR=dark; } || { export PS1_COLOR=light; }
    (have ps1_prompt) && ps1_prompt; (have bash_dircolors) && bash_dircolors;
}

# Path management functions
# Usage: pls [<var>]. List entries of PATH or env var <var>. Alternate: alias p='echo -e ${PATH//:/\\n}'
function pls() { eval echo \$${1:-PATH} | tr : '\n'; }

# Usage: pappend <path> [<var>]. Append <path> to PATH or environment variable <var>.
function pappend() { eval "${2:-PATH}='$(eval echo \$${2:-PATH})':$1"; }

# Usage: pprepend <path> [<var>]. Prepend <path> to PATH or environment variable <var>.
function pprepend() { eval "${2:-PATH}='$1:$(eval echo \$${2:-PATH})'"; }

# Usage: prm <path> [<var>]. Remove <path> from PATH or environment variable <var>.
function prm () { eval "${2:-PATH}='$(pls ${2:-PATH} |grep -v "^$1\$" |tr '\n' :)'"; }

# Remove duplicate entries from a PATH style value while retaining the original order.
# Example: $ puniq /usr/bin:/usr/local/bin:/usr/bin     Output: /usr/bin:/usr/local/bin
function puniq() { echo "$1" | tr : '\n' | uniq | tr '\n' : | sed -e 's/:$//' -e 's/^://'; }

# Usage: pshift [-n <num>] [<var>]. Shift <num> entries off the front of environment <var>. Useful: pshift $(pwd)
function pshift () {
    local n=1
    [ "$1" = "-n" ] && { n=$(( $2 + 1 )); shift 2; }
    eval "${1:-PATH}='$(pls $1 |tail -n +$n |tr '\n' :)'"
}

# Usage: ppop [-n <num>] [<var>]. Pop <num> entries off the end of PATH or environment variable <var>.
function ppop () {
    local n=1 i=0
    [ "$1" = "-n" ] && { n=$2; shift 2; }
    while [ $i -lt $n ]; do eval "${1:-PATH}='\${${1:-PATH}%:*}'"; i=$(( i + 1 )); done
}

# Usage: pvalid <var>. Validate each entry in input env variable or PATH and rearrange valid ones in same order.
function pvalid()
{
    local tmp_path=.; local loc;
    for loc in $(eval echo \${${1:-PATH}} | tr : ' '); do
        [[ ! -d "$loc" ]] && continue;
        [[ $tmp_path == *":$loc"* ]] && continue || tmp_path="$tmp_path:$loc";
    done
    tmp_path=$(echo $tmp_path | tr : '\n' | uniq | tr '\n' : )
    eval "${1:-PATH}=$tmp_path"; unset tmp_path;
}

# bash scripting helper functions
# $(date +%b%d%T) has display spacing issues. For line number tracing, use: $ becho "+$(echo $LINENO)" "message"
function becho() { echo $(date +"%Y-%m-%d %H:%M:%S") $(hostname_short) $(basename -- $0)[$$]: $*; }

function decho() { [[ "yes" == "$SHDEBUG" ]] && becho "$*"; }

# Flag error if last command was unsuccessful. Ex: $ cmd <opts>; ret_chk
function ret_chk() { local ret=$?; [[ $ret -ne 0 ]] && becho "[ERROR] Command Failure. ret=$ret"; }

# given input list of files, source them
function source_script()
{
    local us;   # user script
    [[ "yes" == "$SHDEBUG" ]] && { local level=CRIT; } || { local level=NOTE; }
    [[ ! -z $LOG_LEVELS_ENABLED ]] && { local cmd=log; } || { local cmd=decho; }
    for us in $*; do
        [[ ! -f $us ]] && { $cmd $level "[OPTOUT] $us"; return $ENOENT; } || { source $us; $cmd $level "[SOURCE] $us"; }
    done
}

# print input string and exit with input error value
function die()
{
    [[ $# -lt 2 ]] && { echo "usage: die <errno> <err-str>"; return $EINVAL; } || { local err=$1; shift; becho $@ >&2; exit $err; }
}

# ASSERT for a positive value.
function assert()
{
    [[ $# -lt 1 ]] && { echo "usage: assert <value>"; return $EINVAL; }
    [[ ! $1 ]] && die $EASSERT "Assertion failed - $1";      # if error, die. else return & continue executing script
}

function pause()
{
    [[ "yes" == "$SHDEBUG" ]] && echo -n $* "Continue (Y/n)? " || return;
    TIMEOUT=3; local reply=y; read -t $TIMEOUT reply; unset TIMEOUT;
    [[ "$?" == "142" ]] && { reply=y; echo $reply; }    # On Timeout choose the default answer
    [[ "$reply" == "n" ]] && die $ECANCELED "Operation Cancelled. Exiting." || { echo ""; }
}

function term()
{
    case "$UNAMES" in
        "SunOS")
            # Needed for color console in Solaris. But breaks Vim (problem in vim)
            # on other platforms.
            export TERM=xterm-color;
            ;;
        "FreeBSD")
            # Required to prevent vim leaving behind text on terminal on FreeBSD
            export TERM=rxvt;
            ;;
        *)
            # On other machines, TERM is automatically set by respective GUIs like
            # GNU screen/xterm.
            ;;
    esac
}

function via() { local file; for file in $*;do vim $file; done; }

function run_on()
{
    local when=$1; shift;
    case $when in
    Now)
        run "$*";
        ;;
    Mon|Tue|Wed|Thu|Fri|Sat|Sun)
        [[ "$(date +'%a')" == "$when" ]] && { run "$*"; }
        ;;
    Date)
        local day=$1; shift;        # Day-of-Year: 01Apr2016
        [[ "$(date +'%d%b%Y')" == "$day" ]] && { run "$*"; }
        ;;
    DoM)
        local day=$1; shift;        # Day-of-Month: 02May
        [[ "$(date +'%d%b')" == "$day" ]] && { run "$*"; }
        ;;
    Day)
        local day=$1; shift;        # Day of current Month: 03
        [[ "$(date +'%d')" == "$day" ]] && { run "$*"; }
        ;;
    esac
}

usage()
{
    echo "usage: bash_utils.sh []"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    if [ "$#" == "0" ]; then
        usage
        exit 1
    fi

    case $1 in
        *)
            usage
            ;;
    esac
    exit 0
}

if [ "$(basename -- $0)" == "$(basename bash_utils.sh)" ]; then
    main $*
else
    export_bash_funcs
fi
# VIM: ts=4:sw=4

#source_utils() { }
#main() { source_utils; exit 0; }
#[[ "$(basename $0)" == "$(basename utils.sh)" ]] && main $* || source_utils
