#!/bin/sh

# 
# Copyright 2018, Richard S Allinson.
# Copyrights licensed under the New BSD License.
# See the accompanying LICENSE file for terms.
#

#
# Lint check by http://www.shellcheck.net/
#

{
export TESTMSMHOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo
echo "Running Lint in $TESTMSMHOME/src"
echo

shellcheck $TESTMSMHOME/src/*.sh

echo
echo "Running Tests in $TESTMSMHOME/src"
echo

failures=0
passes=0

for test in $TESTMSMHOME/src/test_*.sh; do
	# Run the test.
	$test
	if [ $? -eq 0 ]; then
		passes=$(($passes+1))
	    echo "    Pass $test"
	else
		failures=$(($failures+1))
	    echo "    Fail $test"
	fi
done

echo
echo "There were $passes passes and $failures failures."
echo

if [[ $failures != 0 ]]; then
	exit 1
fi
exit 0
}
