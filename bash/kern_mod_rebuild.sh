#!/usr/bin/env bash
#  DETAILS: Builds linux kernel module for specific distro. Built from
# http://www.pixelbeat.org/docs/rebuild_kernel_module.html
#  CREATED: 03/03/13 19:53:21 IST
# MODIFIED: 03/28/16 17:48:21 IST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

#set -uvx               # Treat unset variables as an error, verbose, debug mode

# Source .bashrc.dev only if invoked as a sub-shell.
[[ "$(basename kern_mod_rebuild.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }
# Global defines. (Re)define ENV only if necessary.

kernver=$(uname -r)
kernbase=$(echo $kernver | sed 's/\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/')
rpmarch=$(rpm -q --qf="%{ARCH}\n" kernel | head -n1)
rpmbase=$(rpm -q kernel | sed -n "\$s/\.$rpmarch$//p")
kernextraver=$(echo $kernver | sed "s/$kernbase\(.*\)/\1/")
arch=$(uname -m)

prep_src()
{
    cd /usr/src/kernels #optional
    yum install yum-utils
    sudo yum-builddep kernel
    yumdownloader --source kernel-$kernver

    rpm -ivh $rpmbase.src.rpm
    rm $rpmbase.src.rpm #optional

    rpmbuild_base=~/rpmbuild #use /usr/src/redhat for older systems

    rpmbuild -bp $rpmbuild_base/SPECS/kernel.spec --target=$rpmarch
    kernsrc=$rpmbuild_base/BUILD/kernel-$kernbase/linux-$kernbase.$rpmarch
}

kern_rebuild()
{
    cd $kernsrc
    #copy existing distro config
    cp /boot/config-$kernver .config
    #make config changes
    sed -i 's/# CONFIG_UFS_FS_WRITE is not set/CONFIG_UFS_FS_WRITE=y/' .config
    #or make code changes '$ patch -p1 < ~/alsa-fix.diff'
    sed -i "s/EXTRAVERSION = .*/EXTRAVERSION = $kernextraver/" Makefile
    make oldconfig
    make prepare
    make modules_prepare
    make SUBDIRS=scripts/mod
    make SUBDIRS=fs/ufs/ modules
    make SUBDIRS=sound/pci modules
}

mod_install()
{
    #don't install, just use once
    rmmod ufs
    insmod fs/ufs/ufs.ko
    mount -t ufs -o ufstype=44bsd /dev/sdb4 mnt_monowall
    sudo install -m 744 snd-intel8x0.ko /lib/modules/$(uname -r)/kernel/sound/pci
    killall pulseaudio
    rmmod snd_intel8x0; modprobe snd_intel8x0
    #relogin to start pulseaudio. Don't know how to otherwise?
    mkdir tmp
    cd tmp
    gzip -dc /boot/initramfs-$kernver.img | cpio -i --make-directories
    # copy in the new module
    rm -f lib/modules/$kernver/*.bin # in case not updated by current depmod
    depmod -b $PWD $(basename lib/modules/[23]*)
    find . | cpio -H newc -o | gzip > /boot/initramfs-$kernver.img
    # OR mkinitrd --force /boot/initramfs-$kernver.img $kernver
    make bzImage
    rm -Rf $rpmbuild_base/BUILD/kernel-$kernbase/
}

usage()
{
    echo "usage: kern_mod_rebuild.sh []"
}

# steps for rebuilding a single distro kernel module are coded here. These info
# are distribution and kernel specific. Since rebuilding the whole distro
# kernel takes ages due to the number of modules enabled, so the instructions
# below show how to quickly rebuild and install the minimum required.
# Note: these instructions are based on rpm using distros but should be easily
# translatable to ones using dpkg.

# patch the snd_intel8x0 driver to get sound working on Fedora 11
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

if [ "$(basename -- $0)" == "$(basename kern_mod_rebuild.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4

