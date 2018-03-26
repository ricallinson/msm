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

data="$(msm version)"
if [[ "$data" != "$MSMVERSION" ]]; then
	echo "Failed version match: $data != $MSMVERSION"
	exit 1
fi

data="$(msm help)"
if [[ "$data" != *"Usage:"* ]]; then
	echo "Failed to show help from help command"
	exit 1
fi

data="$(msm)"
if [[ "$data" != *"Usage:"* ]]; then
	echo "Failed to show help from no command"
	exit 1
fi

exit 0
}
