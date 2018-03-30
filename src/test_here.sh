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

data="$(msm here)"
if [[ "$data" != *"This command must be run in a Msm workspace"* ]]; then
	echo "Using a workspace failed."
	exit 1
fi

data="$(msm here .)"
if [[ "$data" != *"Msm workspace set to: /"* ]]; then
	echo "Creating a workspace failed."
	exit 1
fi

mkdir "$WD/tmp/dir"
cd "$WD/tmp/dir" || exit 1

data="$(msm here .)"
if [[ "$data" != *"Msm workspace set to: /"* ]]; then
	echo "Using a nested workspace failed."
	exit 1
fi

cd "$WD" || exit 1
rm -rf "$WD/tmp"

exit 0
}
