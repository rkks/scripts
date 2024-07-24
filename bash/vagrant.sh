#!/bin/bash
#  DETAILS: Helper script for Vagrant
#  CREATED: 16/01/24 10:33:18 PM +0530
# MODIFIED: 24/07/24 09:34:34 PM +0530
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2024, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

#PATH="/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin:/sbin"

export VAGRANT_DEFAULT_PROVIDER=libvirt
export VAGRANT_NO_PARALLEL=yes
#export VAGRANT_LOG=info
export VAGRANT_VAGRANTFILE=$(pwd)/Vagrantfile
VGT_OPTS="--color"

function run()
{
    # time cmd returns return value of child program. And time takes time as argument and still works fine
    [[ ! -z $TIMED_RUN ]] && { local HOW_LONG="time "; }
    [[ $(type -t "$1") == function ]] && { local fname=$1; shift; echo "$fname $*"; $HOW_LONG $fname "$*"; return $?; }
    local p; local a="$HOW_LONG"; for p in "$@"; do a="${a} \"${p}\""; done; test -z "$RUN_LOG" && { RUN_LOG=/dev/null; };
    echo "$a"; test -n "$DRY_RUN" && { return 0; } || eval "$a" 2>&1 | tee -a $RUN_LOG 2>&1; return ${PIPESTATUS[0]};
}

# Bit complicated box creation process for libvirt
bld_vgt_libvirt_box_manual()
{
    local dpath=$(mktemp -d); cd $dpath;
    sudo qemu-img convert -O qcow2 /var/lib/libvirt/images/images_$VM_NAME.img box.img;
    echo -e "{\n\t\"format\":\"qcow2\",\n\t\"provider\":\"libvirt\",\n\t\"virtual_size\":128\n}" > metadata.json;
    echo -e "{\n\t\"Author\": \"$USERNM\",\n\t\"Website\": \"https://b4cloud.wordpress.com/\",\n\t\"Artifacts\": \"https://vagrantcloud.com/b4cloud/\",\n\t\"Repository\": \"https://github.com/rkks/images/\",\n\t\"Description\": \"VM base box images, for different hypervisors\"\n}" > info.json;
    echo -e "Vagrant.configure(\"2\") do |config|\n\tconfig.vm.provider :libvirt do |lv|\n\t\tlv.driver = \"kvm\"\n\tend\nend" > Vagrantfile;
    # File path needs to be absolute path, not relative path. Else, err: "URL rejected: Bad file:// URL"
    echo -e "{\n\t\"name\": \"$VM_NAME\",\n\t\"description\": \"This box contains B4C base image off Ubuntu 22.04 64-bit.\",\n\t\"versions\": [\n\t\t{\n\t\t\t\"version\": \"0.0.1\",\n\t\t\t\"providers\": [\n\t\t\t\t{\n\t\t\t\t\t\"name\": \"libvirt\",\n\t\t\t\t\t\"url\": \"file://$dpath/$VM_NAME.box\",\n\t\t\t\t\t\"architecture\": \"amd64\",\n\t\t\t\t\t\"default_architecture\": true\n\t\t\t\t}\n\t\t\t]\n\t\t}\n\t]\n}" > catalog.json;
    tar cvzf $VM_NAME.box Vagrantfile box.img metadata.json info.json;
    return $?;
}

# https://github.com/vagrant-libvirt/vagrant-libvirt/issues/851
bld_vgt_box()
{
    run vagrant $VGT_OPTS halt $VM_NAME;
    [[ $VAGRANT_DEFAULT_PROVIDER == libvirt ]] && { bld_vgt_libvirt_box_manual; return $?; }
    [[ $VAGRANT_DEFAULT_PROVIDER == libvirt ]] && { PKG_OPTS="--output $VM_NAME.box"; export VAGRANT_LIBVIRT_VIRT_SYSPREP_OPTIONS="--run $(pwd)/images.sh -s vgtinf"; }
    [[ $VAGRANT_DEFAULT_PROVIDER == virtualbox ]] && { PKG_OPTS="--base $VM_NAME"; }
    PKG_OPTS="--vagrantfile $VAGRANT_VAGRANTFILE $PKG_OPTS";
    run vagrant $VGT_OPTS package $PKG_OPTS $VM_NAME; return $?;
}

