#!/bin/bash
#  DETAILS: QEMU helper script to manage life-cycle of KVM VMs using cloud-init
# provisioner, cloud-images, and libvirt tools.
#  CREATED: 24/07/24 03:54:36 PM +0530
# MODIFIED: 24/07/24 09:32:27 PM +0530
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2024, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin:/sbin"
CI_VM_NUM_CPU=2
CI_VM_RAM_SZ=4096
CI_DISK_SIZE=16G
CI_SSH_PUBKEY=~/.ssh/id_ed25519.pub
CI_IMG_LOC=$HOME/ws/cloud-images
CI_IMG_URL="https://cloud-images.ubuntu.com/releases/jammy/release/ubuntu-22.04-server-cloudimg-amd64.img"
CI_IMG_FNAME=$(basename $CI_IMG_URL)
CI_IMG_FPATH=$CI_IMG_LOC/$CI_IMG_FNAME
CI_IMG_EXT=${CI_IMG_FPATH##*.}
# Vagrant NAT bridge w/ pvt IP address subnet 192.168.122.0/24
CI_PVT_BR=virbr0

USERNM=ef
PASSWD=ef123
USRID=1000
GRPID=1000
USER_HOME=/home/$USERNM

function run()
{
    # time cmd returns return value of child program. And time takes time as argument and still works fine
    [[ ! -z $TIMED_RUN ]] && { local HOW_LONG="time "; }
    [[ $(type -t "$1") == function ]] && { local fname=$1; shift; echo "$fname $*"; $HOW_LONG $fname "$*"; return $?; }
    local p; local a="$HOW_LONG"; for p in "$@"; do a="${a} \"${p}\""; done; test -z "$RUN_LOG" && { RUN_LOG=/dev/null; };
    echo "$a"; test -n "$DRY_RUN" && { return 0; } || eval "$a" 2>&1 | tee -a $RUN_LOG 2>&1; return ${PIPESTATUS[0]};
}

write_user_data()
{
    local pubkey=$(cat ${CI_SSH_PUBKEY})
    echo -e "#cloud-config" > user-data;    # First line must be #cloud-config
    echo -e "hostname: ${CI_VM_HOSTNM}" >> user-data
    echo -e "fqdn: ${CI_VM_HOSTNM}" >> user-data
    echo -e "manage_etc_hosts: true" >> user-data
    echo -e "users:" >> user-data
    echo -e "  - name: ${USERNM}" >> user-data
    echo -e "    sudo: ALL=(ALL) NOPASSWD:ALL" >> user-data
    echo -e "    groups: users, admin, sudo" >> user-data
    echo -e "    home: ${USER_HOME}" >> user-data
    echo -e "    shell: /bin/bash" >> user-data
    echo -e "    lock_passwd: false" >> user-data
    echo -e "    ssh-authorized-keys:" >> user-data
    echo -e "      - $pubkey" >> user-data
    echo -e "" >> user-data
    echo -e "# both cert auth as well as passwd auth via ssh " >> user-data
    echo -e "ssh_pwauth: true" >> user-data
    echo -e "disable_root: false" >> user-data
    echo -e "chpasswd:" >> user-data
    echo -e "  list: |" >> user-data
    echo -e "     ${USERNM}:${PASSWD}" >> user-data
    echo -e "  expire: false" >> user-data
    echo -e "package_update: true" >> user-data
    echo -e "packages:" >> user-data
    echo -e "  - qemu-guest-agent" >> user-data
    echo -e "" >> user-data
    echo -e "# add network config for both public, private infs " >> user-data
    echo -e "write_files:" >> user-data
    echo -e "- path: /etc/cloud/cloud.cfg.d/99-custom-networking.cfg" >> user-data
    echo -e "  permissions: '0644'" >> user-data
    echo -e "  content: |" >> user-data
    echo -e "      network: {config: disabled}" >> user-data
    echo -e "- path: /etc/netplan/my-new-config.yaml" >> user-data
    echo -e "  permissions: '0644'" >> user-data
    echo -e "  content: |" >> user-data
    echo -e "    network:" >> user-data
    echo -e "      version: 2" >> user-data
    echo -e "      ethernets:" >> user-data
    echo -e "        ens3:" >> user-data
    echo -e "          addresses:" >> user-data
    echo -e "            - 192.168.1.${CI_VM_IP_LSB}/24" >> user-data
    echo -e "          nameservers:" >> user-data
    echo -e "            #search: [example.com]" >> user-data
    echo -e "            addresses: [1.1.1.1, 8.8.4.4]" >> user-data
    echo -e "          routes:" >> user-data
    echo -e "            - to: default" >> user-data
    echo -e "              via: 192.168.1.1" >> user-data
    echo -e "        ens4:" >> user-data
    echo -e "          addresses:" >> user-data
    echo -e "            - 192.168.122.${CI_VM_IP_LSB}/24" >> user-data
    echo -e "          routes:" >> user-data
    echo -e "            - to: default" >> user-data
    echo -e "              via: 192.168.122.1" >> user-data
    echo -e "" >> user-data
    echo -e "# Configure where output will go" >> user-data
    echo -e "output:" >> user-data
    echo -e "  all: \">> /var/log/cloud-init.log\"" >> user-data
    echo -e "" >> user-data
    echo -e "# configure interaction with ssh server" >> user-data
    echo -e "ssh_genkeytypes: ['ed25519', 'rsa']" >> user-data
    echo -e "" >> user-data
    echo -e "# set timezone for VM" >> user-data
    echo -e "timezone: Asia/Kolkata" >> user-data
    echo -e "" >> user-data
    echo -e "# disable cloud-init from running provision again" >> user-data
    echo -e "runcmd:" >> user-data
    echo -e "  - rm /etc/netplan/50-cloud-init.yaml" >> user-data
    echo -e "  - netplan generate" >> user-data
    echo -e "  - netplan apply" >> user-data
    echo -e "  - apt -y remove cloud-init" >> user-data
    echo -e "# written to /var/log/cloud-init-output.log" >> user-data
    echo -e "final_message: \"It took OS \$UPTIME seconds to come up.\"" >> user-data
}

bld_cidata_iso()
{
    [[ -e meta-data ]] && { echo "meta-data file already exists"; exit -1; }
    [[ -e user-data ]] && { echo "user-data file already exists"; exit -1; }
    [[ -e ${CI_VM_HOSTNM}-cidata.iso ]] && { echo "${CI_VM_HOSTNM}-cidata.iso file already exists"; exit -1; }

    echo -e "instance-id: ${CI_VM_HOSTNM}\nlocal-hostname: ${CI_VM_HOSTNM}" > meta-data;
    write_user_data;

    # -V/-volid: volume ID
    # -r/-rational-rock: relaxed Rock Ridge protocol for ISO file naming
    # -J/-joliet: generate Jolier directory records along w/ file names
    genisoimage -output ${CI_VM_HOSTNM}-cidata.iso -V cidata -r -J user-data meta-data

    # Instead of genisoimage, cloud-localds cmd can also be used to generate iso
    # https://manpages.ubuntu.com/manpages/jammy/en/man1/cloud-localds.1.html

    return $?;
}

print_vm_ip()
{
    [[ -z $CI_VM_HOSTNM ]] && { echo "Pass -n option with -t argument"; exit -1; }

    local macaddr=$(virsh -q domiflist ${CI_VM_HOSTNM} | awk '{ print $5 }')
    arp -e | grep -i $macaddr | awk '{ print $1 }'
}

teardown_vm()
{
    [[ -z $CI_VM_HOSTNM ]] && { echo "Pass -n option with -t argument"; exit -1; }
    [[ ! -e $CI_VM_HOSTNM.$CI_IMG_EXT || ! -e ${CI_VM_HOSTNM}.xml ]] && { echo "run this cmd from init directory"; exit -1; }
    [[ ! -e ${CI_VM_HOSTNM}-cidata.iso || ! -e meta-data || ! -e user-data ]] && { echo "run this cmd from init directory"; exit -1; }

    virsh destroy "${CI_VM_HOSTNM}"
    virsh undefine "${CI_VM_HOSTNM}"
    rm -vf $CI_VM_HOSTNM.$CI_IMG_EXT meta-data user-data ${CI_VM_HOSTNM}-cidata.iso; ${CI_VM_HOSTNM}.xml;
    local vol;
    for vol in $(virsh vol-list --pool cloud-init | grep $(basename $PWD) | awk '{print $1}'); do
        virsh vol-delete --pool $(basename $PWD) $vol;
    done
}

setup_vm()
{
    [[ -z $CI_VM_HOSTNM ]] && { echo "Pass -n option with -s argument"; exit -1; }

    [[ ! -z $CI_VM_MACADDR ]] && { local virtopts="--mac $CI_VM_MACADDR"; }
    bld_cidata_iso || exit -1;
    # --hvm/-v: full virtualization, default for QEMU
    virt-install --name="${CI_VM_HOSTNM}" \
        --network "bridge=${CI_PUB_BR},model=virtio" \
        --network "bridge=${CI_PVT_BR},model=virtio" \
        $virtopts --import \
        --disk "path=$PWD/${CI_VM_HOSTNM}.${CI_IMG_EXT},format=qcow2" \
        --disk "path=$PWD/${CI_VM_HOSTNM}-cidata.iso,device=cdrom" \
        --ram="${CI_VM_RAM_SZ}" --vcpus="${CI_VM_NUM_CPU}" --check-cpu \
        --autostart --arch x86_64 --accelerate \
        --osinfo detect=on,require=off --debug --force \
        --watchdog=default --graphics vnc,listen=0.0.0.0 --noautoconsole
    virsh dumpxml "${CI_VM_HOSTNM}" > "${CI_VM_HOSTNM}.xml"
    virsh list --all;
}

function clone_img()
{
    local isqcow=$(file -b $CI_IMG_FPATH | grep -i qcow | wc -l)
    [[ $isqcow -eq 0 ]] && { echo "Only qcow2 supported for cloning"; exit -1; }
    [[ -e $CI_VM_HOSTNM.$CI_IMG_EXT ]] && { echo "$CI_VM_HOSTNM.$CI_IMG_EXT already exists"; return 0; }
    qemu-img create -b $CI_IMG_FPATH -f qcow2 -F qcow2 $CI_VM_HOSTNM.$CI_IMG_EXT $CI_DISK_SIZE;
    return $?;
}

function copy_img()
{
    [[ -e $CI_VM_HOSTNM.$CI_IMG_EXT ]] && { echo "$CI_VM_HOSTNM.$CI_IMG_EXT already exists"; return 0; }
    cp -v $CI_IMG_FPATH $CI_VM_HOSTNM.$CI_IMG_EXT;
}

function convert_img_to_raw()
{
    local isqcow=$(file -b $CI_IMG_FPATH | grep -i qcow | wc -l)
    [[ $isqcow -eq 0 ]] && { echo "Only qcow2 supported for converting"; exit -1; }
    local fname=${CI_IMG_FNAME%.*}
    qemu-img convert -f raw -O qcow2 $CI_IMG_FPATH $CI_IMG_LOC/$fname.raw;
    CI_IMG_EXT=raw; CI_IMG_FNAME=$fname.$CI_IMG_EXT; CI_IMG_FPATH=$CI_IMG_LOC/$CI_IMG_FNAME;
}

usage()
{
    echo "Usage: qemu.sh [-h|]"
    echo "Options:"
    echo "  -h              - print this help"
    echo "  -a              - print given VM (IP) address"
    echo "  -b <br-name>    - connect VM WAN to given bridge"
    echo "  -c <num-cpus>   - number of vCPUs in VM"
    echo "  -d <disk-sz>    - size of disk attached to VM"
    echo "  -i <vm-ip-byte> - WAN IP address LSByte for VM (in 192.168.1.0/24)"
    echo "  -l <img-loc>    - location where base images of VM are stored"
    echo "  -m <mac-addr>   - config MAC addr of VM WAN to given value"
    echo "  -n <host-nm>    - config hostname of VM to given value"
    echo "  -p <ssh-pubkey> - add given SSH public key to authorized_keys"
    echo "  -q              - qcow2 clone $CI_IMG_FPATH => $CI_VM_HOSTNM.$CI_IMG_EXT (needs -n)"
    echo "  -r <ram-sz>     - size of RAM in the VM"
    echo "  -s              - setup new VM w/ given parameters"
    echo "  -t              - teardown VM w/ given name"
    echo "  -u <img-url>    - HTTP URL to download base image from"
    echo "  -w              - convert image to raw file format"
    echo "  -z              - dry run this script"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="hab:c:d:i:l:m:n:p:r:stu:wz"
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
    ((opt_b)) && { CI_PUB_BR=$optarg_b; }
    ((opt_c)) && { CI_VM_NUM_CPU=$optarg_c; }
    ((opt_d)) && { CI_DISK_SIZE=$optarg_d; }
    ((opt_i)) && { CI_VM_IP_LSB="$optarg_i"; }
    ((opt_l)) && { CI_IMG_LOC="$optarg_l"; }
    ((opt_m)) && { CI_VM_MACADDR=$optarg_m; }
    ((opt_n)) && { CI_VM_HOSTNM=$optarg_n; }
    ((opt_p)) && { CI_SSH_PUBKEY=$optarg_p; }
    ((opt_r)) && { CI_VM_RAM_SZ=$optarg_r; }
    ((opt_u)) && { CI_IMG_URL="$optarg_u"; CI_IMG_FNAME=$(basename $CI_IMG_URL); }
    [[ -z $CI_VM_HOSTNM || -z $CI_PUB_BR || -z $CI_VM_IP_LSB ]] && { echo "-b, -n, -i are mandatory"; exit -1; }
    [[ ! -e $CI_SSH_PUBKEY ]] && { echo "SSH public key not found at $CI_SSH_PUBKEY"; exit -1; }
    [[ ! -d $CI_IMG_LOC/ ]] && { mkdir -pv $CI_IMG_LOC/; }
    CI_IMG_FNAME=$(basename $CI_IMG_URL); CI_IMG_FPATH=$CI_IMG_LOC/$CI_IMG_FNAME; CI_IMG_EXT=${CI_IMG_FPATH##*.}
    ((opt_u)) && { [[ ! -e $CI_IMG_FPATH ]] && wget -O $CI_IMG_FPATH $CI_IMG_URL; }
    [[ ! -e $CI_IMG_FPATH ]] && { echo "Base image not found at $CI_IMG_FPATH"; }
    #((opt_w)) && { convert_img_to_raw; }
    ((opt_t)) && { teardown_vm; }
    ((opt_q)) && { clone_img && CI_IMG_CLONED=1; }
    ((opt_s)) && { [[ -z $CI_IMG_CLONED ]] && copy_img; setup_vm; }
    ((opt_a)) && { print_vm_ip; }
    ((opt_h)) && { usage; }

    exit 0;
}

if [ "qemu.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
