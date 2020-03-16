#!/bin/sh
# make test configuration for testexpandfile
#
# if config.htmi exists, just list its date
# else if $HOME/.my.cnf exists, adopt values from it
# if variables username, password, hostname, database do not exist, ask for them
# expand config.tpt info config.htmi
#
# THVV 2020-02024

checkvar()
{
    local thing
    thing="$1"
    local default=""
    default="$2"
    local temp
    z1='temp=${'
    z2=$thing
    z3='}'
    z="$z1$z2$z3"
    eval $z
    #echo "!! $thing is $temp"
    local readval
    if [ "$temp" = "" ] ; then
	read -p "$thing ($prompt) [$default] >>" readval
	test -z "$readval" && readval=$default
	if test -z "$readval"
	then
	    { echo "configure: error: must specify a value for $thing" >&2
	    { (exit 1); exit 1; }; }
	fi
	export ${thing}="$readval"
    else
	readval=$temp
    fi
    #echo "!! checkvar sets $thing to $readval"
}
readmycnf()
{
    local thing
    thing="$1"
    #echo "!!checking $HOME/.my.cnf for $thing"
    unset temp
    temp=`grep $thing= $HOME/.my.cnf`
    #echo "!!readmycnf found $temp"
    if [ "$temp" = "" ] ; then
	export junk=""
    else
	#echo "!!$HOME/.my.cnf contains $temp"
	eval export $temp
    fi
}
# ================================================================

if [ -f config.htmi ] ; then
    ls -l config.htmi
else
    echo "==== setting up config.htmi"
    # check .my.cnf
    if [ -f $HOME/.my.cnf ] ; then
	# some vars are renamed between .my.cnf and expandfile
	readmycnf password
	readmycnf user
	export username=$user
	readmycnf host
	export hostname=$host
	readmycnf database
    fi
    # ask for missing values
    export prompt="MySQL user"
    checkvar user root
    export prompt="MySQL user password"
    checkvar password 99
    export prompt="MySQL host"
    checkvar host localhost
    export prompt="MySQL database"
    checkvar database stats
    expandfile config.tpt > config.htmi
    ls -l config.htmi
fi
