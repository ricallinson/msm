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

data="$(msm env)"
if [[ "$data" != *"MSMPATH"* && "$data" != *"MSMHOME"* ]]; then
	echo "Environment not returned"
	exit 1
fi

exit 0
}
