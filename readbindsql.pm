#!/usr/local/bin/perl

# module to execute a MySQL query and bind its results, to support %[*sqlloop,&outvar,iterator,query]
#
# $$symtbptr{$varname} = &iterateSQL(&gvalue($v1, $symtbptr), &gvalue($v2, $symtbptr), $symtbptr);
#
# USAGE:
#   &iterateSQL();
##
# 2018-09-07 THVV split out from thvve.pm
# 2020-08-31 THVV minor changes for expandfile3
# 2020-09-15 THVV write out error and trace messages using expandfile::errmsg()
# 2021-04-15 THVV using expandfile.pm
#
# Copyright (c) 2018 Tom Van Vleck
 
#  Permission is hereby granted, free of charge, to any person obtaining
#  a copy of this software and associated documentation files (the
#  "Software"), to deal in the Software without restriction, including
#  without limitation the rights to use, copy, modify, merge, publish,
#  distribute, sublicense, and/or sell copies of the Software, and to
#  permit persons to whom the Software is furnished to do so, subject to
#  the following conditions:
 
#  The above copyright notice and this permission notice shall be included
#  in all copies or substantial portions of the Software.
 
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 

package readbindsql3;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(iterateSQL);

use DBI;

# SQL iteration function used by *sqlloop
#   $val = &iterateSQL($iterator, $query, \%values)
#
# Runs query, binds %[_xf_nrows']%
# then expands iterator once per row if it is nonblank
# binds %[_xf_colnames]% to the column names
# it is not an error to have 0 rows but a warning will be printed.
#
# The database can go down and come back up, try waiting for it before giving up.
# If "out of memory" occurs, it is worth retrying for that too.
# If there are database errors, prints a warning and aborts.

sub iterateSQL {
    my $iterator = shift;
    my $query = shift;
    my $symtbptr = shift;
    my @array;
    my $result = '';
    my $hostname = &expandfile::getter($symtbptr, '_xf_hostname');
    my $database = &expandfile::getter($symtbptr, '_xf_database');
    my $username = &expandfile::getter($symtbptr, '_xf_username');
    my $password = &expandfile::getter($symtbptr, '_xf_password');
    if (($hostname eq '') || ($database eq '') || ($username eq '') || ($password eq '')) {
	&expandfile::errmsg($symtbptr, 0, "error: database parameters not set: database=$database hostname=$hostname username=$username (password) for query $query in *sqlloop");
	exit 1;
    }
    my $i;			# index on columns
    my $tablecol;		# one column name
    my $db;			# database handle
    my $sth;			# statement handle
    my $em;			# error message
    # code to deal with "lost connection to database"
    my $tries = 1;
    my $sleeptime = 1;
    my $maxtries = 11; 	# see if database comes back in 2046 seconds
    while ($tries < $maxtries) {
	sleep $sleeptime if $sleeptime > 1; # sleep 2,4,8,16,32,64,128,256,512,1024 secs
	if (($db = DBI->connect("DBI:mysql:$database:$hostname", $username, $password))) {
	    last;		# success
	}
	$tries++;
	$sleeptime *= 2;
    } # while
    if ($tries >= $maxtries) {
	&expandfile::errmsg($symtbptr, 0, "warning: cannot open DBI:mysql:$database:$hostname $username for query $query in *sqlloop");
	exit 1;
    }
    # prepare the query
    if (!($sth = $db->prepare($query))) {
	$em = $db->errstr;
	$db->disconnect;
	&expandfile::errmsg($symtbptr, 1, "error: cannot prepare query $query $em for query $query in *sqlloop");
    }
    # code to deal with "out of memory"
    $tries = 1;
    $maxtries = 11;
    $sleeptime = 1;
    while ($tries < $maxtries) {
	sleep $sleeptime if $sleeptime > 1; # sleep 2,4,8,16,32,64,128,256,512,1024 seconds
	if ($sth->execute) {
	    last;		# success
	}
	$tries++;
	$sleeptime *= 2;
    }
    if ($tries >= $maxtries) {
	$sth->finish;
	$em = $db->errstr;
	$db->disconnect;
	&expandfile::errmsg($symtbptr, 1, "error: cannot execute query $query $em for query $query in *sqlloop");
    }
    $result = '';
    my $nrows = $sth->rows;
    &expandfile::errmsg($symtbptr, 0, "trace: *sqlloop '$query' => $nrows") if (&expandfile3::getter($symtbptr, '_xf_tracebind') ne '');
    &expandfile::setter($symtbptr, '_xf_nrows', $sth->rows);
    my @labels = @{$sth->{NAME}}; # get column names.
    my @tables = @{$sth->{'mysql_table'}}; # .. and table names
    # for each returned row, expand the iterator once with values bound to the row's columns.
    while (@array = $sth->fetchrow_array) {
	&expandfile::setter($symtbptr, '_xf_colnames', '');	# doing this every row is simpler than adding logic to do it once
	for ($i=0;  $i<@labels; $i++) {
	    $tablecol = $tables[$i].'.'.$labels[$i]; # table name is blank for expressions
	    if ($tablecol =~ /\#sql.+\.count\(\*\)/) { # mySQL specific..
		$tablecol = 'count';
	    }
	    &expandfile::catter($symtbptr, '_xf_colnames', ' ') if (&expandfile3::getter($symtbptr, '_xf_colnames') ne '');
	    &expandfile::catter($symtbptr, '_xf_colnames', $tablecol);
	    &expandfile::setter($symtbptr, $tablecol, $array[$i]);
	    # if (&expandfile::getter($symtbptr, '_xf_escape') eq 'y') { # hmm, do I need this
	    # 	&expandfile::setter($symtbptr, $tablecol, &escape($array[$i]));
	    # } else {
	    # 	&expandfile::setter($symtbptr, $tablecol, $array[$i]);
	    # }
	    &expandfile::errmsg($symtbptr, 0, "trace: bound $tablecol = $array[$i]") if (&expandfile3::getter($symtbptr, '_xf_tracebind') ne '');
	} # for
	$result .= &expandfile::expandstring($iterator, $symtbptr);
    } # while fetchrow
    $sth->finish if defined($sth);
    $db->disconnect if defined($db);
    return $result;
} # iterateSQL
