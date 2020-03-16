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
#
sh setup-config.sh
#
# Basic test
expandfile test1d
# CSV loop test
expandfile testcsv.htmt
# CSV bind test
expandfile testbindcsv.htmt
# XML loop test
expandfile testxml.htmt
expandfile testxml2.htmt
# SSV loop test
expandfile testssv.htmt
# Test SQL loop
# .. load the database
mysql thvv_userlist < test.sql
ec=$?
if [ $ec != 0 ] ; then
    echo "*** cannot test sqlloop, mysql error"
    # .my.cnf might be wrong, or database may not be named thvv_userlist
else
    expandfile config.htmi testsql.htmt
fi
# dirloop test
expandfile testdirloop.htmt > dir.html
systype=`uname`
if [ "$systype" != "Darwin" ] ; then
    echo "*** open dir.html and check it"
else
    open -a /Applications/Safari.app dir.html
fi
