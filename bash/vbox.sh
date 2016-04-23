#!/bin/bash
#  DETAILS: Virtual Box create/modify/update
#  CREATED: 03/28/16 15:13:58 IST
# MODIFIED: 04/15/16 08:10:38 IST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2016, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

[[ "$(basename vbox.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }

function create_vm()
{
    cd ~/VirtualBox\ VMs/

    # Change these variables as needed
    VM_NAME="UbuntuServer"
    UBUNTU_ISO_PATH=~/Downloads/ubuntu-14.04.1-server-amd64.iso
    VM_HD_PATH="UbuntuServer.vdi" # The path to VM hard disk (to be created).
    SHARED_PATH=~ # Share home directory with the VM

    vboxmanage createvm --name $VM_NAME --ostype Ubuntu_64 --register
    vboxmanage createhd --filename $VM_NAME.vdi --size 32768
    vboxmanage storagectl $VM_NAME --name "SATA Controller" --add sata --controller IntelAHCI
    vboxmanage storageattach $VM_NAME --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $VM_HD_PATH
    vboxmanage storagectl $VM_NAME --name "IDE Controller" --add ide
    vboxmanage storageattach $VM_NAME --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium
    $UBUNTU_ISO_PATH
    vboxmanage modifyvm $VM_NAME --ioapic on
    vboxmanage modifyvm $VM_NAME --memory 1024 --vram 128
    vboxmanage modifyvm $VM_NAME --nic1 nat
    vboxmanage modifyvm $VM_NAME --natpf1 "guestssh,tcp,,2222,,22"
    vboxmanage modifyvm $VM_NAME --natdnshostresolver1 on
    vboxmanage sharedfolder add $VM_NAME --name shared --hostpath $SHARED_PATH --automount
}

function bootup_vm()
{
    if [ $# -eq 0 ]; then
        local vms=$(VBoxManage list vms | awk '{print $1}' | sed "s/^\([\"']\)\(.*\)\1\$/\2/g");
        local cnt=$(echo $vms | wc -l);
        [[ $cnt -eq 1 ]] && { local vm=$vms; } || { return; }
    else
        local vm="$*";
    fi
    VBoxManage startvm $vm --type $VM_TYPE;
}

function poweroff_vm()
{
    if [ $# -eq 0 ]; then
        local vms=$(VBoxManage list runningvms | awk '{print $1}' | sed "s/^\([\"']\)\(.*\)\1\$/\2/g");
        local cnt=$(echo $vms | wc -l);
        [[ $cnt -eq 1 ]] && { local vm=$vms; } || { return; }
    else
        local vm="$*";
    fi
    VBoxManage controlvm $vm poweroff
}

# hibernate
function savestate_vm()
{
    VBoxManage controlvm $* savestate
}

function connect_vm()
{
    echo "1.1.1.101";                    # welcome yourself
    ssh.exp 1.1.1.101;
}

function list_vms()
{
    local name=vms;
    VBoxManage list $RUN$name
}

usage()
{
    echo "Usage: vbox.sh [-h|-b|-l|-p|-r|-s]"
    echo "Options:"
    echo "  -b <vm-name>    - boot the given virtual machine"
    echo "  -l              - list all virtual machines"
    echo "  -c <vm-name>    - connect over ssh to virtual machine"
    echo "  -p <vm-name>    - power-off the given virtual machine"
    echo "  -r              - list all running virtual machines"
    echo "  -s <vm-name>    - hibernate the given virtual machine"
    echo "  -t <type>       - gui|headless|separate. default: headless"
    echo "  -h              - print this help"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="hbclprst:"
    local opts_found=0
    while getopts ":$PARSE_OPTS" opt; do
        case $opt in
        [a-zA-Z0-9])
            log DEBUG "-$opt was triggered, Parameter: $OPTARG"
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

    ((opt_t)) && { VM_TYPE=$optarg_t; } || { VM_TYPE=headless; }
    ((opt_b)) && { bootup_vm $*; }
    ((opt_c)) && { connect_vm $*; }
    ((opt_r)) && { RUN=running; }
    ((opt_l || opt_r)) && { list_vms; }
    ((opt_p)) && { poweroff_vm $*; }
    ((opt_i)) && { savestate_vm $*; }
    ((opt_h)) && { usage; }

    exit 0;
}

if [ "vbox.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
