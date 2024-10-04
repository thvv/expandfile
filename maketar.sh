#!/bin/sh
### maketar.sh - generate htmxkit.tar.gz
#
# USAGE: cd htmxkit; sh maketar.sh
#
COPYFILE_DISABLE=1 tar cf htmxkit.tar README.txt
COPYFILE_DISABLE=1 tar rf htmxkit.tar checknonempty
COPYFILE_DISABLE=1 tar rf htmxkit.tar cr2nl
COPYFILE_DISABLE=1 tar rf htmxkit.tar csv2sql.htmt
COPYFILE_DISABLE=1 tar rf htmxkit.tar expandfile
COPYFILE_DISABLE=1 tar rf htmxkit.tar expandfile.man
COPYFILE_DISABLE=1 tar rf htmxkit.tar expandfile.pm
COPYFILE_DISABLE=1 tar rf htmxkit.tar readbindsql.pm
COPYFILE_DISABLE=1 tar rf htmxkit.tar readbindxml.pm
COPYFILE_DISABLE=1 tar rf htmxkit.tar expandfile_config
COPYFILE_DISABLE=1 tar rf htmxkit.tar filedaysold
COPYFILE_DISABLE=1 tar rf htmxkit.tar filemodiso
COPYFILE_DISABLE=1 tar rf htmxkit.tar filemodshort
COPYFILE_DISABLE=1 tar rf htmxkit.tar filemodyear
COPYFILE_DISABLE=1 tar rf htmxkit.tar filesizek
COPYFILE_DISABLE=1 tar rf htmxkit.tar firstletter
COPYFILE_DISABLE=1 tar rf htmxkit.tar firstofnextmonth
COPYFILE_DISABLE=1 tar rf htmxkit.tar fmtnum
COPYFILE_DISABLE=1 tar rf htmxkit.tar fmtsql
COPYFILE_DISABLE=1 tar rf htmxkit.tar gifsize
COPYFILE_DISABLE=1 tar rf htmxkit.tar gifsize2
COPYFILE_DISABLE=1 tar rf htmxkit.tar gth2x
COPYFILE_DISABLE=1 tar rf htmxkit.tar gthumb
COPYFILE_DISABLE=1 tar rf htmxkit.tar htmxlib.htmi
COPYFILE_DISABLE=1 tar rf htmxkit.tar lowercase
COPYFILE_DISABLE=1 tar rf htmxkit.tar nargs
COPYFILE_DISABLE=1 tar rf htmxkit.tar padstring
COPYFILE_DISABLE=1 tar rf htmxkit.tar gitpush.sh
COPYFILE_DISABLE=1 tar rf htmxkit.tar uppercase
COPYFILE_DISABLE=1 tar rf htmxkit.tar xml2sql
rm -f htmxkit.tar.gz
gzip htmxkit.tar
