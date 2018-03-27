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
MSMHOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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
msm_helper_find_src() {
    local dir
    dir="$(jmm_helper_find_up "$1" 'src')"
    if [ -e "$dir/src" ]; then
        echo "$dir/src"
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
        wPath=$(msm_helper_find_src "$(pwd)")
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
    mkdir -p "$wPath/bin"
    mkdir -p "$wPath/pkg"
    mkdir -p "$wPath/src"
    export MSMPATH=$wPath

    echo
    echo "Msm workspace set to: $MSMPATH"
    echo

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
    "" )
        msm_help
        return 0
    ;;
    "version" )
        msm_version
        return 0
    ;;
    "here" )
        msm_here "$2"
        return 0
    ;;
    "env" )
        msm_env
        return 0
    ;;
    "run" )
        # Cleanup pkg
        rm ./pkg/*
        # Create a raw disk image
        qemu-img create -f raw ./pkg/msm.img 50M
        # Mount the image.
        disk=$(hdiutil attach -imagekey diskimage-class=CRawDiskImage -nomount ./pkg/msm.img)
        # Write boot sector
        dd if=./kernel/Core-9.0.iso of=$disk 
        # Unmount the disk
        diskutil unmountDisk $disk
        # Eject the disk
        diskutil eject $disk
        # Start the VM
        qemu-system-x86_64 -m 512 -cdrom ./pkg/msm.img -boot d
    ;;
    *)
        echo "msm: unknown command \"$1\""
        echo "Run 'msm help' for usage."
        return 1
    esac
    return $?
}

}
