#!/bin/sh
# Test harness for expandfile and thvve.pm
# THVV 02/22/05 1.0
# THVV 09/18/05 1.1 ssv
# THVV 02/21/06 1.2 new config
# THVV 03/03/15 1.3 do not fail on distant systems
# THVV 03/30/15 1.4 add xmlloop
# THVV 09/17/18 1.5 remove -config
# THVV 10/15/18 1.6 add testxml2.htmt
# THVV 01/06/18 1.7 add testbindcsv.htmt
# THVV 02/24/20 1.8 set up config with setup-config.sh
# THVV 08/27/20 2.0 test expandfile3, add tests for ENV and old syntax
# THVV 04/16/21 2.1 better tests for variables, rename things back to expandfile
#
export EXPAND=expandfile
export CONFIG=config2.htmi
#
sh setup-config.sh
#
echo --- test if $EXPAND can reference ENV vars
echo .. expect 6 warnings: 4 Undefined, 2 invalid chars
echo sh testvar.sh
sh testvar.sh
#
echo "================================================================"
echo --- test for old syntax, also firstnonemtpy and wrap from htmxlib.htmi
echo ".. expect 3 warnings" >&2
echo $EXPAND $CONFIG varwarp.htmt
$EXPAND $CONFIG varwrap.htmt
#
echo "================================================================"
echo --- Basic test: test1d
echo $EXPAND $CONFIG test1d
$EXPAND $CONFIG test1d
echo "================================================================"
echo --- CSV loop test: testcsv.htmt
echo $EXPAND $CONFIG testcsv.htmt
$EXPAND $CONFIG testcsv.htmt
echo "================================================================"
echo --- CSV bind test: testbindcsv.htmt
echo $EXPAND $CONFIG testbindcsv.htmt
$EXPAND $CONFIG testbindcsv.htmt
echo "================================================================"
echo --- XML loop test: testxml.htmt
echo $EXPAND $CONFIG testxml.htmt, testxml2.htmt
$EXPAND $CONFIG testxml.htmt
echo $EXPAND $CONFIG testxml2.htmt
$EXPAND $CONFIG testxml2.htmt
echo "================================================================"
echo --- SSV loop test: testssv.htmt
echo $EXPAND $CONFIG testssv.htmt
$EXPAND $CONFIG testssv.htmt
echo "================================================================"
echo --- Test SQL loop: testsql.htmt
# .. load the database
echo mysql thvv_userlist < test.sql
mysql thvv_userlist < test.sql
ec=$?
if [ $ec != 0 ] ; then
    echo "*** cannot test sqlloop, mysql error"
    # .my.cnf might be wrong, or database may not be named thvv_userlist
else
    $EXPAND $CONFIG testsql.htmt
fi
echo "================================================================"
echo "--- dirloop test: testdirloop.htmt"
echo $EXPAND $CONFIG testdirloop.htmt > dir.html
$EXPAND $CONFIG testdirloop.htmt > dir.html
systype=`uname`
if [ "$systype" != "Darwin" ] ; then
    echo "*** (non Mac) open dir.html in local browser and check it"
else
    echo open -a /Applications/Safari.app dir.html
    open -a /Applications/Safari.app dir.html
fi
echo "================================================================"
echo "--- macro library test: macrotest.tpt"
echo "----- exercises *set, *concat, *format, *shell"
echo ".. expect 11 warnings that nonexist.jpg is missing" >&2
echo $EXPAND $CONFIG macrotest.tpt
$EXPAND $CONFIG macrotest.tpt
