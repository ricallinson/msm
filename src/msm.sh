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
# Searches up through the directories until it finds a directory named 'srv'.
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
# Resolves the given directory to an absolute path if it exists.
msm_helper_resolve() {
    cd "$1" 2>/dev/null || return $?  # cd to desired directory; if fail, quell any error messages but return exit status
    pwd -P # output full, link-resolved path
    return 0
}

MSMHOME=$(msm_helper_resolve "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/..")

# @String $1 - Directory path
# Creates directories and files for a new workspace.
msm_make_workspace() {
    dir=$(msm_helper_resolve "$wPath/srv")
    if [ -e "$dir" ]; then
        return 0
    fi
    mkdir -p "$wPath/pkg"
    mkdir -p "$wPath/srv"
    # echo '#!/bin/sh' > "$wPath/srv/init.sh"
    # echo 'echo "Hello World!"' >> "$wPath/srv/init.sh"
    # chmod u+x "$wPath/srv/init.sh"
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
        echo "This command must be run in a Msm workspace or on an existing directory."
        echo
        return 0
    fi
    export MSMPATH=$wPath
    msm_make_workspace "$wPath"

    echo
    echo "Msm workspace set to: $MSMPATH"
    echo

    return 0
}

# @String $1 - ["x86", "pi"]
# Creates a base TinyCore disk image in the workspaces 'pkg' directory.
msm_create_disk_image() {
    # Cleanup img directory
    rm "$MSMPATH/pkg/service.img"
    # Create a raw disk image
    qemu-img create -f raw "$MSMPATH/pkg/service.img" 50M
    # Mount the image.
    disk=$(hdiutil attach -imagekey diskimage-class=CRawDiskImage -nomount "$MSMPATH/pkg/service.img")
    # Write boot sector
    dd if="$MSMHOME/images/core-$1-9.0.img" of=$disk
    # Eject the disk
    hdiutil eject $disk
    return 0
}

# Mounts the disk image './pkg/service.img' to './mnt'.
msm_mount_disk_image() {
    path=$(hdiutil attach "$MSMPATH/pkg/service.img" -mountpoint "$MSMPATH/mnt")
    echo "$path"
    return 0
}

# Mounts the disk image at './mnt'.
msm_unmount_disk_image() {
    sleep 2 # Give it time...
    hdiutil eject "$MSMPATH/mnt"
    return 0
}

# Copies the content of './srv' to '/mnt/tce/srv'.
msm_insert_service() {
    cp -r "$MSMPATH/srv" "$MSMPATH/mnt/tce/srv"
    return 0
}

msm_insert_optional() {
    for file in $MSMPATH/opt/*
    do
        if [[ -f $file ]]; then
            cp -a $file $MSMPATH/mnt/tce/optional
            echo $(basename "$file") >> "$MSMPATH/mnt/tce/onboot.lst"
            echo "Added $(basename "$file") to onboot."
        fi
    done
    return 0
}

msm_insert_ssh() {
    echo "openssh.tcz" >> "$MSMPATH/mnt/tce/onboot.lst"
    return 0
}

# @String $1 - ["x86", "pi"]
# @String $2 - ["ssh", ""]
# Creates a new base TinyCore disk image in the workspace './pkg' directory.
# Copies to the disk image the './srv' directory and makes './srv/init.sh' execute on startup.
msm_build_disk_image() {
    msm_create_disk_image "$1"
    msm_mount_disk_image
    if [[ "$2" = "ssh" ]]; then
        msm_insert_ssh
    fi
    msm_insert_optional
    msm_insert_service
    msm_unmount_disk_image
    return 0
}

# Start the VM service.
msm_start_x86_image() {
    qemu-system-x86_64 -m 512 -drive file="$MSMPATH/pkg/service.img,index=0,media=disk,format=raw"
    return 0
}

# Start the VM service.
msm_start_pi_image() {
    qemu-system-arm -kernel "$MSMHOME/images/piCore-QEMU/piCore-140513-QEMU" \
    -initrd "$MSMHOME/images/piCore-QEMU/9.0.3v7.gz" \
    -cpu arm1176 -m 256 -M versatilepb \
    -append "root=/dev/ram0 elevator=deadline rootwait quiet nortc nozswap"
    return 0
}

# @String $1 - ["x86", "pi"]
# Start the VM service.
msm_start_disk_image() {
    if [[ "$1" = "x86" ]]; then
        msm_start_x86_image
    elif [[ "$1" = "pi" ]]; then 
        msm_start_pi_image
    fi
    return 0
}

# @String $1 - [pi", ""]
msm_arch() {
    if [[ "$1" = "pi" ]]; then
        echo "pi"
    else
        echo "x86"
    fi
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
    echo "    here        sets $MSMPATH to the given directory creating a workspace is one is not found."
    echo "    build       create a Linux disk image."
    echo "    run         create a Linux disk image and activate it with QEMU."
    echo "    env         print Msm environment variables."
    echo "    version     print Msm version."
    echo "    help        this text."
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
        msm_build_disk_image "$(msm_arch $2)"
    ;;
    "run" )
        msm_build_disk_image "$(msm_arch $2)" #"ssh"
        msm_start_disk_image "$(msm_arch $2)"
    ;;
    "use" )
        # Start the VM service and return to the current process.
        msm_start_disk_image "$(msm_arch $2)" &
    ;;
    *)
        echo "msm: unknown command '$1'"
        echo "Run 'msm help' for usage."
        return 1
    esac
    return $?
}

}
