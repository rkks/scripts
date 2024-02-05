#!/bin/bash
#  DETAILS: tmux handler script
#  CREATED: 01/28/14 10:51:03 IST
# MODIFIED: 05/02/24 05:05:41 PM +0530
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2014, Ravikiran K.S.

# Warn unset vars as error, Verbose (echo each command), Enable debug mode
#set -uvx

# No utilities from ~/.bashrc.dev are used here, except PATH. So, only doing that.
UNAMES=$(uname -s)
export PATH=".:$HOME/scripts/bin:$HOME/tools/$UNAMES/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
SESS_DEF_NM=rk

function check_os_load()
{
    # Alternately, [[ "Linux" == "$(uname -s)" ]] && { FIELD=5; } || { FIELD=4; }
    # uptime | cut -d":" -f$FIELD | sed s/,//g | sed 's/^[[:space:]]*//'    OR
    # uptime | rev | cut -d":" -f1 | rev | sed s/,//g | sed 's/^[[:space:]]*//'
    UPTIME="$(uptime | awk '{print $(NF-2),$(NF-1),$NF}' | sed s/,//g)"
    echo "$UPTIME" #(tmux_load.sh)
}

# usage: build_session [cmds_file]
function build_session()
{
    # has-session is better, $(tmux list-sessions -F '#S' | grep -w $SESS_NM)
    tmux has-session -t $SESS_NM > /dev/null 2>&1; local rval=$?;
    [[ $rval -eq 0 ]] && { echo "session $SESS_NM already exists"; return $EINVAL; }
    tmux start-server
    [[ $# -eq 0 ]] && { tmux new-session -d -s $SESS_NM -n $SESS_NM\; return 0; }
    [[ ! -e $1 ]] && { echo "input cmds file $1 does not exist"; return $EINVAL; }
    WIN_LIST=$(cat $1 | grep -v '#' | grep $SESS_NM | awk -F. '{print $1}' | awk -F: '{print $2}' | uniq | tr '\n' ' ')
    for name in $WIN_LIST; do
        if [ -z $SESS_UP ]; then
            local SESS_UP=$SESS_NM;
            tmux new-session -d -s $SESS_NM -n $name\; split-window -h\; split-window -v\; select-pane -t 0\; split-window -v\; select-pane -t 0\;
        else
            # To cd pane to specified dir like $HOME: new-window -c ~
            tmux new-window -a -t $SESS_NM -n $name\; split-window -h\; split-window -v\; select-pane -t 0\; split-window -v\; select-pane -t 0\;
        fi
    done
}

function execute_cmds()
{
    [[ $# -ne 1 ]] && { echo "Usage: $FUNCNAME <cmd-file>"; return $EINVAL; }
    [[ ! -e $1 ]] && { echo "cmds file $1 does not exist"; return $EINVAL; }
    tmux list-sessions > /dev/null 2>&1; local rval=$?;
    [[ $rval -ne 0 ]] && { build_session $1; }
    local rval=0; local line=""; local sess=""; local cmds="";
    while read -r line; do
        [[ "$line" == \#* ]] && { continue; }
        IFS=, read -r sess cmds <<<"$line";
        # tmux send-keys -t {session}:{window}.{pane} "cmd <args>"
        tmux send-keys -t $sess "$cmds" C-m;
        rval=$?; [[ $rval -ne 0 ]] && { break; }
    done < $1
}

function show_info()
{
    tmux server-info | grep -vw "string\|missing\|number\|flag";
    echo "";
    echo "Environment:";
    tmux show-environment;
}

usage()
{
    echo "Usage: tmux.sh <-h|-a|-c|-e|-k|-l|-n <new-session-name>|-o|-r>"
    echo "Options:"
    echo "  -a              - attach to given session (pass -x for exclusive)"
    echo "  -b              - create/build new empty tmux session"
    echo "  -c              - check OS, user load on this machine"
    echo "  -e <cmd-file>   - create new tmux session & execute cmds from file"
    echo "  -i              - print tmux information on this machine"
    echo "  -k              - kill tmux server and all sessions within"
    echo "  -l              - list tmux sessions on this machine"
    echo "  -m              - list all commands supported by current tmux"
    echo "  -n <sess-name>  - use this session name for start/attach/stop"
    echo "  -r              - reload ~/.tmux.conf for current session"
    echo "  -s              - stop session with given name, all windows in it"
    echo "  -t              - start tmux server alone, no sessions "
    echo "  -x              - exclusive attach (detaches other clients)"
    echo "  -y              - list tmux key bindings of current ~/.tmux.conf"
    echo "  -h              - print this help message"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    local PARSE_OPTS="habce:iklmn:rstxy"
    local opts_found=0
    while getopts ":$PARSE_OPTS" opt; do
        case $opt in
            [a-zA-Z0-9])
                #log DEBUG "-$opt was triggered, Parameter: $OPTARG"
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

    ((opt_n)) && SESS_NM=$optarg_n || SESS_NM=$SESS_DEF_NM;
    ((opt_c)) && check_os_load;                 # check machine load
    ((opt_i)) && show_info;                     # dumps detailed tmux info
    ((opt_y)) && tmux list-keys;                # 'C-a ?' within tmux window
    ((opt_l)) && tmux list-sessions;            # list existing sessions
    ((opt_m)) && tmux list-commands;            # list commands
    ((opt_s)) && tmux kill-session -t $SESS_NM; # stop session
    ((opt_k)) && tmux kill-server;              # kill tmux server
    ((opt_t)) && tmux start-server;             # start tmux server
    ((opt_r)) && tmux source-file ~/.tmux.conf; # reload conf file
    ((opt_b)) && build_session;                 # build session
    ((opt_e)) && execute_cmds $optarg_e;        # execute tmux cmds from file
    ((opt_x)) && { XCL="-d"; }  # exclusive (detach all other clients)
    ((opt_a)) && tmux attach -t $SESS_NM $XCL; # attach to existing sess
    ((opt_h)) && { usage; exit 0; }

    exit 0
}

if [ "$(basename -- $0)" == "$(basename tmux.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
