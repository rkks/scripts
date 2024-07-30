#!/bin/bash
#  DETAILS: QEMU helper script to manage life-cycle of KVM VMs using cloud-init
# provisioner, cloud-images, and libvirt tools.
# Reference:
# https://earlruby.org/2023/02/quickly-create-guest-vms-using-virsh-cloud-image-files-and-cloud-init/
#  CREATED: 24/07/24 03:54:36 PM +0530
# MODIFIED: 30/07/24 10:05:29 AM +0530
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2024, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:.:/auto/opt/bin:/bin:/sbin"

CI_VM_NUM_CPU=2
CI_VM_RAM_SZ=4096
CI_DISK_SIZE=16
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

function bail() { local e=$?; [[ $e -ne 0 ]] && { echo "$! failed w/ err: $e." >&2; exit $e; } || return 0; }

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
    [[ ! -e $CI_SSH_PUBKEY ]] && { echo "SSH public key not found at $CI_SSH_PUBKEY"; exit -1; }

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
    # TODO: Check if disable_root should be true instead
    echo -e "disable_root: false" >> user-data
    echo -e "chpasswd:" >> user-data
    echo -e "  list: |" >> user-data
    echo -e "     ${USERNM}:${PASSWD}" >> user-data
    echo -e "  expire: false" >> user-data
    echo -e "package_update: true" >> user-data
    echo -e "packages:" >> user-data
    echo -e "  - qemu-guest-agent" >> user-data
    echo -e "" >> user-data
    # TODO: First default NAT for provision through internet does not work.
    #echo -e "        ens3:" >> user-data
    #echo -e "          dhcp4: true" >> user-data
    #echo -e "          dhcp6: false" >> user-data
    echo -e "# 1 NAT for provision, 1 mgmt, 1 WAN/pub, 1 LAN/pvt inf" >> user-data
    echo -e "write_files:" >> user-data
    echo -e "- path: /etc/cloud/cloud.cfg.d/99-custom-networking.cfg" >> user-data
    echo -e "  permissions: '0644'" >> user-data
    echo -e "  content: |" >> user-data
    echo -e "      network: {config: disabled}" >> user-data
    echo -e "- path: /etc/netplan/80-tgw-config.yaml" >> user-data
    echo -e "  permissions: '0600'" >> user-data
    echo -e "  content: |" >> user-data
    echo -e "    network:" >> user-data
    echo -e "      version: 2" >> user-data
    echo -e "      ethernets:" >> user-data
    echo -e "        enp3s0:" >> user-data
    echo -e "          addresses:" >> user-data
    echo -e "            - 192.168.1.${CI_VM_IP_LSB}/24" >> user-data
    echo -e "          nameservers:" >> user-data
    echo -e "            #search: [example.com]" >> user-data
    echo -e "            addresses: [1.1.1.1, 8.8.4.4]" >> user-data
    echo -e "          routes:" >> user-data
    echo -e "            - to: default" >> user-data
    echo -e "              via: 192.168.1.1" >> user-data
    echo -e "        enp4s0:" >> user-data
    echo -e "          dhcp4: true" >> user-data
    echo -e "          dhcp6: false" >> user-data
    echo -e "        enp5s0:" >> user-data
    echo -e "          addresses:" >> user-data
    echo -e "            - 192.168.122.${CI_VM_IP_LSB}/24" >> user-data
    # CAUTION: No default routes through private LAN interface, only via WAN
    #echo -e "          routes:" >> user-data
    #echo -e "            - to: default" >> user-data
    #echo -e "              via: 192.168.122.1" >> user-data
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
    echo -e "  - rm -f /etc/netplan/50-cloud-init.yaml" >> user-data
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

print_vm_ip_addr()
{
    [[ -z $CI_VM_HOSTNM ]] && { echo "Pass -n option with -t argument"; exit -1; }

    local macaddr=$(virsh -q domiflist ${CI_VM_HOSTNM} | awk '{ print $5 }')
    arp -e | grep -i $macaddr | awk '{ print $1 }'
}

teardown_vm()
{
    [[ -z $CI_VM_HOSTNM || -z $CI_IMG_EXT ]] && { echo "-u, -n mandatory for -t arg"; exit -1; }
    [[ ! -e $CI_VM_HOSTNM.$CI_IMG_EXT || ! -e ${CI_VM_HOSTNM}.xml ]] && { echo "run this cmd from init directory"; exit -1; }
    [[ ! -e ${CI_VM_HOSTNM}-cidata.iso || ! -e meta-data || ! -e user-data ]] && { echo "run this cmd from init directory"; exit -1; }

    virsh destroy "${CI_VM_HOSTNM}"
    virsh undefine "${CI_VM_HOSTNM}"
    rm -vf $CI_VM_HOSTNM.$CI_IMG_EXT meta-data user-data ${CI_VM_HOSTNM}-cidata.iso ${CI_VM_HOSTNM}.xml;
    local vol;
    for vol in $(virsh vol-list --pool $(basename $PWD) | grep $(basename $PWD) | awk '{print $1}'); do
        virsh vol-delete --pool $(basename $PWD) $vol;
    done
}

