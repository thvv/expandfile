#!/bin/sh
#
# test diagnosis of errors in expandfile
# thvv 02/12/15
# updated 08/27/20
#
# errors are written to STDERR but have color shifts in them. esc 033m .... esc 0m
#
### error messages should indicate what file is being expanded and what line .. blocks screw that up though ..
#
export EXPAND=expandfile
#
# missing close quote
# err msg shows context for the open quote
echo "Test e1, missing close quote"
$EXPAND teste1.htmt 2> errout.txt
diff expected.errout1.txt errout.txt
echo "----------------------------------------------------------------"
#
# *block with missing end pattern
echo "Test e2, missing end pattern for BLOCK"
$EXPAND teste2.htmt 2> errout.txt
diff expected.errout2.txt errout.txt
echo "----------------------------------------------------------------"
#
# missing close bracket-pct
### err msg should show context for the open bracket .. tricky because close bracket could be quoted
echo "Test e3, missing close bracket-pct"
$EXPAND teste3.htmt 2> errout.txt
diff expected.errout3.txt errout.txt
echo "----------------------------------------------------------------"
#
# attempt to set variable with illegal name: should not allow comma, vbar, star, empty, all numeric
echo "Test e4, attempt to set variable with illegal name"
$EXPAND teste4.htmt 2> errout.txt
diff expected.errout4.txt errout.txt
echo "----------------------------------------------------------------"
#
# access to nonexistent variable (missing =)
# this is only printed if _debug = yes
echo "Test e5, complain if getting a varname that does not exist and _xf_debug is set"
export _xf_debug=yes
$EXPAND teste5.htmt 2> errout.txt
export _xf_debug=
diff expected.errout5.txt errout.txt
echo "----------------------------------------------------------------"
#
# unknown builtin *gork
echo "Test e6, unknown builtin *gork"
$EXPAND teste6.htmt 2> errout.txt
diff expected.errout6.txt errout.txt
echo "----------------------------------------------------------------"
#
# extra args to builtin
### dies after first error, figure out how to test them all..
echo "Test e7, extra args to builtin"
$EXPAND teste7.htmt 2> errout.txt
diff expected.errout7.txt errout.txt
echo "----------------------------------------------------------------"
#
# dirloop on nonexistent dir -- no error returned
echo "Test e8, dirloop on nonexistent dir"
$EXPAND teste8.htmt 2> errout.txt
diff expected.errout8.txt errout.txt
echo "----------------------------------------------------------------"
#
# cannot execute command with *shell
echo "Test e9, cannot execute command with *shell"
$EXPAND teste9.htmt 2> errout.txt
# tries a *shell command, gets error from OPEN on stdout, result is empty
diff expected.errout9.txt errout.txt
echo "----------------------------------------------------------------"
#
# use of garbage chars in variable names
echo "Test e10, use of garbage chars in variable names"
$EXPAND teste10.htmt 2> errout.txt
# expand a variable with garbage name, ref a variable's value in a bif, try to set a garbage named var
diff expected.errout10.txt errout.txt
echo "----------------------------------------------------------------"
#
# cannot fappend or fwrite file
#
# missing CSV file
#
# database params not set   -- execute with no config
# cannot open DBI:mysql.... -- execute with faked config that sets db params to junk
# cannot prepare query      --
# cannot execute query      --
#
# no input args to $EXPAND
### gives usage message via die().. if no args, should $EXPAND read stdin?
#
### recursive include loop, should have a counter
#
# missing arg to getv -- internal error, not tested
#
