#!/bin/bash
#  DETAILS: Terraform helper script
#  CREATED: 02/08/24 12:52:52 PM +0530
# MODIFIED: 20/08/24 10:26:47 AM +0530
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2024, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin:/sbin:$PATH"

[[ ~/.bashrc.ext ]] && { source ~/.bashrc.ext; }

TF_PLAN="$PWD/tf-$(basename $PWD).plan"
TF_SHOW_ARGS="terraform.tfstate"
SSH_PVT_KEY=$HOME/.ssh/keys/id_rsa

usage()
{
    echo "Usage: tf.sh [-h|]"
    echo "Options:"
    echo "  -h              - print this help"
    echo "  -a <api_token>  - API token to use for given terraform provider"
    echo "  -d              - run terraform destroy w/ given args (use -a)"
    echo "  -i              - run terraform init"
    echo "  -k <ssh-key>    - SSH private key to use for terraform ops"
    echo "  -l              - turn on verbose logging for terraform ops"
    echo "  -p              - run terraform plan w/ given args (use -a)"
    echo "  -s              - run terraform show w/ terraform.tfstate"
    echo "  -v <VPS>        - VPS provider name"
    echo "  -y              - run terraform apply w/ given args (use -a)"
    echo "  -z              - dry run this script"
    echo "VPS: do (digitalocean), hz (hetzner)"
}

# $ eval `ssh-agent -s` && ssh ef@10.0.1.2
# Agent pid 70615
# kex_exchange_identification: Connection closed by remote host
# Connection closed by UNKNOWN port 65535
ssh_key_copy_msg()
{
    echo "Copy pvt_key to ssh jump-VM to avoid error: Connection closed by UNKNOWN port 65535";
}

set_tf_plan_args()
{
    [[ -z $API_TOKEN || -z $SSH_PVT_KEY ]] && { echo "Pass either -v or -a and -k"; exit -1; }
    TF_PLAN_ARGS="-var api_token=${API_TOKEN} -var ssh_key=${SSH_PVT_KEY}";
    #TF_PLAN_ARGS="-var do_token=${API_TOKEN} -var pvt_key=${SSH_PVT_KEY}";
}

set_vps_provider_env()
{
    case $1 in
    do)
        API_TOKEN=${DO_PAT};
        ;;
    hz)
        API_TOKEN=${HZ_PAT};
        ;;
    *)
        usage; exit -1;
    esac
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="ha:dk:ilpsv:yz"
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

    ((opt_z)) && { DRY_RUN=1; LOG_TTY=1; }
    ((opt_v)) && { set_vps_provider_env $optarg_v; }
    ((opt_a)) && { API_TOKEN=$optarg_a; }   # override vps provider default
    ((opt_k)) && { SSH_PVT_KEY=$optarg_k; } # override vps provider default
    ((opt_l)) && { export TF_LOG=1; }
    ((opt_d || opt_p)) && { set_tf_plan_args; }
    # 'terraform destroy' is alias for 'terraform apply -destroy'
    ((opt_d)) && { terraform apply -destroy $TF_PLAN_ARGS; } # && rm -rf .terraform*;
    ((opt_i)) && { terraform init; }
    ((opt_p)) && { terraform plan $TF_PLAN_ARGS -out=$TF_PLAN; }
    ((opt_y)) && { terraform apply $TF_PLAN && ssh_key_copy_msg; }
    ((opt_s || opt_y)) && { terraform show $TF_SHOW_ARGS; } # for VM IP addr
    ((opt_h)) && { usage; }

    exit 0;
}

if [ "tf.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