add_vgt_box()
{
    local exists=$(vagrant box list | grep $VM_NAME | wc -l)
    [[ $exists -ne 0 ]] && { vagrant box remove $VM_NAME; }
    exists=$(virsh vol-list --pool default | grep $VM_NAME | grep vagrant_box | wc -l);
    vname=$(virsh vol-list --pool default | grep $VM_NAME | grep vagrant_box | awk -F' ' '{print $1}');
    [[ $exists -ne 0 ]] && { virsh vol-delete --pool default $vname; }
    run vagrant $VGT_OPTS box add catalog.json; return $?;
    run vagrant $VGT_OPTS box add --name $VM_NAME $VM_NAME.box; return $?;  # -f $VM_NAME
}

usage()
{
    echo "Usage: vagrant.sh [-h|-a|-c|-d|-e|-f|-g|-l|-r|-s|-t|-u|-v|-z]"
    echo "Options:"
    echo "  -h          - print this help"
    echo "  -a          - export vagrant package (use -f option)"
    echo "  -b          - list all vagrant boxes available"
    echo "  -c          - display vagrant ssh config (use -f option)"
    echo "  -d          - destroy given VM (use -v option)"
    echo "  -e          - check Vagrantfile for any errors (use -f option)"
    echo "  -f <fpath>  - relative path of Vagrantfile"
    echo "  -g          - show vagrant global-status (use -v option)"
    echo "  -l          - enable debug logging of vagrant op"
    echo "  -n          - display vagrant status (use -f option)"
    echo "  -o          - build vagrant base box (use -f, -v option)"
    echo "  -p          - pass --provision option vagrant up (use -v option)"
    echo "  -r          - reload guest VM applying Vagrantfile again (use -v option)"
    echo "  -s          - ssh into guest VM (use -v option)"
    echo "  -t          - halt given VM (use -v option)"
    echo "  -u          - do vagrant up (use -f option)"
    echo "  -v <vm-sha> - SHA of VM to perform ops on"
    echo "  -z          - dry run this script"
    echo "-f input is must for -a|-c|-u, use either -v or -f input for the rest"
    echo "log-lvl: info(-v)/debug(-vv), warn/error(quiet)"
    return 0;
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="habcdef:glnoprstuv:z"
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
    # Take argument for option -p in future, when more than 2 provider supported
    #((opt_p)) && { export VAGRANT_DEFAULT_PROVIDER=virtualbox; }
    ((opt_f)) && { export VAGRANT_VAGRANTFILE=$optarg_f; vagrant validate $VAGRANT_VAGRANTFILE; }
    # Take argument for option -l in future, when more debug options needed
    ((opt_l)) && { export VAGRANT_LOG=info; VGT_OPTS="$VGT_OPTS --debug"; }  # override vgtenv
    ((opt_v)) && { VM_NAME=$optarg_v; }
    ((opt_p)) && { VGT_UP_OPTS="--provision"; }
    ((opt_a || opt_u)) && { [[ ! -e $VAGRANT_VAGRANTFILE ]] && echo "Input valid -f <vagrantfile-path>" && exit $EINVAL; }
    [[ -f "$(dirname $VAGRANT_VAGRANTFILE)/vgtenv" ]] && { source "$(dirname $VAGRANT_VAGRANTFILE)/vgtenv"; } # override default
    ((opt_o)) && { bld_vgt_box; }
    ((opt_a)) && { add_vgt_box; }
    ((opt_b)) && { run vagrant $VGT_OPTS box list; }
    ((opt_e)) && { run vagrant $VGT_OPTS validate; }
    ((opt_r)) && { run vagrant $VGT_OPTS reload $VGT_UP_OPTS $VM_NAME; } # VM_NAME is optional
    ((opt_s)) && { run vagrant $VGT_OPTS ssh $VM_NAME; }
    ((opt_t)) && { run vagrant $VGT_OPTS halt $VM_NAME; }
    ((opt_d)) && { run vagrant $VGT_OPTS destroy -f $VM_NAME; } # -f optional
    ((opt_g)) && { run vagrant $VGT_OPTS global-status $VM_NAME; } # VM_NAME & "--prune" are optional
    ((opt_u)) && { run vagrant $VGT_OPTS up $VGT_UP_OPTS; } # no need of --debug option, $VAGRANT_LOG set
    ((opt_n)) && { run vagrant $VGT_OPTS status; }
    ((opt_c)) && { run vagrant $VGT_OPTS ssh-config; }
    ((opt_h)) && { usage; }
    unset VAGRANT_LOG;

    exit 0;
}

if [ "vagrant.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
