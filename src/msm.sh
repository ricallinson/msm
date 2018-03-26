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
    *)
        echo "msm: unknown command \"$1\""
        echo "Run 'msm help' for usage."
        return 1
    esac
    return $?
}

}