setup_vm()
{
    [[ -z $CI_VM_HOSTNM || -z $CI_PUB_BR || -z $CI_VM_IP_LSB ]] && { echo "-b, -n, -i are mandatory for -s"; exit -1; }

    [[ ! -z $CI_VM_MACADDR ]] && { local virtopts="--mac $CI_VM_MACADDR"; }
    bld_cidata_iso || exit -1;

    # DPDK recommends e1000 VM NICs: https://doc.dpdk.org/guides-16.07/nics/e1000em.html
    # --network "bridge=br0,model=virtio": But virtio are more performant

    # --force: TODO: What is this for?
    # --network default: # 1st NAT IP for cloud-init over internet does not work
    # --hvm/-v: full virtualization, default for QEMU
    # --connect=qemu:///system: if it is not finding right domain to connect to
    # --osinfo detect=on,require=off: Using --osinfo generic, VM performance may suffer
    #   - use cmd 'virt-install --osinfo list' to see list of all supported OS
    # --console pty,target_type=serial: to automatically jump user to console
    # --graphics vnc,listen=0.0.0.0: useful for ubuntu-desktop
    # --location 'http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/' --extra-args 'console=ttyS0,115200n8 serial': for auto-install
    virt-install --name="${CI_VM_HOSTNM}" \
        --network "bridge=${CI_PUB_BR},model=virtio" \
        --network "bridge=${CI_PUB_BR},model=virtio" \
        --network "bridge=${CI_PVT_BR},model=virtio" \
        $virtopts --import \
        --disk "path=$PWD/${CI_VM_HOSTNM}.${CI_IMG_EXT},format=qcow2,size=$CI_DISK_SIZE" \
        --disk "path=$PWD/${CI_VM_HOSTNM}-cidata.iso,device=cdrom" \
        --ram="${CI_VM_RAM_SZ}" --vcpus="${CI_VM_NUM_CPU}" --check-cpu \
        --autostart --arch x86_64 --accelerate --osinfo ubuntu22.04 --debug \
        --watchdog=default --graphics none --noautoconsole
    # https://game.ci/docs/self-hosting/host-creation/QEMU/linux-cloudimage/
    # SMP=$(( $PHYSICAL_CORES * $HYPR_THRDS ))
    #sudo qemu-system-x86_64 \
    #    -machine accel=kvm,type=q35 \
    #    -cpu host \
    #    -smp $SMP,sockets=1,cores="$PHYSICAL_CORES",threads="$HYPR_THRDS",maxcpus=$SMP \
    #    -m "$MEMORY" \
    #    -serial stdio -vga virtio -parallel none \
    #    -device virtio-net-pci,netdev=network \
    #    -netdev user,id=network,hostfwd=tcp::"${VM_SSH_PORT}"-:"${HOST_SSH_PORT}" \
    #    -object iothread,id=io \
    #    -device virtio-blk-pci,drive=disk,iothread=io \
    #    -drive if=none,id=disk,cache=none,format=qcow2,aio=threads,file=disk.qcow2 \
    #    -drive if=virtio,format=raw,file=seed.img,index=0,media=disk \
    #    -bios /usr/share/ovmf/OVMF.fd \
    #    -usbdevice tablet \
    #    -vnc "$HOST_ADDRESS":"$VNC_PORT"
    #qemu-system-x86_64 -machine accel=kvm,type=q35 -cpu host -m 2G \
    #    -nographic -device virtio-net-pci,netdev=net0 \
    #    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    #    -drive if=virtio,format=qcow2,file=${CI_VM_HOSTNM}.${CI_IMG_EXT} \
    #    -drive if=virtio,format=raw,file=${CI_VM_HOSTNM}-cidata.raw
    virsh dumpxml "${CI_VM_HOSTNM}" > "${CI_VM_HOSTNM}.xml"
    virsh list --all;
}

function clone_img()
{
    local isqcow=$(file -b $CI_IMG_FPATH | grep -i qcow | wc -l)
    [[ $isqcow -eq 0 ]] && { echo "Only qcow2 supported for cloning"; exit -1; }
    [[ -e $CI_VM_HOSTNM.$CI_IMG_EXT ]] && { echo "$CI_VM_HOSTNM.$CI_IMG_EXT already exists"; return 0; }
    qemu-img create -b $CI_IMG_FPATH -f qcow2 -F qcow2 $CI_VM_HOSTNM.$CI_IMG_EXT ${CI_DISK_SIZE}G;
    return $?;
}

function copy_img()
{
    [[ -e $CI_VM_HOSTNM.$CI_IMG_EXT ]] && { echo "$CI_VM_HOSTNM.$CI_IMG_EXT already exists"; return 0; }
    cp -v $CI_IMG_FPATH $CI_VM_HOSTNM.$CI_IMG_EXT && qemu-img resize $CI_VM_HOSTNM.$CI_IMG_EXT ${CI_DISK_SIZE}G;
    return $?;
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
    ((opt_u)) && { CI_IMG_URL="$optarg_u"; }
    CI_IMG_FNAME=$(basename $CI_IMG_URL); CI_IMG_FPATH=$CI_IMG_LOC/$CI_IMG_FNAME; CI_IMG_EXT=${CI_IMG_FPATH##*.}
    ((opt_t)) && { teardown_vm; }
    ((opt_q || opt_s || opt_u || opt_w)) && { [[ ! -e $CI_IMG_FPATH ]] && { mkdir -pv $CI_IMG_LOC/ && wget -O $CI_IMG_FPATH $CI_IMG_URL; bail; }; }
    ((opt_w)) && { convert_img_to_raw; }
    ((opt_q)) && { clone_img && CI_IMG_CLONED=1; }
    ((opt_s)) && { [[ -z $CI_IMG_CLONED ]] && copy_img; setup_vm; }
    ((opt_a)) && { print_vm_ip_addr; }
    ((opt_h)) && { usage; }

    exit 0;
}

if [ "qemu.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
