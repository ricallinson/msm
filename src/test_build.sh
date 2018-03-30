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
# shellcheck source=./src/msm.sh
source "$TESTMSMHOME/src/msm.sh"

WD=$(pwd)

rm -rf "$WD/tmp"
mkdir "$WD/tmp"
cd "$WD/tmp" || exit 1

msm here . > /dev/null 2>&1
msm build > /dev/null 2>&1

if [[ ! -f "./pkg/service.img" ]]; then
	echo "Service disk image was not created."
	exit 1
fi

cd "$WD" || exit 1
rm -rf "$WD/tmp"

exit 0
}
