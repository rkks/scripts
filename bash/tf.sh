#!/bin/bash
#  DETAILS: Terraform helper script
#  CREATED: 02/08/24 12:52:52 PM +0530
# MODIFIED: 12/09/24 10:54:58 PM +0530
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2024, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin:/sbin:$PATH"

[[ ~/.bashrc.ext ]] && { source ~/.bashrc.ext; }

TF_SHOW_ARGS="terraform.tfstate"
SSH_PVT_KEY=$HOME/.ssh/keys/id_rsa
VPS_PROVIDER=$(basename $PWD)
TF_ARGS=""

function bail() { local e=$?; [[ $e -ne 0 ]] && { echo "$! failed w/ err: $e." >&2; exit $e; } || return 0; }

usage()
{
    echo "Usage: tf.sh [-h|]"
    echo "Options:"
    echo "  -h              - print this help"
    echo "  -a <api_token>  - API token to use for given terraform provider"
    echo "  -c              - clean terraform artefacts and destroy resources"
    echo "  -d              - run terraform destroy w/ given args (use -a)"
    echo "  -i              - run terraform init"
    echo "  -k <ssh-key>    - SSH private key to use for terraform ops"
    echo "  -l              - turn on verbose logging for terraform ops"
    echo "  -o <os-distro>  - bring up instance w/ given base image"
    echo "  -p              - run terraform plan w/ given args (use -a)"
    echo "  -s              - run terraform show w/ terraform.tfstate"
    echo "  -t <tgt-name>   - terraform target name to bring up/down single resource"
    echo "  -v <VPS>        - VPS provider name"
    echo "  -y              - run terraform apply w/ given args (use -a)"
    echo "  -z              - dry run this script"
    echo "VPS: do (digitalocean), hz (hetzner)"
}

tf_plan_apply()
{
    # Do: terraform apply -target hcloud_server.ssheu, to bring up single VM,
    # but then also need to call for "-target hcloud_server_network.ssheu_inf"
    [[ ! -z $TF_PLAN ]] && TF_APPLY_ARGS=$TF_PLAN || TF_APPLY_ARGS=$TF_ARGS; bail;
    terraform apply $TF_APPLY_ARGS;
    # This error is seen during SSH, if SSH private key is not copied to jump-VM
    # $ eval `ssh-agent -s` && ssh ef@10.0.1.2
    # Agent pid 70615 # kex_exchange_identification: Connection closed by remote host # Connection closed by UNKNOWN port 65535
    # But copying pvt_key to SSH jump-server is cardinal sin, use ssh -J instead
    [[ $VPS_PROVIDER == lv ]] && virsh net-dhcp-leases --network default || terraform show $TF_SHOW_ARGS | grep ipv4_address;
}

tf_plan_destroy()
{
    # 'terraform destroy' is alias for 'terraform apply -destroy', but latter
    # command breaks when "-target digitalocean_droplet.ssh" is passed.
    terraform destroy $TF_ARGS; bail;
    echo "Deleted cloud resources, removing local terraform artefacts";
    [[ ! -z $CLN_TF ]] && { rm -rf terraform.* .terraform*; }
    return 0;
}

set_tf_args()
{
    [[ ! -z $API_TOKEN ]] && TF_ARGS="$TF_ARGS -var api_token=${API_TOKEN}";
    [[ ! -z $SSH_PVT_KEY ]] && TF_ARGS="$TF_ARGS -var ssh_key=${SSH_PVT_KEY}";
    [[ ! -z $TF_TGT ]] && TF_ARGS="$TF_ARGS -target ${TF_TGT}";
    [[ ! -z $OS_DISTRO ]] && TF_ARGS="$TF_ARGS -var os_distro=${OS_DISTRO}";
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
    lv)
        API_TOKEN=${LV_PAT};
        OS_DISTRO="$HOME/ws/cloud-images/ubuntu-22.04-server-cloudimg-amd64.img";
        ;;
    *)
        echo "Either pass -v or run in a directory w/ name do/hz"; exit -1;
        ;;
    esac
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="ha:cdk:ilo:pst:v:yz"
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
    ((opt_v)) && { VPS_PROVIDER=$optarg_v; }
    ((opt_a)) && { API_TOKEN=$optarg_a; }   # override vps provider default
    ((opt_c)) && { CLN_TF=1; }
    ((opt_k)) && { SSH_PVT_KEY=$optarg_k; } # override vps provider default
    ((opt_l)) && { export TF_LOG=1; }
    ((opt_o)) && { OS_DISTRO=$optarg_o; }
    ((opt_t)) && { TF_TGT=$optarg_t; }
    set_vps_provider_env $VPS_PROVIDER;
    ((opt_c || opt_d || opt_p || opt_y)) && { set_tf_args; }
    ((opt_c || opt_d)) && { tf_plan_destroy; bail; }
    ((opt_i)) && { terraform init; bail; }
    ((opt_p)) && { TF_PLAN="terraform-$VPS_PROVIDER.plan"; terraform plan $TF_ARGS -out=$TF_PLAN; bail; }
    ((opt_y)) && { tf_plan_apply; bail; }
    ((opt_s)) && { terraform show $TF_SHOW_ARGS; } # for VM IP addr
    ((opt_h)) && { usage; }

    exit 0;
}

if [ "tf.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
