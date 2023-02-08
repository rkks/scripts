#!/bin/bash
#  DETAILS: Bash Utility Functions.
#  CREATED: 06/25/13 10:30:22 IST
# MODIFIED: 08/02/2023 04:45:22 AM
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

export FILE_MAX_SZ=10240                   # In KB
export FILE_MAX_BKUPS=1                    # max num of backup files
export LOG_LVLS=( "<DEBUG>" "<INFO>" "<NOTE>" "<WARN>" "<ERROR>" "<CRIT>" "<ALERT>" "<EMERG>" ); # RFC 5424 defines 8 levels of severity
export LOG_FILE="$SCRPT_LOGS/$(basename -- $0).log";

# {} - used for command grouping. if all commands are on single line, last command should end with a semi-colon ';'
# invoke any program with 'env -i <prog>' for clearing all ENV variables while invoking program

# export functions using 'export -f' option. $FUNCNAME has current function name in bash
function export_func() { local func; export -f $FUNCNAME; for func in $*; do export -f $func; done; }

function export_bash_funcs()
{
    local FUNCS="run shell own have cdie mkdie hostnm bail up die vid mkfile"
    FUNCS="bash_trace bash_untrace log_warn prnt term assert pause read_tty log $FUNCS"
    FUNCS="chk run_on file_sz page_brkr file_rotate bkup now myname log_init $FUNCS"
    FUNCS="puniq ppop pvalid prm pappend pprepend pshift pls source_script $FUNCS"
    FUNCS="chownall cpx dos2unixall reset_tty screentab starthttp log_lvl $FUNCS"
    FUNCS="truncate_file vncs bug rli make_workspace_alias bash_colors $FUNCS"
    FUNCS="diffscp compare show_progress get_ip_addr ssh_key ssh_pass $FUNCS"
    FUNCS="batch_run batch_mkdie log_note log_crit log_err log_dbg $FUNCS"
    FUNCS="is_func $FUNCS"
    export_func $FUNCS;
}

# Delete these. And bring in syslog filtering to echo as well.
function brb() { local pid=$!; ( while kill -0 $pid >/dev/null 2>&1; do sleep 1; done) && echo "$pid finished"; echo -e "\a"; }

# prints local date/time. date-format suitable for logs. ".%N"=NSEC, not supported on FreeBSD
# msec=$(date +"$FMT"".%N" | sed 's/......$//g');    # truncate last 6 digits: sed 's/......$//g' & sed 's/[0-9][0-9][0-9][0-9][0-9][0-9]$//g' same.
function now() { date "+%Y-%m-%d %H:%M:%S"; }

# prints script-name
function myname() { echo "$(basename -- $0)"; }

function dash_line() { local i; for i in {1..79}; do echo -n "-"; done; echo "-"; }

# $(date +%b%d%T) has display spacing issues. For line number tracing, use: $ echo "+$(echo $LINENO)" "message"
function prnt() { local m="$(now) $(hostnm) $(myname)[$$] $*"; [[ -z $STDERR ]] && echo "$m" || >&2 echo "$m"; unset STDERR; return 0; }

# prints to stderr instead of stdout
function log_warn() { log WARN $@; return 0; }

function log_crit() { log CRIT $@; return 0; }

function log_note() { log NOTE $@; return 0; }

function log_info() { log INFO $@; return 0; }

function log_alrt() { log ALERT $@; return 0; }

function log_dbg() { log DEBUG $@; return 0; }

function log_err() { log ERROR $@; return 0; }

