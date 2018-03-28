#!/bin/bash

# 
# Copyright 2018, Richard S Allinson.
# Copyrights licensed under the New BSD License.
# See the accompanying LICENSE file for terms.
#

#
# Lint check by http://www.shellcheck.net/
#

{
export MSMVERSION
MSMVERSION="0.0.1"
export MSMHOME
MSMHOME=$(msm_helper_resolve "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/..")

msm_version() {
    echo "$MSMVERSION"
}

msm_env () {
    echo "MSMPATH=\"$MSMPATH\""
    echo "MSMHOME=\"$MSMHOME\""
    return 0
}

# @String $1 - Directory path
# @String $2 - Directory name
# @return "dir/path"
# Searches up through the directories until it finds directory name a match for the given input string.
msm_helper_find_up() {
    local path
    path=$1
    while [ "$path" != "" ] && [ ! -d "$path/$2" ]; do
        path=${path%/*}
    done
    echo "$path"
    return 0
}

# @String $1 - Directory path
# @return "dir/path" || ""
# Searches up through the directories until it finds a directory named 'src'.
msm_helper_find_srv() {
    local dir
    dir="$(msm_helper_find_up "$1" 'srv')"
    if [ -e "$dir/srv" ]; then
        echo "$dir/srv"
    fi
    return 0
}

# @String $1 - Directory path
# @return "/abs/dir/path" || ""
# Resolves the given directory if it exists.
msm_helper_resolve() {
    cd "$1" 2>/dev/null || return $?  # cd to desired directory; if fail, quell any error messages but return exit status
    pwd -P # output full, link-resolved path
    return 0
}

# @String $1 - Directory path
# Sets the workspace either by walking up from the given directory
# to find one or creating one in the given directory.
msm_here() {
    local wPath
    if [ -z "$1" ]; then
        wPath=$(msm_helper_find_srv "$(pwd)")
        wPath=${wPath%/*}
    else
        wPath=$(msm_helper_resolve "$1")
    fi
    if [ -z "$wPath" ]; then
        echo
        echo "This command must be run in a Msm workspace"
        echo
        return 0
    fi
    mkdir -p "$wPath/pkg"
    mkdir -p "$wPath/srv"
    echo "#!/bin/bash" > "$wPath/srv/init.sh"
    chmod +x "$wPath/srv/init.sh"
    export MSMPATH=$wPath

    echo
    echo "Msm workspace set to: $MSMPATH"
    echo

    return 0
}

# path/to/core/dir
msm_unpack_core() {
    currentDir=$(pwd)
    coreDir="$1"
    mkdir $coreDir/rootfs
    cd $coreDir/rootfs
    gunzip -c $coreDir/core.gz | sudo cpio -i -d
    cd $currentDir
    return 0
}

# path/to/core/dir
msm_pack_core() {
    currentDir=$(pwd)
    coreDir="$1"
    cd $coreDir/rootfs
    sudo find . | sudo cpio -o -H newc | sudo gzip -2 > $coreDir/core.gz
    # sudo advdef -z4 core
    sudo chmod 755 $coreDir/core.gz
    cd $currentDir
    rm -rf $coreDir/rootfs
    return 0
}

# Create a base disk image.
msm_create_disk_image() {
    # Cleanup img directory
    rm $MSMPATH/pkg/*
    # Create a raw disk image
    qemu-img create -f raw $MSMPATH/pkg/service.img 50M
    # Mount the image.
    disk=$(hdiutil attach -imagekey diskimage-class=CRawDiskImage -nomount $MSMPATH/pkg/service.img)
    # Write boot sector
    dd if=$MSMHOME/images/core-9.0.img of=$disk
    # Unmount the disk
    diskutil unmountDisk $disk
    # Eject the disk
    diskutil eject $disk
    return 0
}

msm_mount_disk_image() {
    path=$(hdiutil attach $MSMPATH/pkg/service.img -mountpoint $MSMPATH/mnt )
    echo $path
    return 0
}

msm_unmount_disk_image() {
    hdiutil unmount $MSMPATH/mnt
    return 0
}

msm_insert_service() {
    sudo rsync -xa --progress $MSMPATH/srv/ $MSMPATH/mnt/tce/boot/rootfs/opt/srv
    return 0
}

msm_build_disk_image() {
    msm_create_disk_image
    msm_mount_disk_image
    msm_open_core_gz "$MSMPATH/mnt/tce/boot"
    msm_insert_service
    msm_close_core_gz "$MSMPATH/mnt/tce/boot"
    msm_unmount_disk_image
    return 0
}

msm_open_core_gz() {
    msm_unpack_core "$1"
    return 0
}

msm_close_core_gz() {
    msm_pack_core "$1"
    return 0
}

# Prints the available commands.
msm_help() {
    echo "Msm is a tool for creating disk images from an executable."
    echo
    echo "Msm"
    echo
    echo "Usage:"
    echo
    echo "    msm command [arguments]"
    echo
    echo "The commands are:"
    echo
    echo "    install     compile packages and dependencies"
    echo "    version     print Msm version"
    echo "    here        sets $MSMPATH to the given directory creating a workspace is one is not found."
    echo
    return 0
}

#
# Interface
#

# The main entry point.
msm() {
    case $1 in
    "help" )
        msm_help
        return 0
    ;;
    "version" )
        msm_version
        return 0
    ;;
    "env" )
        msm_env
        return 0
    ;;
    "here" )
        msm_here "$2"
        return 0
    ;;
    "" )
        msm_help
        return 0
    ;;
    esac

    if [[ -z "$MSMPATH" ]]; then
        echo
        echo "You must be in a Msm workspace to use '$1'."
        echo
        return
    fi

    case $1 in
    "build" )
        msm_build_disk_image
    ;;
    "run" )
        # Build service image
        msm_build_disk_image
        # Start a VM running the service
        qemu-system-x86_64 -m 512 -drive file=$MSMPATH/pkg/service.img,index=0,media=disk,format=raw
    ;;
    "open" )
        msm_open_core_gz "$2"
    ;;
    "close" )
        msm_close_core_gz "$2"
    ;;
    *)
        echo "msm: unknown command \"$1\""
        echo "Run 'msm help' for usage."
        return 1
    esac
    return $?
}

}
