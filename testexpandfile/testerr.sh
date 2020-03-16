#!/bin/sh
#
# test diagnosis of errors in expandfile
# thvv 02/12/15
#
# errors are written to STDERR but have color shifts in them. esc 033m .... esc 0m
#
### error messages should indicate what file is being expanded and what line .. blocks screw that up though ..
#
# missing close quote
# err msg shows context for the open quote
echo "Test e1, missing close quote"
expandfile teste1.htmt 2> errout.txt
diff expected.errout1.txt errout.txt
echo "----------------------------------------------------------------"
#
# *block with missing end pattern
echo "Test e2, missing end pattern for BLOCK"
expandfile teste2.htmt 2> errout.txt
diff expected.errout2.txt errout.txt
echo "----------------------------------------------------------------"
#
# missing close bracket-pct
### err msg should show context for the open bracket .. tricky because close bracket could be quoted
echo "Test e3, missing close bracket-pct"
expandfile teste3.htmt 2> errout.txt
diff expected.errout3.txt errout.txt
echo "----------------------------------------------------------------"
#
# attempt to set variable with illegal name: should not allow comma, vbar, star, empty, all numeric
echo "Test e4, attempt to set variable with illegal name"
expandfile teste4.htmt 2> errout.txt
diff expected.errout4.txt errout.txt
echo "----------------------------------------------------------------"
#
# access to nonexistent variable (missing =)
# this is only printed if _debug = yes
echo "Test e5, complain if getting a varname that does not exist and _HTMXDEBUG2 is set"
export _HTMXDEBUG2=yes
expandfile teste5.htmt 2> errout.txt
export _HTMXDEBUG2=
diff expected.errout5.txt errout.txt
echo "----------------------------------------------------------------"
#
# unknown builtin *gork
echo "Test e6, unknown builtin *gork"
expandfile teste6.htmt 2> errout.txt
diff expected.errout6.txt errout.txt
echo "----------------------------------------------------------------"
#
# extra args to builtin
### dies after first error, figure out how to test them all..
echo "Test e7, extra args to builtin"
expandfile teste7.htmt 2> errout.txt
diff expected.errout7.txt errout.txt
echo "----------------------------------------------------------------"
#
# dirloop on nonexistent dir -- no error returned
echo "Test e8, dirloop on nonexistent dir"
expandfile teste8.htmt 2> errout.txt
diff expected.errout8.txt errout.txt
echo "----------------------------------------------------------------"
#
# cannot execute command
echo "Test e9, cannot execute command"
expandfile teste9.htmt 2> errout.txt
# tries a *shell command, gets error from OPEN on stdout, result is empty
diff expected.errout9.txt errout.txt
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
# no input args to expandfile
### gives usage message via die().. if no args, should expandfile read stdin?
#
### recursive include loop, should have a counter
#
# missing arg to getv -- internal error, not tested
#