# print input string and exit with input error value
function die() { [[ $# -ge 2 ]] && { local e=$1; shift; log_warn "$@" >&2; exit $e; } || return $EINVAL; }

# ASSERT for a positive value.
function assert() { [[ $# -ge 2 ]] && { [[ $1 -ne $2 ]] && { log_warn "ASSERT! $1 != $2. $*"; return $EASSERT; } || return 0; } || return $EINVAL; }

# bail-out if last command returned error. success == 0
function bail() { local e=$?; [[ $e -ne 0 ]] && { die $e "$! failed w/ err: $e. $*"; } || return 0; }

# usage: run <cmd> <args>. can-not check exec-perms in all inputs, some are internal cmds.
# redirect to tee will always return $? as 0. For correct retval, check PIPESTATUS[0]
function run()
{
    # time cmd returns return value of child program. And time takes time as argument and still works fine
    [[ ! -z $TIMED_RUN ]] && { local HOW_LONG="time "; }
    [[ $(type -t "$1") == function ]] && { local fname=$1; shift; log_dbg "$fname $*"; $HOW_LONG $fname "$*"; return $?; }
    local p; local a="$HOW_LONG"; for p in "$@"; do a="${a} \"${p}\""; done; test -z "$RUN_LOG" && { RUN_LOG=/dev/null; };
    log_dbg "$a"; test -n "$DRY_RUN" && { return 0; } || eval "$a" 2>&1 | tee -a $RUN_LOG 2>&1; return ${PIPESTATUS[0]};
}

# Bypass cron if input sanity chk fails. 0 is cronskip, non-zero is no-cronskip
function is_cronskip()
{
    [[ $# -ne 2 ]] && { echo "Usage: $FUNCNAME <func-name> <path>"; return 0; }
    [[ $(type -t "$1") != function ]] && { echo "Function $1 does not exists"; return 0; }
    [[ ! -d $2 ]] && { echo "$1: dir $2 does not exists"; return 0; }
    local skipname="$1"; skipname+="4$2";
    [[ -f $HOME/.cronskip.ext && ! -z "$(grep -w $skipname $HOME/.cronskip.ext)" ]] && return 0;
    [[ -f $HOME/.cronskip && ! -z "$(grep -w $skipname $HOME/.cronskip)" ]] && return 0;
    return 1;
}

# Run cmds from file in a batch. If optional function provided, call function
# with lines from file as argument
function batch_run()
{
    [[ $# -lt 1 ]] && { echo "Usage: $FUNCNAME [func-name] <cmds-file>"; return $EINVAL; }
    [[ $# -gt 1 && $(type -t "$1") != function ]] && { echo "Usage: $FUNCNAME [func-name] <cmds-file>"; return $EINVAL; }
    [[ $# -gt 1 && $(type -t "$1") == function ]] && { local fname=$1; shift; }
    [[ ! -e $1 ]] && { echo "$1: No such file found"; return $EINVAL; }
    local line=""; local rval=0; local list=$1;
    while read line; do
        [[ "$line" == \#* ]] && { continue; } || { log_note "$fname $line"; }
        [[ ! -z $CRON_RUN && ! -z $fname ]] && eval is_cronskip $fname $line && { log_note "Skip $fname for $line"; continue; }
        cdie $line && run $fname $line; [[ $? -ne 0 ]] && { rval=$?; [[ -z $CONT_ON_ERR ]] && break; }; cd -;
    done < $list
    return $rval;   # reflects if any of runs failed
}

# usage: is_func <func-name> && echo true || echo false
function is_func() { [[ $(type -t "$1") == function ]] && return 0 || return -1; }

# usage: shell <cmd> <args>
function shell() { run $SHELL $*; return $?; }

# usage: (own ls) && echo true || echo flase
function own { which "$1" &>/dev/null; }        # Error moved to /dev/null because on Solaris, 'which' cmd emits stty error

# usage: (have ls) && echo true || echo flase
function have { type -t "$1" &>/dev/null; }

# usage: cdie <path>. cd can not be passed to 'run' as eval creates sub-shell.
function cdie { chk DE EX $1 && { cd $1 && return $?; } || return $EINVAL; }

# usage: mkdie <path>. Create directory if doesn't exist, otherwise just update timestamp.
function mkdie { chk EQ 1 $# && { [[ ! -e $1 ]] && { mkdir -pv $1 && chmod 750 "$1"; return $?; } || return 0; } || return $EINVAL; }

# usage: batch_mkdie <dir-list>.
function batch_mkdie() { local dname; for dname in $*; do [[ ! -d $dname ]] && { mkdie $dname; } done; }

# create file and directory path (if doesn't exist); else just update timestamp. return no error for already existing files.
function mkfile() { chk EQ 1 $# && { [[ ! -e $1 ]] && { mkdie "$(dirname -- $1)" && touch -- $1 && chmod 640 $1; return $?; } || return 0; } || return $?; }

# encode file and send as attachment. uuencode 2nd arg is attachment filename (as appears in mail). mutt not available on FreeBSD 
function email() { [[ $# -eq 1 ]] && uuencode $1 $(basename $1) | mail -s "[ARCHIVE] Old logs" $MAILTO; }

# usage: bkup <path>
function bkup() { [[ -e $1 ]] && { local ext="$RANDOM.$(stat --printf="%Y" $1)"; mv $1 $1.$ext && gzip $1.$ext; }; }

# Bash tracing functions
# begin bash tracing
function bash_trace() { set -x; }

# end bash tracing
function bash_untrace() { set +x; }

# Check if conditions are met. If not, die.
function chk()
{
    [[ $# -ne 3 ]] && { log_warn "usage: chk <COND> <req-num-args> <input-num-args>\nCOND:LT|LE|EQ|NE|GE|GT|PE, REQ-PE|DE|FE:NE|EX"; return $EINVAL; }
    local cond=$1; local req=$2; local in=$3; local r=0; local ae="already exists"; local dne="does not exist";
    case $cond in
    LT) [[ $in -lt $req ]] && { r=0; } || { r=1; local m=" < "; }; ;;
    LE) [[ $in -le $req ]] && { r=0; } || { r=1; local m=" <= "; }; ;;
    EQ) [[ $in -eq $req ]] && { r=0; } || { r=1; local m=" == "; }; ;;
    NE) [[ $in -ne $req ]] && { r=0; } || { r=1; local m=" != "; }; ;;
    GE) [[ $in -ge $req ]] && { r=0; } || { r=1; local m=" >= "; }; ;;
    GT) [[ $in -gt $req ]] && { r=0; } || { r=1; local m=" > "; }; ;;
    PE) [[ NE == $req ]] && { [[ -e $in ]] && { r=2; n=$ae; } || r=0; } || { [[ ! -e $in ]] && { r=2; n=$dne; } || r=0; }; local m="Path"; ;;       # extra r=0 to keep bash sane
    DE) [[ NE == $req ]] && { [[ -d $in ]] && { r=2; n=$ae; } || r=0; } || { [[ ! -d $in ]] && { r=2; n=$dne; } || r=0; }; local m="Dir"; ;;
    FE) [[ NE == $req ]] && { [[ -f $in ]] && { r=2; n=$ae; } || r=0; } || { [[ ! -f $in ]] && { r=2; n=$dne; } || r=0; }; local m="File"; ;;
    esac
    [[ $r -eq 1 ]] && { log_warn "Invalid #num of args. Failed check: in($in) $m req($req)"; return $EINVAL; }
    [[ $r -eq 2 ]] && { log_warn "$m $in $n"; return $EEXIST; }
    return 0;
}

# usage: file_sz <file-path>. du -k unreliable for small files
function file_sz() { [[ $# -eq 1 ]] && { echo "$(wc -l "$1" | awk '{print $1}')"; return 0; } || return $EINVAL; }

# usage: page_brkr <num-chars>. useful to add page-breaker for new content to start. default 80 char wide.
function page_brkr() { local c=${1:-80}; local s=${2:-=}; local p; local i; for i in $(seq 1 $c); do p+="$s"; done; echo "$p" && return $?; }

# usage: file_rotate <file-path> [max-backups]. Useless: 'LOGGER=/usr/bin/logger -t logrotate'
function file_rotate()
{
    chk EQ $# 1 && { [[ ! -e $1 ]] && return $ENOENT; local file="$1"; local sz=$(file_sz $file); } || { return $EINVAL; }
    local max=0; local f=""; local i=0; local num=0; local len=$((${#file} + 1))   # len+1 to account for . in filename (as in log.1 log.2)
    [[ $sz -gt 0 ]] && { page_brkr >> $file.0; cat $file >> $file.0 && cat /dev/null > $file; }
    touch $file.0 && sz=$(file_sz $file.0) || return $?; [[ $sz -lt $FILE_MAX_SZ ]] && return 0;    # do nothing if size within limit.
    # Find out upto which sequence file.0..9 the archive has grown. ${f:$len} extracts .suffix-num. Ex. 3 for log.3
    for f in ${file}.[0-$FILE_MAX_BKUPS]*; do [ -f "$f" ] && num=${f:$len} && [ $num -gt $max ] && max=$num; done
    f="$file.$(($max + 1))";
    [[ $max -ge $FILE_MAX_BKUPS && -f "$f" ]] && { [[ ! -z $MAILTO ]] && { gzip $f && email $f.gz; rm -f $f $f.gz; } || { rm -f $f; }; }
    for ((i = $max;i >= 0;i -= 1)); do [[ -f "$file.$i" ]] && mv -f $file.$i "$file.$(($i + 1))" > /dev/null 2>&1; done
    return 0;
}

function dump_args() {
  echo -e "cmd: \"${0} ${*}\" pid: ${$} as $(whoami)"
  echo -e "\${#}:\t${#}"
  echo -e "\${*}:\t${*}"
  echo -e "\${$}:\t${$}"
  echo -e "\${?}:\t${?}"
  echo -e "\${-}:\t${-}"
  echo -e "\${$}:\t${$}"
  echo -e "\${!}:\t${!}"
  echo -e "\${0}:\t${0}"
  echo -e "\${_}:\t${_}"
}

# verified copy
function cpv()
{
    [[ -f $1 && -e $2 ]] && cp -v $1 $2; local src="$1";
    [[ -d $2 ]] && { local tgt="$2/$1"; } || { local tgt="$2"; }
    echo -n "md5sum of $src, $tgt does";
    [[ "$(md5sum $src)" != "$(md5sum $tgt)" ]] && { echo " not match"; } || { echo " match"; }
}

function hostnm() { [[ $UNAMES == *SunOS* ]] && { echo $(hostname); } || echo $(hostname -s); }

# no more cd ../../../../ just -- up 4
function up() { local d=""; for ((i=1;i<=$1;i++)); do d=../$d; done; echo "cd $d"; cd $d; }

# Coloring functions
# Colors - Enable colors for ls, etc.
function bash_colors()
{
    [[ -z $PS1_COLOR ]] && { log_warn "ps1_prompt: PS1_COLOR not set"; return $EINVAL; } || { local d; }
    d="$CUST_CONFS/dir_colors_$PS1_COLOR"; [[ -f $d ]] && { (own dircolors) && { eval $(dircolors -b $d); }; }
    [[ "$TERM" == "screen-256color" ]] && return 0;
    [[ -e $CONFS/Xdefaults ]] && { (own xrdb) && xrdb $CONFS/Xdefaults; } || return 0;
    d="$CUST_CONFS/Xresources_$PS1_COLOR"; [[ -f $d ]] && { (own xrdb) && xrdb -merge $d; }
}

function ps1_prompt()
{
    [[ -z $PS1_COLOR ]] && { log_warn "ps1_prompt: PS1_COLOR not set"; return 1; }
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
    [[ $# -eq 0 ]] && { export PS1="$Y[$U\D{%d/%b/%Y} \t$Y|$P\u$C@$P\h$Y:$G\w$Y!$C$?$Y]\r\n$R\$$N "; return 0; }
    #[[ $# -eq 0 ]] && { export PS1="$Y[$U\D{%d/%b/%Y} \t$Y|$P\u$C@$P\h$Y:$G\w$Y$(__git_ps1)!$C$?$Y]\r\n$R\$$N "; return 0; }   # __git_ps1 shows even on non-git repos

    export PS1="$Y[$U\D{%b/%d} \t$Y|$G\w$Y]\$$N "; return 0;    # short PS1
}

# toggle PS1
function ps1_toggle()
{
    [[ "$PS1_COLOR" == "light" ]] && { export PS1_COLOR=dark; } || { export PS1_COLOR=light; }
    (have ps1_prompt) && ps1_prompt; (have bash_colors) && bash_colors;
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

# given input list of files, source them
function source_script() { local us; for us in $*; do chk FE EX $us && { log_note "[SOURCE] $us"; source $us; } || { log_note "[OPTOUT] $us"; }; done; }

function pause()
{
    [[ ! -z $DRY_RUN ]] && echo -n $* "Continue (Y/n)? " || return 0;
    TIMEOUT=3; local reply=n; read -t $TIMEOUT reply; unset TIMEOUT;
    [[ "$?" == "142" ]] && { reply=y; echo $reply; }    # On Timeout choose the default answer
    [[ ! $reply =~ ^[Yy]$ ]] && die $ECANCELED "Operation Cancelled. Exiting." || { echo ""; }
}

function term()
{
    case "$UNAMES" in
        "SunOS")
            export TERM=xterm-color; ;;     # Needed for color console in Solaris. But breaks Vim (problem in vim) on other platforms.
        "FreeBSD")
            export TERM=rxvt; ;;            # Required to prevent vim leaving behind text on terminal on FreeBSD
        *)
            ;;                              # On other machines, TERM is automatically set by respective GUIs like: GNU screen/xterm.
    esac
}

# usage: run_on Mon abc.sh
# usage: run_on Mon backup_update /home/ravikiranks/conf
function run_on()
{
    [[ $# -lt 2 ]] && { return $ENOTSUP; } || { local when=$1; local fname=$2; shift; }
    [[ ! -z $CRON_RUN && ! -z "$(grep -w $fname $HOME/.cronskip)" ]] && { log_note "Skip $fname"; return; }   # skip option altogether
    case $when in
    Now)
        run $*; ;;
    Mon|Tue|Wed|Thu|Fri|Sat|Sun)
        [[ "$(date +'%a')" == "$when" ]] && { run $*; }; ;;
    Date)
        local day=$1; shift; [[ "$(date +'%d%b%Y')" == "$day" ]] && { run $*; }; ;;    # Day-of-Year: 01Apr2016
    DoM)
        local day=$1; shift; [[ "$(date +'%d%b')" == "$day" ]] && { run $*; }; ;;    # Day-of-Month: 02May
    Day)
        local day=$1; shift; [[ "$(date +'%d')" == "$day" ]] && { run $*; }; ;;    # Day of current Month: 03
    esac
    return $?;
}

# tmpfile=$(mktemp /tmp/abc-script.XXXXXX); rm $tmpfile;
function mktmp() { local f=$(mktemp); [[ $# -eq 1 ]] && cat $1 > $f || cat $TMPLTS/read_tty > $f; echo $f; }

function clean_kv() { local i; for i in "${!R[@]}"; do unset $i; done; unset R; }

function read_kv()
{
    [[ $# -ne 1 ]] && return $EINVAL || { local k; local v; local i; }
    # Only issue with below line is, unsetting vars imported is not straight forward
    #while read -r l; do declare $l; done< $F;
    declare -g -A R; while IFS="=" read -r k v; do R[$k]="$v"; done< $1;
    for i in "${!R[@]}"; do log_dbg "$i=${R[$i]}"; declare -g $i=${R[$i]}; done;
    return 0;
}

function clean_tty() { rm $F; unset F; }

function read_tty() { declare -g F; F=$(mktmp $*); ${EDITOR:-vim} $F && [[ -s $F ]] && return 0 || return $?; }

function clean_cfg() { clean_tty && clean_kv; }

# usage: read_cfg <kv-file-path>
function read_cfg() { read_tty $* && read_kv $F; }

# Logger Usage Guideline
#-----------------------
# 1. Load the source file:          source log_utils.sh
# 2. Init logger with new config:   log_init <LOG_LEVEL> <LOG_FILE>
# 3. Use logger api for logging:    log <LOG_LEVEL> "Your message here"
function log_init()
{
    [[ $# -eq 0 ]] && { return $EINVAL; } || { local LVL=$1; [[ $# -eq 2 ]] && LOG_FILE="$2"; }
    log_lvl $LVL && mkfile $LOG_FILE && file_rotate $LOG_FILE && RUN_LOG=$LOG_FILE; return $?;
}

function log_lvl()
{
    # LOG_LVLS_ON set is last step during init. log() depends on it.
    case "$1" in
        "EMERG") LOG_LVLS_ON=( "<EMERG>" ); ;;
        "ALERT") LOG_LVLS_ON=( "<ALERT>" "<EMERG>" ); ;;
        "CRIT")  LOG_LVLS_ON=( "<CRIT>" "<ALERT>" "<EMERG>" ); ;;
        "ERROR") LOG_LVLS_ON=( "<ERROR>" "<CRIT>" "<ALERT>" "<EMERG>" ); ;;
        "WARN")  LOG_LVLS_ON=( "<WARN>" "<ERROR>" "<CRIT>" "<ALERT>" "<EMERG>" ); ;;
        "NOTE")  LOG_LVLS_ON=( "<NOTE>" "<WARN>" "<ERROR>" "<CRIT>" "<ALERT>" "<EMERG>" ); ;;
        "INFO")  LOG_LVLS_ON=( "<INFO>" "<NOTE>" "<WARN>" "<ERROR>" "<CRIT>" "<ALERT>" "<EMERG>" ); ;;
        "DEBUG") LOG_LVLS_ON=( "<DEBUG>" "<INFO>" "<NOTE>" "<WARN>" "<ERROR>" "<CRIT>" "<ALERT>" "<EMERG>" ); ;;
        *) LOG_LVLS_ON=( "<INFO>" "<NOTE>" "<WARN>" "<ERROR>" "<CRIT>" "<ALERT>" "<EMERG>" ); ;; # Invalid log-level, reset to default (INFO)
    esac
    return 0;
}

# syslog style logger library for bash scripts (https://github.com/nischithbm/bash-logger, http://sourceforge.net/projects/bash-logger)
# usage: log <LOG_LVL> <log-msg>. LOG_LVL=EMERG/ALERT/CRIT/ERROR/WARN/NOTE/INFO/DEBUG
function log()
{
    [[ $# -lt 2 ]] && { return $EINVAL; } || { local s=$(echo ${LOG_LVLS[@]} | grep "<$1>"); [[ -z ${s} ]] && return $EINVAL; }
    [[ -z $LOG_LVLS_ON ]] && { return $ENOENT; } || { local is_log_lvl_on=$(echo ${LOG_LVLS_ON[@]} | grep "<$1>"); } # check if log_init() done
    [[ -z ${LOG_TTY} && -z ${is_log_lvl_on} ]] && { return 0; } || { local is_crit=$(echo ${1} | grep -E "EMERG|ALERT|CRIT"); } # filter on sev
    [[ ! -z $is_crit ]] && { STDERR=1; }; [[ ! -z $LOG_TTY ]] && prnt "$*"; prnt "$*" >> $LOG_FILE;
    return 0;
}

# grab ownership of given file/directory
function chownall() { sudo chown -R ${USER} ${1:-.}; }

# cpx : 'Expert' cp : uses tar to preserve ownership and permissions
function cpx () { [[ $# -ne 2 ]] && { echo "Usage: cpx src dest"; return $EINVAL; } || { tar cpf - $1 | (cdie $2 && tar xvpBf -); return $?; }; }

function dos2unixall() { local file; for file in $(find ${1:-.} -type f -print | xargs file | grep -v ELF | cut -d: -f1); do dos2unix $file; done; }

# fixtty : reset TTY after it has turned unusable (cat binary file to tty, scp failed, etc.). Alternate: alias r='echo -e \\033c'
function reset_tty() { stty sane; reset; [[ "$UNAMES" != "SunOS" ]] && { stty stop '' -ixoff; stty erase '^?'; }; }

# Using octal codes (ex. 0755 for dir/0644 for files) overwrites all old settings with new perms. go-rwx only affects given perms.

function screentab() { test -z $1 && { echo "usage: screentab <name>"; return $EINVAL; } || screen -t $1 bash; }

# You should be able to reach index.html through 8080 port of machine. usage: cd <doc-root> && starthttp
function starthttp() { python -m SimpleHTTPServer 8080; }

function truncate_file() { run cat /dev/null > $1; }

function vncs() { test -z $1 && { echo "usage: vncs <geometry>\nEx:1600x900,1360x760"; return $EINVAL; } || (own vncserver) && vncserver -geometry $*; }

# Enable password less login over SSH by exchanging public key to remote box
function ssh_key() { [[ ! -e $HOME/.ssh/id_rsa.pub ]] && ssh-keygen -t rsa; }
function ssh_pass() { ssh_key; local h; for h in "$@"; do echo $h; ssh $h 'cat >> ~/.ssh/authorized_keys' < $HOME/.ssh/id_rsa.pub; done; }

# development helper functions
function bug() { [[ $# -eq 0 ]] && { ls ~/work/PR/; return; } || cdie ~/work/PR/$1; }

function rli() { [[ $# -eq 0 ]] && { ls ~/work/RLI/; return; } || cdie ~/work/RLI/$1; }

# make workspace aliases. easy to jump between different workspaces
function make_workspace_alias()
{
    [[ $# -ne 1 ]] && { echo "usage: make_workspace_alias <sb-parent-dir>"; return $EINVAL; }
    [[ ! -d "$1" ]] && { echo "[ERROR] directory $1 not found"; return $ENOENT; }

    local PARENT=$1; local SB;
    for SB in $(ls $PARENT); do
        [[ "" != "$(alias $SB 2>/dev/null)" ]] && continue;     # already exists
        [[ -d "$PARENT/$SB" && -d "$PARENT/$SB/src" ]] && alias "$SB"="cd $PARENT/$SB/src";
    done
}

function vid()
{
    [[ $# -eq 0 ]] && { echo "Usage: $FUNCNAME <file-list>"; return $EINVAL; } || { local files=""; local rval=0; }
    while read files; do
        [[ "$files" == \#* ]] && { continue; } || { vim -d $files; rval=$?; }; [[ $rval -ne 0 && $# -lt 2 ]] && break;
    done < $1; return $rval;
}

# usage: diffscp <relative-dir-path> <dst-server>. GUI. if relative paths are not given, we need to do circus like: echo ${file#$1}
# CLI: ssh $2 cat $file | vim - -c ':vnew $file |windo diffthis' OR ssh $2 cat $file | diff - $file
function diffscp() { chk EQ $# 2 && { local file; for file in $(find $1 -type f); do vimdiff $file scp://$2/$file; done; } || { return $EINVAL; }; }

# usage: compare <file1> <file2>
function compare()
{
    # lengthy: cksum11=$(echo $(cksum $1) | awk -F ' ' '{print $1}'); cksum12=$(echo $(cksum $1) | awk -F ' ' '{print $2}');
    chk EQ $# 2 && { read cksum11 cksum12 file1 <<< $(cksum $1); read cksum21 cksum22 file2 <<< $(cksum $2); } || { return $EINVAL; }
    [[ $cksum11 -ne $cksum21 || $cksum12 -ne $cksum22 ]] && echo "Files $1 and $2 are different" || echo "Files $1 and $2 are identical";
    echo "Checksums:"; echo "$file1: $cksum11 $cksum12"; echo "$file2: $cksum21 $cksum22";
}

function show_progress()
{
    [[ $# -eq 1 && -f $1 ]] && { local file=$1; } || { echo "usage: show_progress <file-path>"; return; }
    local delay=0.75
    local spinstr='|/-\'
    local oldwc=0
    local newwc=$(wc -l $file | awk '{print $1}')
    while [ $newwc -gt $oldwc ]; do
        oldwc=$newwc
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
        newwc=$(wc -l $file | awk '{print $1}')
    done
    printf "    \b\b\b\b"
}

function get_ip_addr()
{
    [[ $UNAMES == "Linux" ]] && { local addr=$(ifconfig eth0 | grep -w inet | awk -F: '{print $2}' | awk '{print $1}'); echo $addr; }
    [[ $UNAMES == "Darwin" ]] && { local addr=$(ifconfig en0 | grep -w inet | awk '{print $2}'); echo $addr; }
}

function auto_mount()
{
    [[ $# -ne 3 ]] && { die "usage: automount <nfs_ip> <nfs_path> <mnt_path>"; } || { local NFS_SVR="$1:$2"; local MNT_PATH="$3"; }
    grep -q "$NFS_SVR" /etc/fstab; [[ $? != 0 ]] && { echo "$NFS_SVR   $MNT_PATH   nfs    auto  0  0" >> /etc/fstab; }
}

function mount_nfs()
{
    [[ $# -ne 3 ]] && { die "usage: mount_nfs <nfs_ip> <nfs_path> <mnt_path>"; } || { local NFS_SVR="$1:$2"; local MNT_PATH="$3"; }
    sudo ping -q -c 1 -W 1 $1 &> /dev/null; [[ $? != 0 ]] && { die "No network connectivity to NFS server from this box. Bye.."; }
    sudo dpkg -s nfs-common &> /dev/null; [[ $? != 0 ]] && { die "nfs-common pkg not present. do apt install nfs-common. Bye.."; }
    sudo mkdir -p $MNT_PATH && sudo mount -t nfs $NFS_SVR $MNT_PATH; #automount
    [[ $? -eq 0 ]] && { echo "NFS mounted at $MNT_PATH"; } || { die "NFS mount failure"; }
}

function umount_nfs() { [[ $# -ne 1 ]] && { die "usage: umount_nfs <mnt_path>"; } || { sudo umount -l $1; sudo umount -f $1; }; }

function sys_status() {
    for svc in "networking dnsmasq dbus ssh cron"; do
        sudo systemctl status $svc
    done
}

function find_grep() { [[ $# -ne 1 ]] && { echo "usage: find_grep <pattern>"; } || find . -type f -exec grep -H "$*" {} \;; }

usage()
{
    log_warn "Usage: bash_utils.sh <-h|-l <log-level> <log-message>|-r <log-file>>"
    log_warn "Options:"
    log_warn "  -l <log-level> <log-message>- log given message at given log-level"
    log_warn "  -r <log-file>               - rotate given log file"
    log_warn "  -h                          - print this help message"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    local PARSE_OPTS="hi:l:r:p"
    local opts_found=0; local opt;
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

    #log_init $LOG_FILE
    ((opt_i)) && { LOG_FILE="$*"; log_init $optarg_i $LOG_FILE; }
    ((opt_l)) && { log $optarg_l $*; }
    ((opt_r)) && { file_rotate $optarg_r; }
    ((opt_p)) && { page_brkr 10 -; }
    ((opt_h)) && (usage; exit 0)

    exit 0
}

if [ "$(basename -- $0)" == "$(basename bash_utils.sh)" ]; then
    main $*
else
    export_bash_funcs
fi
# VIM: ts=4:sw=4
