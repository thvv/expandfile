#!/bin/sh
# make sure we can access ENV values
# thvv 2020-08-31
#
echo test expandfile3 access to ENV values
export magic_var=
echo expanding vartest.htmt when ENV.magic_var=$magic_var
$EXPAND vartest.htmt
export magic_var=3
echo expanding vartest.htmt when ENV.magic_var=$magic_var
$EXPAND vartest.htmt
echo expanding vartest.htmt with cmd line argument magic_var=7 and ENV.magic_var=$magic_var
$EXPAND magic_var=7 vartest.htmt
