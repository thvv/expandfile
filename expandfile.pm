#!/usr/local/bin/perl
# Functions for HTML template expansion.
# Heavy version. !!!!!!!!!!!!!!!!
# -- Supports *sqlloop and *xmlloop
# -- Needs more CPAN modules installed: DBI, DBD::mysql, XML::LibXML
#
# 05/23/03 THVV 1.0 created module
# 11/29/03 THVV 1.1 moved expandMultics into it
# 10/11/04 THVV 1.2 added conditional expansion; renamed to thvve.pm
# 01/11/05 THVV 1.3 reorg code, spell out verbs, add expandblocks
# 01/16/05 THVV 1.4 add *sqlloop
# 01/25/05 THVV 1.5 add indirect get and set, added =~ operator, *call
# 02/15/05 THVV 1.6 add *onchange, *onnochange, *expandv, added alternate rel ops
# 02/17/05 THVV 1.61 look in environment for gvalue, add debug
# 02/20/05 THVV 2.0 allow nesting of calls, quoting; add *csvloop
# 03/10/05 THVV 2.1 add *dirloop, *exit
# 03/18/05 THVV 2.11 fix *subst use of $1 etc
# 06/24/05 THVV 2.12 add bracketplus and bracketminus
# 09/15/05 THVV 2.2 make *include and ! references bind *block
# 09/18/05 THVV 2.3 add *ssvloop, *popssv
# 11/19/05 THVV 2.4 put titles in {{ }} and {[ ]} links, add {@ @}
# 11/22/05 THVV 2.41 improve {@ @} to do descriptions
# 01/09/06 THVV 2.42 subtle fix in &execute_command() to not add space at start of value.
# 02/22/06 THVV 2.43 add titles to {! !} links
# 03/01/06 THVV 2.44 use 'mxrelative' so THVV pages can also use mx expansions, add 'innewwindow'
# 03/31/06 THVV 2.3 add *expandv, change titles in {{ }} and {[ ]} links to look in database
# 04/20/06 THVV 2.4 add *decrement, *product, *quotient, *scale, *ncopies, "!~", ">=", "<="
# 07/16/06 THVV 2.41 add "eqlc", "nelc"
# 07/30/06 THVV 2.42 add *quotientrounded
# 08/07/06 THVV 2.43 skip null entries in ssvloop
# 08/25/06 THVV 2.44 make callv return null if it was returning just a NL
# 09/24/06 THVV 2.45 make *scale round its answer
# 10/20/06 THVV 2.46 add *htmlescape
# 02/03/07 THVV 2.47 add *fappend
# 02/21/07 THVV 2.48 bind _colnames in sqlloop
# 03/01/07 THVV 2.49 work better with -w
# 03/01/07 THVV 2.5 Prefix some machinery vars with underscore, e.g. _nrows, add _tracebind, add *dump
# 03/31/07 THVV 2.6 Add {*relpath text*} as a link to Multics source at MIT
# 04/17/07 THVV 2.61 Allow a blank iterator in sqlloop
# 02/23/08 THVV 2.62 If db connect fails, try every minute for 10 mins
# 08/13/08 THVV 2.7 add *includeraw
# 09/08/08 THVV 2.71 call gvalue() in fwrite and fappend
# 12/06/08 THVV 2.8 sleep and retry on SQL errors
# 03/14/09 THVV 2.81 lengthen sleep time on SQL errors
# 01/08/10 THVV 2.9 add *fread
# 02/11/11 THVV 2.91 have *exit call die, take optional args; minor fix to *dump output
# 02/18/11 THVV 2.92 fix junk empty line in output when nested expansions
# 06/20/11 THVV 2.93 use gvalue in expandmultics so it can be set in the makefile
# 04/22/12 THVV 2.94 remove indirect get/set (1.5): not needed, use nesting
# 04/11/13 THVV 2.95 put tinyglob in a span "nb" for nobreak
# 02/06/15 THVV 3.0 print errors to STDERR with warn instead of using die or print
# 02/06/15 THVV 3.0 add *warn
# 03/03/15 THVV 3.1 allow double quote => quote inside a quoted string in CSV format
# 03/30/15 THVV 3.2 add *xmlloop, which calls readbindxml.pm
# 05/13/15 THVV 3.21 let *xmlloop and *csvloop read gzipped files
# 05/17/15 THVV 3.3 added *urlfetch,&result,=url
# 05/17/15 THVV 3.3 added *fread2,&result,=filename   # will remove *fread later
# 05/17/15 THVV 3.3 added *shell,&result,varnameorliteral
# 05/17/15 THVV 3.3 removed *call, |=, !
# 05/21/15 THVV 3.3 changed error message to include the file path and macro name
# 06/27/15 THVV 3.31 print fatal errors in red, warnings in green
# 07/16/15 THVV 3.32 use gzcat rather than zcat
# 05/27/16 THVV 3.33 must escape { in regexps with new Perl 5.22
# 07/17/16 THVV 3.331 print *warn messages in green
# 09/08/16 THVV 3.332 fix dirloop: "isdst" and rwx modes
# 03/31/17 THVV 3.34 add *format
# 03/27/18 THVV 3.341 fix iterateCSV to create colnames list using _ssvsep
# 04/06/18 THVV 3.35 add optional XPath to *xmlloop
# 04/08/15 THVV 3.36 warn on unknown relational op
# 09/08/15 THVV 3.37 make *fread and *fread2 take output arg as first arg
# 09/08/15 THVV 4.0 Heavy version. Always does Multics expansions. Uses readbindxml and readbindsql.
# 09/08/15 THVV 4.1 change expandMultics to ignore ill-formed expansion requests, such as appear in comments
# 10/28/19 THVV 4.2 turn off multics expansion if 'database' is not defined
# 01/06/20 THVV 4.3 add *bindcsv
#
# Copyright (c) 2003-2019 Tom Van Vleck
 
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

package expandfile;			# !!!!!!!!!!!!!!!!
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(expandstring expandblocks expandMulticsBody);

use LWP::Simple;
use Term::ANSIColor;

# ================================================================
# !!!!!!!!!!!!!!!! packages used by expandfile  !!!!!!!!!!!!!!!!

use readbindxml;		# provides &iterateXML(), wants XML::LibXML
use readbindsql;		# provides &iterateSQL(), wants DBI and DBD::mysql

# ================================================================
# Expand a template.
#   $string = &expandstring($templateString, \%symtb)
#
# constructs like %[foo]% are replaced by foo's value.
# calls &getv() to expand the insdes of bracketed things, qv.
#
# Nesting and quoting handle the following, say %[y]% is 33: 
#  %[*set,&x,=ab%[y]%cd]%    # expand %[y]% first => ab33cd
#  %[*set,&x,=ab\%[y]\%cd]%  # don't expand, because % is escaped => ab%[y]%cd
#  %[*set,&x,=ab"%[y]%"cd]%  # don't expand, because %[y]% is quoted => ab%[y]%cd
#  %[*set,&x,="]%"]%         # => ]%
#  %[*set,&x,="\""]%         # => quote mark
#
# Consequence.. \ is always an escape character that makes the next character literal. It must be doubled in input compared to regular HTML.
# Consequence.. quotes are special inside %[ ]% but not special at level 0.
# Consequence.. "%[abc]%" at level 0 is expanded, even though it is quoted. We want this, for e.g. href.
# Consequence.. "%[abc]%" inside %[ ]% is not expanded, because of the quotes.
# Consequence.. Unbalanced quotes in a comment will cause an error.
#
# This function should be called on the result of &expandblocks(), ie call it first.
sub expandstring {
    my $s = shift;		# The template string.
    my $symtbptr = shift;	# Ref to hash with variable bindings.
    my $state = 0;		# 0 = copy, 1 = inside %[]%, 2 = inside %[""]%
    my $i = 0;			# Current char in the template.
    my $n = length($s);		# Length of the template.
    my $o = '';			# Working string being assembled.  When level==0 this is the output. Otherwise it is an arg.
    my $level = 0;		# Nesting depth of %[]%
    my @stack = ();		# Stack of $o values, for nested expansions.
    my @args;			# List of comma separated items at current level.
    my @svargs = ();		# List of items from previous levels followed by count.
    my $charbefore = "\n";	# Last char output, used to detect %[...]% as only thing on a line and not output a blank.
    my $nargs;			# Number of items at current level.
    my $peek;			# where unclosed string begins, in case of error message
    my $v;			# value returned by getv
    my $lineno = 0;		# .. future attempt to track line for error message .. will work wrong for *block and include files
    my $c;

    while ($i < $n) {
	$c = substr($s, $i, 1);
	if ($c eq '\\') {
	    $o .= substr($s, $i+1, 1); # copy escaped char without looking
	    $i++;
	} elsif (($state == 1) && ($c eq "\"")) {
	    $state = 2;		# Start of quoted string: don't copy the quote.
	    $peek = substr($s, $i-10, 11); # Save the start of the quoted string for error msg.
	} elsif (($state == 2) && ($c eq "\"")) {
	    $state = 1;		# End of quoted string: don't copy the quote.
	} elsif (($state == 1) && ($c eq ",")) {
	    #warn "push $o\n"; ## DEBUG
	    push @args, $o;	# Comma ends this argument.
	    $o = '';
	} elsif (($state == 1) && (substr($s, $i, 2) eq "]%")) { # end of evaluation
	    #warn "ket push $o\n"; ## DEBUG
	    push @args, $o;	# Save last argument.
	    $o = pop @stack;	# Restore the saved string from before evaluation started.
	    #warn "popped $o, args @args\n"; ## DEBUG
	    $level --;          # decrease level
	    $state = 0 if $level == 0;
	    $charbefore = substr($o, -1, 1) if $o ne '' && $level == 0; # Peek at the output so far.
	    $v = &getv($symtbptr, @args); # Call getv() to evaluate args.. either a variable value or a builtin function.
	    #warn "getv @args returned '$v'\n"; ## DEBUG
	    $o .= $v;		# Add the result of evaluation to the output or arg being built.
	    $nargs = pop @svargs; # Restore the arg count.
	    @args = ();
	    while ($nargs-- > 0) { # Restore the old saved args.
		my $onearg = pop @svargs;
		unshift @args, $onearg;
	    }
	    #warn "restored args to @args\n"; ## DEBUG
	    $i++ if (substr($s, $i+2, 1) eq "\n") && ($charbefore eq "\n"); # If a whole input line is %[...]%, do not generate an empty line.
	    $i++;		# 2-char item
	} elsif (($state != 2) && (substr($s, $i, 2) eq "%[")) { # beginning of evaluation
	    #warn "bra\n"; ## DEBUG
	    push @stack, $o;	# save what we were working on
	    $o = '';		# work on a new string
	    push @svargs, @args; # save the args
	    $nargs = @args;	# save arg count
	    push @svargs, $nargs;
	    @args = ();		# empty the argstack
	    $state = 1;		# we're inside %[ ]%
	    $level++;		# increase recursion depth
	    $i++;		# 2-char item
	} else {		# ($state == 0)
	    $lineno++ if $c eq "\n";
	    $o .= $c;		# regular character, ravel onto the end
	}
	$i++;
    } # while

    # Processed all chars.  Check if anything is missing.
    if ($state == 2) {
	&errmsg($symtbptr, 1, "error: unclosed quoted string beginning '$peek'");
   }
    if ($state == 1) {
	&errmsg($symtbptr, 1, "error: need $level ]%");
    }
    if (@stack) {
	&errmsg($symtbptr, 1, "error: stack nonempty"); # shd not happen, unbalanced bra-ket will get previous error.
    }
    return $o; # return the assembled output

} # expandstring

# ================================================================
# Find block definitions, bind them in symboltable, return a template without them.  Do this before expanding.
#   $newTemplateString = &expandblocks($templateString, \%symtb)
#
# The block construct must be on a line by itself. Blocks do not nest.  So there is no need for a state machine.
# %[*block,&name,tailrexp]%

sub expandblocks {
    my $tpt = shift;		# Template to expand.
    my $symtbptr = shift;	# Ref to hash with var bindings.

    my $outval = '';
    my $itx = -1;		# itx is the cursor
    my $oitx = 0;
    my $state = 0;		# 0=normal chars, 1=inside a block
    my $line;
    my $blockname;
    my $tailrexp;
    my $oldfunc = $$symtbptr{'_currentfunction'};
    $$symtbptr{'_currentfunction'} = 'expandblocks';

    while (($itx = index($tpt, "\n", $oitx)) > -1) {
	$line = substr($tpt, $oitx, $itx-$oitx+1);
	if ($state == 1) {	# accumulating a block
	    if ($line =~ /$tailrexp/) {
		$state = 0;	# found end
	    } else {
		$$symtbptr{$blockname} .= $line;
	    }
	} else {		# not in a block
	    if ($line =~ /^%\[\*block,&?(\S+),([^]]+)\]%$/) {
		$blockname = $1; # remember block
		$tailrexp = $2;
		&validvarname($symtbptr, $blockname); # ensure it is valid
		&errmsg($symtbptr, 0, "trace: binding block $blockname") if ($$symtbptr{'_tracebind'} eq 'yes') || ($ENV{'_tracebind'} eq 'yes');
		$state = 1;
	    } else {		# regular case
		$outval .= $line;
	    }
	}
	$oitx = $itx+1;
    } # while
    if ($state == 1) {		# missing tail rexp
	$$symtbptr{$blockname} .= substr($tpt, $oitx);
	&errmsg($symtbptr, 1, "error: missing end of *block $blockname -- $tailrexp"); # should we exit?
    } else {
	$outval .= substr($tpt, $oitx); # copy rest of tpt if no NL
    }
    $$symtbptr{'_currentfunction'} = $oldfunc;
    return $outval;

} # expandblocks

# ================================================================
# [not exported]
# Expand a thing inside %[ ]% -- a reference to a variable, or a call on a builtin function.
#   $val = &getv(\%symtb, @listoftokens);
#
# Given a field of the form %[varsel|pre|post]%
# varsel is var1,var2,var3...
# return pre . value . post
# for the first nonblank var
# looking first in bindings set in the symbol table,  then in cmd environment
# if all are blank, return nothing.
# pre and post may contain \n which will bedome a newline.
#
#  %[** comment]% is a comment, replaced by nothing.
#
#  %[*set,&var,val]%          assigns val to var, returns nothing
#    if val begins with = it is a literal
#    else it is a variable name
#
#  %[*include,=filename]%     returns expanded contents of filename, processes *block
#  %[*includeraw,=filename]%  returns non-expanded contents of filename
#  %[*callv,val,v1,v2,...]%   binds v1 to param1, etc, then expands val
#  %[*expand,val]%            expands val, returns expanded value
#  %[*expandv,&var,val]%      expands val, assigns to var, returns nothing
#  %[*concat,&var,val]%       appends val to var, returns nothing
#  %[*format,&var,fmt,a1,a2,a3,...]%   uses fmt as a format string, replaces $1 $2 $3 etc, result in var, returns nothing
#  %[*ncopies,&var,val,n]%    appends val to var n times, returns nothing
#  %[*increment,&var,val]%    adds val to var, returns nothing
#  %[*decrement,&var,val]%    subtracts val from var, returns nothing
#  %[*product,&result,val1,val2]% computes val1*val2, stores in result, returns nothing
#  %[*quotient,&result,val1,val2]% computes int(val1/val2), stores in result, returns nothing
#  %[*quotientrounded,&result,val1,val2]% computes int((val1+(val2/2))/val2), stores in result, returns nothing
#  %[*scale,&result,val1,val2,val3]% computes int((val1*val3)/val2), stores in result, returns nothing
#  %[*popssv,&var,&ssv]%      pops one value off ssv, puts it in var, rewrites ssv, returns nothing
#  %[*subst,&var,left,right]% does var =~ s/left/right/ig, returns nothing
#  %[*fread,&var,=filename]%  reads filename or URL into var
#  %[*fwrite,=filename,val]%  writes val to filename, returns nothing
#  %[*fappend,=filename,val]% appends val to filename, returns nothing
#  %[*urlfetch,&var,url]%     reads URL into var
#  %[*bindcsv,=csvfile]%      read local or remote CSV file, row1 is vars, row2 is values
#  %[*if,op,v1,v2,rest]%      performs "rest" if (v1 op v2) op may be "==" "!=" ">" "<" "=~" and "!~" (etc)
#  %[*dirloop,&outvar,iterator,=dirname,starrex]% lists dirname, expands iterator once per entry matching starrex
#  %[*csvloop,&outvar,iterator,=csvfile]% read CSV file, expands iterator once per row, output in outvar
#  %[*ssvloop,&outvar,iterator,sslist]% expands iterator once per ssv item binding _ssvitem, output in outvar
#  %[*sqlloop,&outvar,iterator,query]% runs query, expands iterator once per row, output in outvar !!!! HEAVY ONLY
#  %[*xmlloop,&outvar,iterator,=xmlfile,path]% expands iterator once per item, output in outvar !!!! HEAVY ONLY
#  %[*onchange,var,command]% execute command when var changes
#  %[*onnochange,var,command]% execute command if var does not change
#                             (put before onchange if using both)
#  %[*htmlescape,s]%          Escapes HTML constructs in s, returns value
#  %[*shell,&result,varnameorliteral]%  executes a shell command and puts output (if any) in result
#  %[*dump]%                  Output entire symbol table
#  %[*exit,anything]%         print error message on STDERR and call exit(0)
#  %[*warn,anything]%         print message on STDERR and keep going
#
# Notable useful external functions: filemodshort, filesizek, filedaysold, dbcounts, gifsize, nargs
# Notable interesting include files: fileinfo.htmi, htmxlib.htmi
#
# assignment and concat do not expand variable contents, but expand does
# e.g. if a variable "pct" contains "%" and variable "hello" contains "world"
#  %[*set,&x,pct]%%[*concat,&x,=[hello]]%%[*concat,&x,pct]%%[x]% %[*expand,x]%%[x]%
# inserts "%[hello]% world" into the output.
#
# Security issue: if any web client can submit an arbitrary
# template, then they could exec code or files on the server or read ENV.
# DO NOT DO this.  Note that substitutions are not rescanned, so GET
# and POST args are probably not a problem.  But make sure that the template
# name can't come from the web and point to an arbitrary file.

sub getv {
    my $symtbptr = shift;	# Ref to hash with var bindings.
    if (@_ == ()) {
	&errmsg($symtbptr, 1, "internal error: getv args missing"); # should not happen.
    }
    my $cmd = shift;		# first element of args is command
    my $vars;
    my $pre;
    my $post;
    my $varname;
    my $fn;
    my $filen;
    my $string;
    my $op;
    my $v0;
    my $v1;
    my $v2;
    my $v3;
    my $val;
    my $i;
    my @params;
    my @savedparams;
    my $args;
    #&errmsg($symtbptr, 0, "trace: getv $cmd,@_"); ## DEBUG
    if ($cmd =~ /^\*\*/) {	    # ** begins a comment
	return '';		    # do nothing
    } elsif ($cmd =~ /^\*(.*)$/) {  # * is followed by a command name
	$cmd = $1;		    # extract command
	$$symtbptr{'_currentfunction'} = $cmd;
	if ($cmd eq 'set') {	    # set a variable in symtb
	    $varname = &argshouldbeginwith($symtbptr, '&', shift); 
	    $v1 = join ',', @_;	    # take all remaing args
	    #&errmsg($symtbptr, 0, "trace: *set $varname $v1"); ## DEBUG
	    $$symtbptr{$varname} = &gvalue($v1, $symtbptr);
	    &errmsg($symtbptr, 0, "trace: bound $varname = \"$$symtbptr{$varname}\"") if $$symtbptr{'_tracebind'} eq 'yes' || ($ENV{'_tracebind'} eq 'yes');
	} elsif ($cmd eq 'include') { # *include,=filename
	    $fn = &argshouldbeginwith($symtbptr, '=', shift); # **************** fix to gvalue later
	    &checkextraargs($symtbptr, @_);
	    return &insert_and_expand_file($fn, $symtbptr);
	} elsif ($cmd eq 'includeraw') { # *includeraw,=filename
	    $fn = &argshouldbeginwith($symtbptr, '=', shift); # **************** fix to gvalue later
	    &checkextraargs($symtbptr, @_);
	    return &insert_raw_file($fn, $symtbptr);
	} elsif ($cmd eq 'if') { # %[*if,lt,v1,v2,command...]%
	    $op = shift;
	    $v1 = shift;
	    $v2 = shift;
	    $v1 = &gvalue($v1, $symtbptr);
	    $v2 = &gvalue($v2, $symtbptr);
	    # --------- relational operators --------
	    if ((($op eq '=') && ($v1 eq $v2)) ||
		(($op eq '==') && ($v1 eq $v2)) ||
		(($op eq 'eq') && ($v1 eq $v2)) ||
		(($op eq '!=') && ($v1 ne $v2)) ||
		(($op eq 'ne') && ($v1 ne $v2)) ||
		(($op eq '<>') && ($v1 ne $v2)) ||
		(($op eq 'eqlc') && (lc $v1 eq lc $v2)) || # case insensitive
		(($op eq 'nelc') && (lc $v1 ne lc $v2)) || # case insensitive
		(($op eq '=~') && ($v1 =~ /$v2/)) || # regexp
		(($op eq 'rexp') && ($v1 =~ /$v2/)) ||
		(($op eq '!~') && ($v1 !~ /$v2/)) || # negative regexp
		(($op eq '<') && ($v1 < $v2)) ||     # numeric comparison
		(($op eq '<=') && ($v1 <= $v2)) ||   # numeric comparison
		(($op eq 'lt') && ($v1 < $v2)) ||    # numeric comparison
		(($op eq 'le') && ($v1 <= $v2)) ||   # numeric comparison
		(($op eq '>') && ($v1 > $v2)) ||     # numeric comparison
		(($op eq '>=') && ($v1 >= $v2)) ||   # numeric comparison
		(($op eq 'gt') && ($v1 > $v2)) ||    # numeric comparison
		(($op eq 'ge') && ($v1 >= $v2)) ||   # numeric comparison
		(($op eq 'tgt') && ($v1 gt $v2)) ||  # alphabetic comparison, e.g. "31" gt "100"
		(($op eq 'tlt') && ($v1 lt $v2)) ||  # alphabetic comparison
		(($op eq 'tle') && ($v1 le $v2)) ||  # alphabetic comparison
		(($op eq 'tge') && ($v1 ge $v2)) ) { # alphabetic comparison
		return &getv($symtbptr, @_); # Relation is true.  Evaluate rest of args.
	    } else {
		# either unknown operator, or known op but relation is false
		&errmsg($symtbptr, 0, "warning: unknown *if $op") if index("|=|==|eq|!=|ne|<>|eqlc|nelc|=~|rexp|!~|<|<=|lt|le|>|>=|gt|ge|tgt|tlt|tle|tge|", '|'.$op.'|') < 0;
		# make fatal later
	    }
	} elsif ($cmd eq 'expand') { # *expand,val -- output expansion of val
	    $v0 = shift;
	    &checkextraargs($symtbptr, @_);
	    $val = &gvalue($v0, $symtbptr); # fetch value to expand
	    return &expandstring(&expandMulticsBody($val, $symtbptr), $symtbptr); # !!!!!!!!!!!!!!!! Multics expansion
	} elsif ($cmd eq 'expandv') { # *expandv,&varname,val -- store expansion of val into varname
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $v0 = shift;
	    &checkextraargs($symtbptr, @_);
	    $val = &gvalue($v0, $symtbptr); # fetch value to expand
	    $$symtbptr{$varname} = &expandstring(&expandMulticsBody($val, $symtbptr), $symtbptr); # !!!!!!!!!!!!!!!! Multics expansion
	} elsif ($cmd eq 'concat') { # *concat,&varname,val -- ravels val onto varname
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $v0 = join ',', @_;	    # take all remaing args
	    $val = &gvalue($v0, $symtbptr);
	    $$symtbptr{$varname} .= $val;
	} elsif ($cmd eq 'format') { # *format,&varname,fmt,a1,a2,... -- replaces $1 $2 etc in fmt, result in varname
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $v0 = &gvalue(shift, $symtbptr); # format string
	    @va = [];		# replacement values .. this has to be global so 'getrep' can see it
	    my $n = 1;		# 1-origin index
	    while (@_) {
		$v1 = shift;
		$va[$n++] = &gvalue($v1, $symtbptr);
	    }
	    sub getrep {my $y = shift; return $va[$y];}
	    $v0 =~ s/(\$)(\d+)/getrep($2)/ge;
	    $$symtbptr{$varname} = $v0;
	} elsif ($cmd eq 'ncopies') { # *ncopies,&varname,val,n -- store n copies of val into varname
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $v0 = shift;
	    $v1 = shift;
	    &checkextraargs($symtbptr, @_);
	    $val = &gvalue($v0, $symtbptr);
	    $v2 = &gvalue($v1, $symtbptr);
	    $$symtbptr{$varname} = $val x $v2;
	} elsif ($cmd eq 'increment') { # *increment,&varname,val -- varname += val
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $v0 = shift;
	    &checkextraargs($symtbptr, @_);
	    $val = &gvalue($v0, $symtbptr);
	    #&errmsg($symtbptr, 0, "trace: increment $varname $val"); ## DEBUG
	    $$symtbptr{$varname} += $val;
	} elsif ($cmd eq 'decrement') { # *decrement,&varname,val -- varname -= val
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $v0 = shift;
	    &checkextraargs($symtbptr, @_);
	    $val = &gvalue($v0, $symtbptr);
	    $$symtbptr{$varname} -= $val;
	} elsif ($cmd eq 'product') { # *product,&varname,top,base -- store top*base into varname
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $v1 = shift;
	    $v2 = shift;
	    &checkextraargs($symtbptr, @_);
	    $val = &gvalue($v1, $symtbptr);
	    $v0 = &gvalue($v2, $symtbptr);
	    $$symtbptr{$varname} = $val * $v0;
	} elsif ($cmd eq 'quotient') { # *quotient,&varname,top,base -- store int(top/base) into varname
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $v1 = shift;
	    $v2 = shift;
	    &checkextraargs($symtbptr, @_);
	    $val = &gvalue($v1, $symtbptr);
	    $v0 = &gvalue($v2, $symtbptr);
	    if (($v0+0) == 0) {
		$$symtbptr{$varname} = 0; # divide by 0
	    } else {
		$$symtbptr{$varname} = int($val / $v0);
	    }
	} elsif ($cmd eq 'quotientrounded') { # *quotientrounded,&result,val1,val2 store int((val1/val2)+0.5) into varname
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $v1 = shift;
	    $v2 = shift;
	    &checkextraargs($symtbptr, @_);
	    $val = &gvalue($v1, $symtbptr);
	    $v0 = &gvalue($v2, $symtbptr);
	    if (($v0+0) == 0) {
		$$symtbptr{$varname} = 0; # divide by 0
	    } else {
		$$symtbptr{$varname} = int(($val / $v0) + 0.5);
	    }
	} elsif ($cmd eq 'scale') { # *scale,&varname,top,base,range -- store int((top*range)/base) into varname
	    # for example, *scale,&ans,observedvar,biggestvalue,containersize
	    # or *scale,&percent,observed,max,=100
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $v1 = shift;
	    $v2 = shift;
	    $v3 = shift;
	    &checkextraargs($symtbptr, @_);
	    $val = &gvalue($v1, $symtbptr);
	    $val = 0 if $val eq ""; # avoid -w errors
	    $v0 = &gvalue($v2, $symtbptr);
	    $v0 = 0 if $v0 eq ""; # avoid -w errors
	    $v3 = &gvalue($v3, $symtbptr);
	    $v3 = 0 if $v3 eq ""; # avoid -w errors
	    #&errmsg($symtbptr, 0, "trace: *scale $v1 = $val, $v2 = $v0"); ## DEBUG
	    if (($v0+0) == 0) {
		$$symtbptr{$varname} = 0; # divide by 0
	    } else {
		$$symtbptr{$varname} = int((($val * $v3) / $v0) + 0.5);
	    }
	} elsif ($cmd eq 'popssv') { # *popssv,&varname,&ssvvar -- pop one item off val into varname
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $v0 = &argshouldbeginwith($symtbptr, '&', shift); # literal not allowed, cause we rewrite it
	    &checkextraargs($symtbptr, @_);
	    $val = $$symtbptr{$v0}; # get the old SSV value
	    $$symtbptr{'_ssvsep'} = ' ' if $$symtbptr{'_ssvsep'} eq "";
	    $v1 = index($val, $$symtbptr{'_ssvsep'}); # look for the first item on the SSV
	    if ($v1 == -1) {
		$$symtbptr{$varname} = $val; # no separator found, return what we got
		$$symtbptr{$v0} = "";
	    } else {
		$$symtbptr{$varname} = substr($val, 0, $v1); # pop off the head of the SSV
		$$symtbptr{$v0} = substr($val, $v1+1);	     # rewrite the SSV with the tail
	    }
	} elsif ($cmd eq 'subst') { # subst,&varname,left,right -- regexp substitution applied to varname
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $pre = shift;
	    $v1 = &gvalue($pre, $symtbptr);
	    $post = join ',', @_; # take all remaing args .. wonder why i do this
	    $v2 = &gvalue($post, $symtbptr);
	    # sanitize v1 and v2, which must not contain '/' .. backtick seems to be ok
	    #$$symtbptr{$varname} =~ s/$v1/$v2/ig; didn't work, gotta do this
	    $v3 = $$symtbptr{$varname}; # get old value in case eval fails
	    $v0 = "\$v3 =~ s/$v1/$v2/ig";
	    eval($v0);		# run this on sanitized arguments only
	    $$symtbptr{$varname} = $v3;
	} elsif (($cmd eq 'fread') || ($cmd eq 'fread2')) { # *fread,&varname,filename
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $filen = &argshouldbeginwith($symtbptr, '=', shift); # **************** fix to gvalue later
	    &checkextraargs($symtbptr, @_);
	    my $content = '';
	    my $olddelim = $/;
	    $/ = undef;		# suck in the whole file in one read
	    my $fh = $incl++;
	    if (open($fh, $filen)) {
		$content = <$fh>;
		close($fh);
	    }
	    $/ = $olddelim;
	    $$symtbptr{$varname} = $content;
	} elsif ($cmd eq 'urlfetch') { # *urlfetch,&varname,=url
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $filen = &argshouldbeginwith($symtbptr, '=', shift); # **************** fix to gvalue later
	    &checkextraargs($symtbptr, @_);
	    my $content = LWP::Simple::get $filen;
	    $content = '' if !defined($content); # if not found, set varname empty
	    $$symtbptr{$varname} = $content; # ugh: this value ends in a newline.
	} elsif ($cmd eq 'bindcsv') { # *bindcsv,=url_or_filename
	    $filen = &argshouldbeginwith($symtbptr, '=', shift); # **************** fix to gvalue later
	    &checkextraargs($symtbptr, @_);
	    &bindCSV($filen, $symtbptr);
	} elsif ($cmd eq 'fwrite') { # *fwrite,filename,varname
	    $filen = &argshouldbeginwith($symtbptr, '=', shift); # **************** fix to gvalue later
	    $v0 = shift;
	    &checkextraargs($symtbptr, @_);
	    if (!open(++$incl, ">$filen")) {
		&errmsg($symtbptr, 1, "error: cannot *fwrite '$filen' $!");
	    } else {
		$v1 = &gvalue($v0, $symtbptr);
		print $incl "$v1\n";
		close $incl;
	    }
	} elsif ($cmd eq 'fappend') { # *fappend,filename,varname
	    $filen = &argshouldbeginwith($symtbptr, '=', shift); # **************** fix to gvalue later
	    $v0 = shift;
	    &checkextraargs($symtbptr, @_);
	    if (!open(++$incl, ">>$filen")) {
		&errmsg($symtbptr, 1, "error: cannot *fappend '$filen' $!");
	    } else {
		$v1 = &gvalue($v0, $symtbptr);
		print $incl "$v1\n";
		close $incl;
	    }
	} elsif ($cmd eq 'shell') { # *shell,&varname,command
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $v0 = &gvalue(shift, $symtbptr);
	    &checkextraargs($symtbptr, @_);
	    $$symtbptr{$varname} = &execute_command($v0, $symtbptr);
	} elsif ($cmd eq 'callv') { # *callv,varname -- set up args and expand a var
	    $v0 = shift;	    # get the template name
	    my $prevfilename = $$symtbptr{'_currentfilename'};
	    if ($$symtbptr{'_currentfilename'} ne '') {
		$$symtbptr{'_currentfilename'} .= ">" . $v0;
	    } else {
		$$symtbptr{'_currentfilename'} = $v0; # might want to know this
	    }
	    # if a function peeks at its args, it might see leftover args from a previous callv
	    $i = 1;
	    @savedparams = ();	# save the old values of paramX
	    while (@_) {	# save old params, bind given ones
		$v1 = 'param'.$i++; # varname to bind
		push @savedparams, $$symtbptr{$v1}; # save old value
		$v2 = shift;	    # new value to bind
		$$symtbptr{$v1} = &gvalue($v2, $symtbptr); 
	    }
	    $val = &gvalue($v0, $symtbptr); # get template value
	    $v2 = &expandstring(&expandMulticsBody($val, $symtbptr), $symtbptr); # recurse !!!!!!!!!!!!!!!! Multics expansion
	    $i = 1;
	    while (@savedparams) { # restore params to prior value
		$v1 = 'param'.$i++;
		$$symtbptr{$v1} = shift @savedparams;
	    }
	    $$symtbptr{'_currentfilename'} = $prevfilename; # pop filename
	    return '' if $v2 eq "\n";
	    return $v2;
	} elsif ($cmd eq 'dirloop') { # The problem with this one is that you can't select "no symlinks" etc.??
	    $varname = &argshouldbeginwith($symtbptr, '&', shift); # outvar
	    $v1 = shift;	# iterator
	    $v2 = shift;	# dirname
	    $v3 = shift;	# name regexp
	    &checkextraargs($symtbptr, @_);
	    $$symtbptr{$varname} = &iterateDir(&gvalue($v1, $symtbptr), &gvalue($v2, $symtbptr), &gvalue($v3, $symtbptr), $symtbptr);
	} elsif ($cmd eq 'csvloop') { # *csvloop,&varname,iteratorvar,csvfile -- loop over a CSV
	    $varname = &argshouldbeginwith($symtbptr, '&', shift); # outvar
	    $v1 = shift;	# iterator
	    $v2 = shift;	# csv file
	    &checkextraargs($symtbptr, @_);
	    $$symtbptr{'_ssvsep'} = ' ' if $$symtbptr{'_ssvsep'} eq "";
	    $$symtbptr{$varname} = &iterateCSV(&gvalue($v1, $symtbptr), &gvalue($v2, $symtbptr), $symtbptr);
	} elsif ($cmd eq 'ssvloop') { # *ssvloop,&varname,iteratorvar,ssvvar
	    $varname = &argshouldbeginwith($symtbptr, '&', shift); # outvar
	    $v1 = shift;	# iterator
	    $v2 = shift;	# ssv
	    &checkextraargs($symtbptr, @_);
	    $$symtbptr{'_ssvsep'} = ' ' if $$symtbptr{'_ssvsep'} eq "";
	    $$symtbptr{$varname} = &iterateSSV(&gvalue($v1, $symtbptr), &gvalue($v2, $symtbptr), $symtbptr);

	# ----------------------------------------------------------------
	# !!!!!!!!!!!!!!!! only in heavy version !!!!!!!!!!!!!!!!
	} elsif ($cmd eq 'sqlloop') { # *sqlloop,&varname,iteratorvar,query
	    $varname = &argshouldbeginwith($symtbptr, '&', shift); # outvar
	    $v1 = shift;	# iterator
	    $v2 = join ',', @_; # take all remaing args for query, commas are allowed
	    $$symtbptr{$varname} = &iterateSQL(&gvalue($v1, $symtbptr), &gvalue($v2, $symtbptr), $symtbptr);
	} elsif ($cmd eq 'xmlloop') { # *xmlloop,&varname,iteratorvar,xmlfile[,xpath] -- loop over a XML file
	    $varname = &argshouldbeginwith($symtbptr, '&', shift); # outvar
	    $v1 = shift;	# iterator
	    $v2 = shift;	# xml file
	    $v3 = shift;	# optional XPath
	    &checkextraargs($symtbptr, @_);
	    if (defined($v3)) {
		$v3 =  &gvalue($v3, $symtbptr);
	    }
	    $$symtbptr{'_ssvsep'} = ' ' if $$symtbptr{'_ssvsep'} eq "";
	    $$symtbptr{$varname} = &iterateXML(&gvalue($v1, $symtbptr), &gvalue($v2, $symtbptr), $symtbptr, $v3);
	# !!!!!!!!!!!!!!!! only in heavy version !!!!!!!!!!!!!!!!
	# ----------------------------------------------------------------

	} elsif ($cmd eq 'onchange') { # useful in iterators
	    $v0 = shift; 
	    $v1 = '_old_'.$v0;
	    #&errmsg($symtbptr, 0, "trace: onchange $v0 $v1 $$symtbptr{$v0} <> $$symtbptr{$v1} $fn"); ## DEBUG
	    if ($$symtbptr{$v1} ne $$symtbptr{$v0}) {
		$$symtbptr{$v1} = $$symtbptr{$v0};
		return &getv($symtbptr, @_); # recurse with rest of args
	    } else {
		return '';	# return with unconsumed args
	    }
	} elsif ($cmd eq 'onnochange') { # do this before "onchange" if doing both, else it fires too often
	    $v0 = shift; 
	    $v1 = '_old_'.$v0;
	    if ($$symtbptr{$v1} eq $$symtbptr{$v0}) {
		return &getv($symtbptr, @_); # recurse with rest of args
	    } else {
		return '';	# return with unconsumed args
	    }
	} elsif ($cmd eq 'exit') { # error exit -- should replace this with "*exec" cmd?
	    # Calling this function causes the calling program to abort with no output.
	    # This is pretty brutal.  Currently there is no way to say "simulate an EOF on your input."
	    &errmsg($symtbptr, 1, "error exit @_ ");
	} elsif ($cmd eq 'dump') { # dump the symbol table onto stdout, good for debugging
	    return &dump_symtb($symtbptr);
	} elsif ($cmd eq 'warn') { # print message on STDERR and keep going
	    warn color("green")."@_".color("reset")."\n"; # user does not want expandfile in the message
	} elsif ($cmd eq 'htmlescape') { # *htmlescape,val -- return htmlescaped value
	    $v0 = shift;
	    &checkextraargs($symtbptr, @_);
	    $val = &gvalue($v0, $symtbptr);
	    return &htmlEscape($val);
        } else {
	    &errmsg($symtbptr, 1, "error: unknown builtin *$cmd,@_");
	}
	return '';
    } # * is followed by a command name

# Didn't begin with a special, variable name case.  Look in symbol table or $ENV
#      %[var1,var2,var3|pre|post]%
    unshift @_, $cmd;          # put the command back on the arglist
    my $lastarg = pop;         # get the last arg, may have the pre/post tail
    ($varname, $pre, $post) = split(/\|/, $lastarg);
    $pre = "" if !defined($pre); # avoid errors if invoked under -w
    $post = "" if !defined($post);
    push @_, $varname;	       # put varname part of last arg back on the list
    $pre =~ s/\\n/\n/g;	       # provide a way to include NLs in pre and post
    $post =~ s/\\n/\n/g;
    foreach $varname (@_) {    # find the first nonempty variable
	#&errmsg($symtbptr, 0, "trace: getv: searching for $varname"); ## DEBUG
	if (defined($$symtbptr{$varname}) && ($$symtbptr{$varname} ne '')) { # in the symbol table and nonblank?
	    &validvarname($symtbptr, $varname); # warn if this is bad name
	    #&errmsg($symtbptr, 0, "trace: getv: found $varname '$$symtbptr{$varname}'"); ## DEBUG
	    return $pre . $$symtbptr{$varname} . $post;
	} elsif (defined($ENV{$varname}) && ($ENV{$varname} ne '')) { # in the command environment?
	    &validvarname($symtbptr, $varname); # warn if this is bad name
	    #&errmsg($symtbptr, 0, "trace: getv: found env $varname '$ENV{$varname}'"); ## DEBUG
	    return $pre . $ENV{$varname} . $post;
	}
    } # foreach
    # Fell out without finding a value. Optionally alert if the variable could not be found.. some code may count on this
    &errmsg($symtbptr, 0, "trace: no value for expansion '@_'") if ($$symtbptr{'_HTMXDEBUG2'} eq 'yes') || ($ENV{'_HTMXDEBUG2'} eq 'yes');
    return '';
} #getv

# ================================================================
# check if valid varname
#   &validvarname($symtbp, $vn);
sub validvarname {
    my $xp = shift;
    my $vn = shift;
    if ($vn eq '') {
	&errmsg($xp, 0, "warning: blank varname in *$$xp{'_currentfunction'}");
	# exit(1); LATER
    }
    if ($vn !~ /[-.+_0-9a-zA-Z]+/) {
	&errmsg($xp, 0, "warning: invalid chars in varname '$vn' in *$$xp{'_currentfunction'}");
	# exit(1); LATER
    }
    if  ($vn =~ /^[0-9]+$/) {
	&errmsg($xp, 0, "warning: all numeric varname '$vn' in *$$xp{'_currentfunction'}");
    }
} # validvarname

# ================================================================
# check if extra args, complain and die if so
#   &checkextraargs($symtbp, @_);
sub checkextraargs {
    my $xp = shift;
    my $ea = shift;
    return if !defined($ea);
    unshift @_, $ea;
    $ea = join(',', @_);
    &errmsg($xp, 1, "error: extra args '$ea' to *$$xp{'_currentfunction'}");
} # checkextraargs

# ================================================================
# check if an argument begins with given char, fuss if not
# .. for = this is interim code, eventually we will just call gvalue
# .. for & this also checks if the name is a valid varname
# $var = &argshouldbeginwith($symtbptr, '=', shift);
# .. the '=' case will be replaced by calls to gvalue, so that either a var name or a literal is allowed.
sub argshouldbeginwith {
    my $xp = shift;
    my $ch = shift;
    my $fn = shift;
    if ($fn =~ /^$ch(.*)$/) {
	$fn = $1;
    } else {
	&errmsg($xp, 0, "warning: '$fn' should begin with $ch in *$$xp{'_currentfunction'}");
	# **************** make fatal later
    }
    return $fn if $ch eq '=';	# literal
    &validvarname($xp, $fn);	# check that the trimmed varname is valid and fuss if bad chars in it
    return $fn;			# lvalue
} # argshouldbeginwith

# ================================================================
# [not exported]
# directory iteration function used by *dirloop
#   $val = &iterateDir($iterator, $dirname, $starname, \%values)
#
# Lists directory, matches starname, stats each file, binds values
# then expands iterator once per file and binds %[_nrows]% to the number of files found
#
# if dirname is not found, does nothing, binds %[_nrows]% to 0
#
sub iterateDir {
    my $iterator = shift;
    my $dn = shift;
    my $starx = shift;
    my $symtbptr = shift;
    my $result = '';
    my $nfiles = 0;
    my $rawmode = 0;
    my $f;
    if (-d $dn) {
	if (!opendir(DH, "$dn")) {
	    &errmsg($symtbptr, 0, "warning: error opening directory '$dn' in *dirloop $!");
	    $$symtbptr{'_nrows'} = 0;
	    return '';
	}
	my(@allfiles) = sort grep !/^\./, readdir DH;
	closedir DH;
	#&errmsg($symtbptr, 0, "trace: read dir $dn");  # DEBUG
	foreach $f (@allfiles) {
	    if ($f =~ /$starx/) { # How can i select dirs/files/links??
		$nfiles++;
		$$symtbptr{'file_name'} = $f;
		$$symtbptr{'file_type'} = 'f';
		$$symtbptr{'file_type'} = 'd' if -d $f;	# dir
		$$symtbptr{'file_type'} = 'l' if -l $f; # symlink
		$$symtbptr{'file_type'} = 'p' if -p $f; # pipe
		$$symtbptr{'file_type'} = 's' if -S $f; # socket
		($$symtbptr{'file_dev'},     # device number of fs
		 $$symtbptr{'file_ino'},     # inode number
		 $rawmode,                    # file mode, needs conversion to rwx
		 $$symtbptr{'file_nlink'},   # number of hardlinks
		 $$symtbptr{'file_uid'},     # uid of file owner
		 $$symtbptr{'file_gid'},     # gid of file owner
		 $$symtbptr{'file_rdev'},    # device ID for special files
		 $$symtbptr{'file_size'},    # size in bytes
		 $$symtbptr{'file_atime'},   # access time
		 $$symtbptr{'file_mtime'},   # modification time (used below)
		 $$symtbptr{'file_ctime'},   # inode change time
		 $$symtbptr{'file_blksize'}, # preferred block size
		 $$symtbptr{'file_blocks'}) = stat("$dn/$f"); # actual 512-byte blocks allocated
		$$symtbptr{'file_mode'} = &rwxmode($rawmode);
		($$symtbptr{'file_sec'},
		 $$symtbptr{'file_min'},
		 $$symtbptr{'file_hour'},
		 $$symtbptr{'file_mday'},
		 $$symtbptr{'file_mon'},
		 $$symtbptr{'file_year'},
		 $$symtbptr{'file_wday'},
		 $$symtbptr{'file_yday'},
		 $$symtbptr{'file_isdst'}) = localtime($$symtbptr{'file_mtime'});  # 1 if DST, 0 if not, -1 if unknown
		$$symtbptr{'file_year'} -= 100 if $$symtbptr{'file_year'} >= 100; # show 2005 as 05
		$$symtbptr{'file_year'} = &twodigit($$symtbptr{'file_year'});
		$$symtbptr{'file_mday'} = &twodigit($$symtbptr{'file_mday'});
		$$symtbptr{'file_mon'} = &twodigit($$symtbptr{'file_mon'}+1);
		$$symtbptr{'file_hour'} = &twodigit($$symtbptr{'file_hour'});
		$$symtbptr{'file_min'} = &twodigit($$symtbptr{'file_min'});
		$$symtbptr{'file_sec'} = &twodigit($$symtbptr{'file_sec'});
		$$symtbptr{'file_datemod'} = "$$symtbptr{'file_mon'}/$$symtbptr{'file_mday'}/$$symtbptr{'file_year'} $$symtbptr{'file_hour'}:$$symtbptr{'file_min'}\n";
		$$symtbptr{'file_modshort'} = "$$symtbptr{'file_mon'}/$$symtbptr{'file_mday'}/$$symtbptr{'file_year'}\n";
		#@moname = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec','Jan');
		#$$symtbptr{'datemod'} = "$year-$month-$mday $hour:$min";

		$$symtbptr{'file_sizek'}= int(($$symtbptr{'file_size'}+1023)/1024);
		$$symtbptr{'file_age'} = int((time - $$symtbptr{'file_mtime'})/86400);
		# for each dir entry, expand the iterator once with values bound to the file's attributes.
		$result .= &expandstring($iterator, $symtbptr);
	    } # if starname
	} # foreach $f
    } else { # not dir
	warn &errmsg($symtbptr, 0, "warning: '$dn' not a dir in *dirloop");
    }
    $$symtbptr{'_nrows'} = $nfiles;
    return $result;
} # iterateDir

# ----------------------------------------------------------------
# [not exported]
# prettifier for modes
#    $val = &rwxmode ($rawmode)
sub rwxmode {
    my $x = shift;
    my @p = qw(--- --x -w- -wx r-- r-x rw- rwx);
    my @y = @p[($x&0700)>>6, ($x&0070)>>3, $x&0007];
    # ignore stickybit and setuid
    return join('', @y);
} # rwxmode

# ----------------------------------------------------------------
# [not exported]
# prettifier for dates
#    $val = &twodigit ($field)
sub twodigit {			# returns field with leading zero if necessary
    my $x = shift;
    return "$x" if ($x > 9);
    return "0$x";
} # twodigit

# ================================================================
# [not exported]
# ssv iteration function used by *ssvloop
#   $val = &iterateSSV($iterator, $ssv, \%values)
#
# Expands iterator once per element of the ssv, binding the element to %[_ssvitem]%
# Does not destroy the ssv
# skips null entries in the ssv
# returns the concatenation of all expansions and sets %[_nssv]% to the count
#
sub iterateSSV {
    my $iterator = shift;
    my $val = shift;
    my $symtbptr = shift;
    my $result = '';
    my $n = 0;
    my $more = 1;
    my $v1;
    $$symtbptr{'_ssvsep'} = ' ' if $$symtbptr{'_ssvsep'} eq "";
    if ($val ne "") {
	while ($more) {
	    $v1 = index($val, $$symtbptr{'_ssvsep'}); # find separator
	    if ($v1 == -1) {
		$$symtbptr{'_ssvitem'} = $val; # no sep, take whole thing, maybe null
		$more = 0;
	    } else {
		$$symtbptr{'_ssvitem'} = substr($val, 0, $v1); # peel off one item
		$val = substr($val, $v1+1); # rewrite the ssv with one less
	    }
	    &errmsg($symtbptr, 0, "trace: bound _ssvitem = $$symtbptr{'_ssvitem'}") if $$symtbptr{'_tracebind'} eq 'yes' || ($ENV{'_tracebind'} eq 'yes');
	    $result .= &expandstring($iterator, $symtbptr) if $$symtbptr{'_ssvitem'} ne ''; # expand iterator and ravel result
	    $n++;
	}
    }
    $$symtbptr{'_nssv'} = $n;
    return $result;
} # iterateSSV

# ================================================================
# [not exported]
# CSV iteration function used by *csvloop
#   $val = &iterateCSV($iterator, $csvfile, \%values)
#
# first row is var names
# read additional rows, bind values to names
# expand iterator once per row
# binds %[_nrows]% to the count of rows
# binds %[_colnames]% to the column names
#
sub iterateCSV {
    my $iterator = shift;
    my $csvfile = shift;
    my $symtbptr = shift;
    my $result = '';
    my $i;
    my $tablecol;
    my $v;
    my $line;
    my @labels;
    my @vals;
    my $nrows = 0;
    
    my $fh = $incl++;
    if ($csvfile =~ /\.gz$|\.z$/i) {
    	if (!open($fh, "gzcat $csvfile |")) {
	    &errmsg($symtbptr, 1, "error: missing compressed CSV file '$csvfile' $! in *csvloop");
	}
    } else {
    	if (!open($fh, "$csvfile")) {
	    # here is where to call  LWP::Simple::get $csvfile if you want to allow fetching over web. Needs restructuring.
	    &errmsg($symtbptr, 1, "error: missing CSV file '$csvfile' $! in *csvloop");
	}
    }
    $line = <$fh>;              # read and parse labels from first line, set @labels
    $line =~ s/[\n\r]//;	# lose final CR/NL
    @labels = &csvparse($line);
    # .. could check the labels to see if they contain illegal stuff
    $$symtbptr{'_colnames'} = join $$symtbptr{'_ssvsep'}, @labels; # bind list of column names for reflection
    &errmsg($symtbptr, 0, "trace: cols $$symtbptr{'_colnames'}") if ($$symtbptr{'_tracebind'} eq 'yes') || ($ENV{'_tracebind'} eq 'yes'); 
    # for each returned row, expand the iterator once with values bound to the row's columns.
    while (<$fh>) {
	$line = $_;		# Read a line.
	$line =~ s/[\n\r]//;	# lose final CR/NL
        while (substr ($line, -1) eq '\\') { # if line ends in backslash, read another line and concat
            chop ($line);
            my $inputlinecontinuation = <$incl>;    # read next line
            $inputlinecontinuation =~ s/\r?\n$//;
            $inputlinecontinuation =~ m/^\s*(.*)$/; # trim leading whitespace
            $line = $line.$1;
        }
	$nrows++;
	@vals = &csvparse($line); # parse the row
	for ($i=0;  $i<@labels; $i++) {
	    $tablecol = $labels[$i];
	    $v = shift @vals;	  # if there are too few values, this will be empty, so missing ones will be set to ""
	    $$symtbptr{$tablecol} = $v;
	    &errmsg($symtbptr, 0, "trace: bound $tablecol = $v") if ($$symtbptr{'_tracebind'} eq 'yes') || ($ENV{'_tracebind'} eq 'yes');
	} # for
	if ($iterator ne '') {
	    $result .= &expandstring($iterator, $symtbptr);
	} # iterator nonblank
    } # while fetchrow
    close($fh);
    $$symtbptr{'_nrows'} = $nrows; # Report results.
    return $result;
} # iterateCSV

# [not exported]
# Parse a CSV line into a perl array
# .. see RFC4180
# returns an array of strings
sub csvparse {
    my $s = shift;		# get arg
    my $i = 0;			# char index in input
    my $r = '';			# current result value
    my $state = 0;		# quote state. 0 = not in quotes, 1=in quotes
    my @result = ();		# output array of strings
    my $c;			# character $i of input string $s
    while ($i < length($s)) {
	$c = substr($s, $i, 1);
	if (($state == 0) && ($c eq ',')) { # not in quotes and see a comma
	    push @result, $r;   # (comma inside quotes is just a character)
	    $r = '';
	} elsif (($state == 0) && ($c eq '"')) { # not in quotes and see a quote
	    $state = 1;
	} elsif (($state == 1) && ($c eq '"')) { # in quotes and see a quote
	    if (($i+1 < length($s)) && (substr($s, $i+1, 1) eq '"')) {
		$i++;		# inside a quoted string, see two double quotes
		$r .= '"';	# .. becomes one double quote
	    } else {
		$state = 0;	# end of quoted string, value does not have the quotes
	    }
	} elsif ($c eq "\n") {	# newline, ignore .. won't happen in iterateCSV
	    # IGNORE
	} else {		# regular character
	    $r .= $c;		# concat char onto element
	}
	$i++;
    } # while
    push @result, $r;		# last element
    return @result;
} # csvparse

# ================================================================
# [not exported]
# Read in 2-line CSV file and bind vars.. File can be remote, specified by URL, or local pathname.
#   &bindCSV($csvfile, \%values)
#
# first row is var names
# second row is values, bind to names
# binds %[_colnames]% to the column names
#
sub bindCSV {
    my $csvfile = shift;
    my $symtbptr = shift;
    my $content;
    my $i;
    my $tablecol;
    my $v;
    my $line;
    my @labels;
    my @vals;
    my $nrows = 0;

    if ($csvfile =~ /^https?:\/\//i) {
	# call  LWP::Simple::get $csvfile 
	$content = LWP::Simple::get $csvfile;
	$content = '' if !defined($content); # if not found, set varname empty
	&errmsg($symtbptr, 1, "error: missing remote CSV file '$csvfile' in *bindcsv") if $content eq '';
    } else {			# not http, local file
	my $fh = $incl++;
	if ($csvfile =~ /\.gz$|\.z$/i) {
	    if (!open($fh, "gzcat $csvfile |")) {
		&errmsg($symtbptr, 1, "error: missing compressed CSV file '$csvfile' $! in *bindcsv");
	    }
	} else {
	    if (!open($fh, "$csvfile")) {
		&errmsg($symtbptr, 1, "error: missing CSV file '$csvfile' $! in *bindcsv");
	    }
	}
	my $olddelim = $/;
	$/ = undef;		# suck in the whole file in one read
	$content = <$fh>;
	close($fh);
	$/ = $olddelim;
    } # not http, local file

    $content =~ s/\r/\n/g;	# change CR to NL in case Mac
    $content =~ s/\n\n/\n/g;	# change NL NL to NL in case Windows
    my $j = index($content, "\n");	# look for the NL delimiting the header line from the body line
    &errmsg($symtbptr, 1, "error: no values in CSV file '$csvfile' in *bindcsv") if $j < 0;
    $line = substr($content, 0, $j); 
    @labels = &csvparse($line);
    # .. could check the labels to see if they contain illegal stuff
    $line = substr($content, $j+1); # rest of file should be one line of comma separated values
    chomp $line;		# trim trailing NL if any
    #warn "$line\n";
    &errmsg($symtbptr, 1, "error: malformed CSV file '$csvfile' in *bindcsv") if $line eq '' || index($line, "\n") >= 0; # if no values or too many
    $$symtbptr{'_ssvsep'} = ' ' if $$symtbptr{'_ssvsep'} eq '';
    $$symtbptr{'_colnames'} = join $$symtbptr{'_ssvsep'}, @labels; # bind list of column names for reflection
    &errmsg($symtbptr, 0, "trace: cols $$symtbptr{'_colnames'}") if ($$symtbptr{'_tracebind'} eq 'yes') || ($ENV{'_tracebind'} eq 'yes'); 
    @vals = &csvparse($line); # parse the row into an array of strings
    for ($i=0;  $i<@labels; $i++) {
	$tablecol = $labels[$i];
	$v = shift @vals;	  # if there are too few values, this will be empty, so missing ones will be set to ""
	$$symtbptr{$tablecol} = $v;
	&errmsg($symtbptr, 0, "trace: bound $tablecol = $v") if ($$symtbptr{'_tracebind'} eq 'yes') || ($ENV{'_tracebind'} eq 'yes');
    } # for
    return;
} # bindCSV
# ================================================================
# [not exported]
# Given a builtin argument reference, return a value.
#   $result = &gvalue($varname, \%symtb);
# (Does not support multiple varnames separated by commas, or pre and post strings... see &getv.)
# -- Literals begin with = and will have \n expanded
# -- otherwise it's a variablename, look up in the symbol table and the ENV.  If not found, return empty string.
# XXX could put in a quoting convention here for punctuation (now i forget what i meant by this)
sub gvalue {
    my $x = shift;
    my $xptr = shift;
    my $v;
    #warn &errmsg($xp, 0, "trace: gvalue $x"); ## DEBUG
    if ($x =~ /^=(.*)/) {	# literal
	$v = $1;
	$v =~ s/\\n/\n/g;	# change escaped NL to real
	return $v;
    }
    # not a special case, take symbol table or cmd envir
    if (defined($$xptr{$x})) { # in the symbol table and nonblank?
	return $$xptr{$x};
    } elsif (defined($ENV{$x})) { # in the command environment?
	return $ENV{$x};
    }
    # if $x is all digits, probably forgot an equal sign
    &errmsg($xptr, 0, "warning: missing = before numeric argument '$x'") if $x =~ /^[0-9]+$/; # i do this sometimes, ,0 instead of ,=0
    # optionally alert if there is no value for the arg.. some code may count on this.
    &errmsg($xptr, 0, "warning: no value for argument '$x'") if ($$xptr{'_HTMXDEBUG2'} eq 'yes') || ($ENV{'_HTMXDEBUG2'} eq 'yes');
    return '';

} # gvalue

# ================================================================
# [not exported]
# given a filename, read it in, expand its contents, and return the content
#   $v = &insert_and_expand_file($filename, \%values);
# sets global: incl
# include files can include other files, should all work..
sub insert_and_expand_file {
    my $filename = shift;	# This filename is unchecked.. don't let users from outside specify it.
    my $xptr = shift;
    my $olddelim = $/;
    $/ = undef;
    my $fh = $incl++;
    if (!open($fh, $filename)) {
	&errmsg($xptr, 1, "error: missing *include '$filename' $!");
    }
    my $content = '';
    $content .= <$fh>;	# fast read
    close($fh);
    $/ = $olddelim;
    $content = &expandblocks($content, $xptr); # make *include honor *block ---- push and pop here? no.
    my $oldfilename = $$xptr{'_currentfilename'};
    if ($$xptr{'_currentfilename'} ne '') {
	$$xptr{'_currentfilename'} .= ">" . $filename;
    } else {
	$$xptr{'_currentfilename'} = $filename; # might want to know this
    }
    my $ans = &expandstring(&expandMulticsBody($content, $xptr), $xptr); # rescan its value to execute *set, *include, etc !!!!!!!!!!!!!!!! Multics
    $$xptr{'_currentfilename'} = $oldfilename; # pop
    return $ans;
} # insert_and_expand_file

# ================================================================
# [not exported]
# given a filename, read it in, and return the content without expanding
#   $v = &insert_raw_file($filename, \%values);
sub insert_raw_file {
    my $filename = shift;	# This filename is unchecked.. don't let users from outside specify it.
    my $xptr = shift;
    my $olddelim = $/;
    $/ = undef;
    my $fh = $incl++;
    if (!open($fh, $filename)) {
	&errmsg($xptr, 1, "error: missing *includeraw '$filename' $!");
    }
    my $content = '';
    $content .= <$fh>;
    close($fh);
    $/ = $olddelim;
    return $content;
} # insert_raw_file 

# ================================================================
# [not exported]
# Execute a command and capture its output as a string.
#    $v = &execute_command($x, symtbptr);
# If multi-line output, change it to space separated.
sub execute_command {
    my $cmd = shift;
    my $xptr = shift;
    $$xptr{'_ssvsep'} = ' ' if $$xptr{'_ssvsep'} eq '';
    my $content = '';
    my $fh = $incl++;
    if (!open($fh, "$cmd|")) {
	&errmsg($xptr, 0, "warning: cannot execute external command '$cmd' $!");
    }
    while (<$fh>) {	# ravel all lines, space separated
	chomp;
	$content .= $$xptr{'_ssvsep'} if $content ne '';
	$content .= $_;
    } # ravel
    close($fh);
    return $content;
} # execute_command
# ================================================================
# use Encode;

# Convert a string to safe HTML
#   $s = &htmlEscape($s);
# uses global: -
# sets global: -
sub htmlEscape {
    my $x = shift;
    $x =~ s/\&/\&amp;/g;
    $x =~ s/\"/\&quot;/g;
    $x =~ s/\</\&lt;/g;
    $x =~ s/\>/\&gt;/g;
    $x =~ s/\'/\&\#39;/g;
    #$x = decode("utf8", $x, Encode::FB_HTMLCREF); # handle Unicode to HTML encoding? maybe don't need.
    return $x;
} # htmlEscape
# ================================================================
# dump
#   &dump_symtb(\%symtb);
sub dump_symtb {
    my $symtbptr = shift;
    my $result = '';
    for (keys %$symtbptr) {		# dump environment
        $result .= "**dump $_**=**$$symtbptr{$_}**\n";
    }
    return $result;
} # dump_symtb
# ================================================================
# write a warning
# &errmsg(\%v, 0, "message");
# param2 = 0 if warning, else fatal
sub errmsg {
    my $sym = shift;
    my $fatal = shift;
    my $msg = shift;
    my $chosencolor = color("green");
    $chosencolor = color("red") if $fatal==1;
    warn $chosencolor."$$sym{'me'}: $$sym{'_currentfilename'} $msg".color ("reset")."\n";
    exit($fatal) if $fatal != 0;
} # errmsg

# ================================================================
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Expand special HTMX constructs for Multics web pages.
#
#   $x = &expandMulticsBody($string, \%values);
#
#       {:string:} into <span class=bracketcolonclass>string</span>
#                       (bracketcolonclass=cmd)
#       {=string=} into <span class=bracketequalclass>string</span>
#                       (bracketequalclass=pathname)
#       {+string+} into <span class=bracketplusclass>string</span>
#                       (bracketplusclass=code)
#       {-string-} into <span class=bracketminusclass>string</span>
#                       (bracketminusclass=special)
#       {*string*} into a reference to multics source, when this is figured out
#                       (multicssourceroot=)
#       {{id string}} into mgloss ref <a href="peoplefile.html#id" title="did">string</a>
#                       (peoplefile=multicians)
#       {[id string]} into multicians ref <a href="glossbaseX.html#id" title="summary">string</a>
#                       (glossbase=mgloss)
#       {!word string!} into <a href="extref" title="...">string</a>
#              by looking up "word" in SQL and generating a new-window href with tinyglob
#              uses hostname, username, database, password tokens from symtb to find sql
#              looks in extreftable's extrefkeycol and replaces with extrefvalcol
#       {@ htmlfile string@}  into <a href="htmlfile" title="description">string</a>
#              by looking up "htmlfile" in SQL and generating an href
#              uses hostname, username, database, password tokens from symtb to find sql
#              looks in loclinktable's loclinkkeycol and replaces with link to the htmlfile decorated with the description
#              special hack if the htmlfile begins with minus: link to the "nextstory"
#
#  'glossbase' is defined in symtb and contains "mg"
#  'peoplefile' is defined in symtb and contains "multicians.html"
#  'mxrelative' is the location of Multics files, either "" or sometimes "../"
#  'bracketcolonclass' 'bracketequalclass' 'bracketplusclass'  and 'bracketminusclass' are defined in symtb
#  SQL lookup assumes that 'tinyglob' and 'newwindow' are defined in config as well as the DB params
#
sub expandMulticsBody {
    my $d = shift;		# the template being expanded.  a whole file.
    my $symtbptr = shift;

    return $d if index($d, '{') == -1; # if the string does not need attention, be fast.

    my $hostname = $$symtbptr{'hostname'};
    return $d if $hostname eq ''; # do nothing if there is no database

    my $bcc = &gvalue('bracketcolonclass', $symtbptr);
    my $bec = &gvalue('bracketequalclass', $symtbptr);
    my $bpc = &gvalue('bracketplusclass', $symtbptr);
    my $bmc = &gvalue('bracketminusclass', $symtbptr);
    
    # do these first, since some of the DB expansions may surround SPAN shortcuts .. otherwise it fucks up
    # change {:xxx:} to surround it with "bracketcolonclass"
    $d =~ s/([^\\])\{:([^}]+):\}/$1\<span class=\"$bcc\"\>$2\<\/span\>/g; # TEST
    # change {=xxx=} to surround it with "bracketequalclass"
    $d =~ s/\{=([^}]+)=\}/\<span class=\"$bec\"\>$1\<\/span\>/g;
    # change {+xxx+} to surround it with "bracketplusclass"
    $d =~ s/\{\+([^}]+)\+\}/\<span class=\"$bpc\"\>$1\<\/span\>/g;
    # change {+xxx+} to surround it with "bracketminusclass"
    $d =~ s/\{-([^}]+)-\}/\<span class=\"$bmc\"\>$1\<\/span\>/g;

    # change {[tag string]} to a link into peoplefile with a TITLE attribute derived from "did"
    while ($d =~ /\{\[(\S+) ([^}]+)\]\}/) {
        my $key = $1;
	# warn "key = '$key'";
	if ($key ne "") {
	    my $did;
	    my @cols = (&gvalue('multiciansvalcol', $symtbptr));
	    ($did) = &lookupSQL($key,  &gvalue('multicianstable', $symtbptr),  &gvalue('multicianskeycol', $symtbptr), "", \@cols, $symtbptr);
	    $did = &cleanRef($did);
	    my $mxr = &gvalue('mxrelative', $symtbptr);
	    my $pfi = &gvalue('peoplefile', $symtbptr);
	    $d =~ s/\{\[(\S+) ([^}]+)\]\}/\<a href=\"$mxr$pfi.html\#$1\" title=\"Multician: $did\"\>$2\<\/a\>/;
	}
    } # while

    # change {*string*} to a link into source -- does not currently work
    while ($d =~ /\{\*(\S*)\*\}/) {
        my $key = $1;
	my $root = &gvalue('multicssourceroot', $symtbptr); # a CGI that looks up the source loc and redirects
	$d =~ s/\{\*(\S*)\*\}/\<a href=\"$root?$key\" title=\"Multics source file $key\" class=\"sourceref\" target=\"_blank\"\>$key\<\/a\>/;
    } # while

    # change {{word string}} to a local link into correct glossary file with a TITLE ref that is first 9 words of definition
    while ($d =~ /\{\{(\S)(\S*) ([^}]+)\}\}/) {
        my $letter = $1;
	my $key = "$1$2";
	$letter =~ tr/A-Z/a-z/;
	$letter = 'a' if !($letter =~ /[a-z]/);
	my $def;
	my $title;
	my $gvc = &gvalue('glossvalcol', $symtbptr);
	my $gtb = &gvalue('glosstable', $symtbptr);
	my $gkc = &gvalue('glosskeycol', $symtbptr);
	my $gbs = &gvalue('glossbase', $symtbptr);
	my $mxr = &gvalue('mxrelative', $symtbptr);
	my @cols = ($gvc);
	($def) = &lookupSQL($key, $gtb, $gkc, " AND glossary.ord = 1", \@cols, $symtbptr);
	$title = &getFirstSentence($def);
	$d =~ s/\{\{(\S)(\S*) ([^}]+)\}\}/\<a href=\"$mxr$gbs$letter.html\#$1$2\" title=\"glossary: $title\"\>$3\<\/a\>/;
    } # while

    # change {!word string!} to an external link (in a new window) looked up in SQL
    while ($d =~ /\{!(\S+) ([^}]+)!\}/) {
        my $key = $1;
        my $ref = $2;
	my $target;
	my $etitle;
	my $j;
	my $evc = &gvalue('extrefvalcol', $symtbptr);
	my $ekc = &gvalue('extrefkeycol', $symtbptr);
	my $ert = &gvalue('extreftable', $symtbptr);
	my $inw = &gvalue('innewwindow', $symtbptr); # ='new window:'
	my $nwx = &gvalue('newwindow', $symtbptr);   # ='target="_blank"'
	my $tyg = &gvalue('tinyglob', $symtbptr);   # ="<img src=\"mulimg/tinyglob.gif\" alt=\"\" width=\"12\" height=\"11\" border=\"0\" style=\"display: inline;\">"
	my @cols = ($evc, 'title');
        ($target, $etitle) = &lookupSQL($key, $ert, $ekc, "", \@cols, $symtbptr);
	if ($ref eq '=') {	# some links display the looked up value as well
	    $ref = $target;
	    if (substr($ref,0,1) eq '!') { # if not putting glob and newwindow 
		$ref = substr($ref, 1);
	    }
	}
	$etitle =~ s/\"//g;	# no quotes in title
	$etitle = $inw . ' ' . $etitle;
	my $char = substr($target, 0, 1);
	if ($char eq '?') {     # if value begins with ? then dead link, no hotlink
	    $d =~ s/\{!(\S+) ([^}]+)!\}/\<span class=\"deadlink\" title=\"dead link\"\>$ref\<\/span\>/;
	} elsif ($char eq '!') { # if value in DB begins with ! then link but no new window or globe
	    $target = substr($target, 1);
	    $d =~ s/\{!(\S+) ([^}]+)!\}/\<a href=\"$target\" title=\"$etitle\"\>$ref\<\/a\>/;
	} elsif ($ref =~ /^\<img/i) { # no globe if wrapping an IMG tag
	    $d =~ s/\{!(\S+) ([^}]+)!\}/\<a href=\"$target\" title=\"$etitle\"$nwx\>$ref\<\/a\>/;
	} elsif ($ref =~ /^\<span class=\"nb\"\>\<img/i) { # no globe if wrapping an IMG tag returned by the imgtag macro
	    $d =~ s/\{!(\S+) ([^}]+)!\}/\<a href=\"$target\" title=\"$etitle\"$nwx\>$ref\<\/a\>/;
	} else {		# Regular case, put external link with tiny globe
	    $d =~ s/\{!(\S+) ([^}]+)!\}/\<a href=\"$target\" title=\"$etitle\"$nwx\>\<span class=\"nb\"\>$tyg $ref\<\/span\>\<\/a\>/;
        }
    } # while

    # change {@filename string@} to a local link looked up in SQL table "pages" .. no new window
    while ($d =~ /\{@(\S+) ([^}]+)@\}/) {
        my $fn = $1;		# andre.html (will get value of mxrelative prefixed to it)
        my $ref = $2;		# Story about Andre
	my $kind;		# story
	my $author;		# Tom Van Vleck
	my $title;		# It Can Be Done
	my $desc;		# description
	my $next;		# sss.html
	my $j;
	my $fnx;		# filename for lookup
	my $nametail = '';	# name anchor
	my @cols;
	my $lkc = &gvalue('loclinkkeycol', $symtbptr);
	my $llt = &gvalue('loclinktable', $symtbptr);
	my $fll = &gvalue('fixlocallink', $symtbptr);
	my $mxr = &gvalue('mxrelative', $symtbptr);
	if (substr($fn, 0, 1) eq '-') {
	    $fn = substr($fn, 1); # special handling if filename begins with minus, means next file
	    @cols = ('nextstory');
	    ($next) = &lookupSQL($fn, $llt, $lkc, "", \@cols, $symtbptr);
	    $fn = $next;	# find next story
	}
	$fnx = $fn;
	if ($fnx =~ /^(.*)\?(.*)$/) { # don't look up search arg
	    $fnx = $1;		      # note that "fn" is used in the actual link though
	}
	if ($fnx =~ /^(.*)#(.*)$/) { # don't look up anchor name
	    $fnx = $1;
	    $nametail = ': ' . $2;
	}
	@cols = ('kind', 'author', 'title', 'description'); # search the pages table
        ($kind, $author, $title, $desc) = &lookupSQL($fnx, $llt, $lkc, "", \@cols, $symtbptr);
	if ($title ne '') {
	    $title = "$kind: $title" if $kind ne '';
	    $title = "$title by $author" if $author ne '' && $author ne '-';
	    #$title = "$title ($desc)" if $desc ne '';
	    $title = "$desc" if $desc ne '';
	    #$title .= $nametail; # so you can tell links apart
	    $title =~ s/\"//g;	# Because of Olin's story with quotes in title, yuk
	    $title = " title=\"$title\"";
	#} else {
	#    $title = " title=\"$fnx not found\"";
	}
	$fn = $mxr . $fn; # mxrelative is needed if in a subdirectory
	#$fn =~ s'^\.\./thvv/'';	# hack to eliminate up-and-back-down .. removed
	#eval "\$fn =~ $fll" if $fll ne ''; # whatever this was, nobody uses it now
	$d =~ s/\{@(\S*) ([^}]+)@\}/\<a href=\"$fn\"$title\>$ref\<\/a\>/;
    } # while

    # do these again, since some of the DB expansions may return SPAN shortcuts
    # change {:xxx:} to surround it with "bracketcolonclass"
    $d =~ s/([^\\])\{:([^}]+):\}/$1\<span class=\"$bcc\"\>$2\<\/span\>/g; # TEST
    # change {=xxx=} to surround it with "bracketequalclass"
    $d =~ s/\{=([^}]+)=\}/\<span class=\"$bec\"\>$1\<\/span\>/g;
    # change {+xxx+} to surround it with "bracketplusclass"
    $d =~ s/\{\+([^}]+)\+\}/\<span class=\"$bpc\"\>$1\<\/span\>/g;
    # change {+xxx+} to surround it with "bracketminusclass"
    $d =~ s/\{-([^}]+)-\}/\<span class=\"$bmc\"\>$1\<\/span\>/g;
    
    return $d;

} # expandMulticsBody

# ----------------------------------------------------------------
# [not exported]
# SQL lookup function called from expandMulticsBody .. looks in the database for various expansions
#   ($val1, $val2, $val3 ...) = &lookupSQL($key, $table, $keycol, $selectcond, \@collist, \%values)
#
# uses these fields from config
#  'hostname'        "localhost"
#  'database'        "thvv_userlist"
#  'username'        "root"
#  'password'        "whatever"
#  'extreftable'     "extref"
#  'extrefkeycol'    "extname"
#
# if extreftable.extrefkeycol has more than one row containing $field, take first one
# return a list of column values.
# If there are database errors, print a warning and return "###" plus the key being looked up.
#
sub lookupSQL {
    my $x = shift;
    my $extreftable = shift;
    my $extrefkeycol = shift;
    my $selectcond = shift;
    my $colsptr = shift;
    my $symtbptr = shift;
    my $hostname = $$symtbptr{'hostname'};
    my $database = $$symtbptr{'database'};
    my $username = $$symtbptr{'username'};
    my $password = $$symtbptr{'password'};
    my $i;
    my $onecol;
    my $onekey;
    my $oneval= '###' . $x;
    my @answer = ($oneval);
    my $db;
    my $sth;
    my $em;			# error message
    if (($hostname eq '') || ($database eq '') || ($username eq '') || ($password eq '') || ($extreftable eq '') || ($extrefkeycol eq '')) {
	warn "database parameters not set: key=$x database=$database hostname=$hostname username=$username (password) extreftable=$extreftable extrefkeycol=$extrefkeycol\n";
	exit 1;
    }
    my $query = "SELECT * FROM $extreftable WHERE $extrefkeycol = '$x'$selectcond";
    if (!($db = DBI->connect("DBI:mysql:$database:$hostname", $username, $password))) {
	# prints a complaint on stdout whether i want it or not
	my $tries = 1;
	my $maxtries = 10; 	# see if database comes back in 10 minutes
	while ($tries < $maxtries) {
	    sleep 60;
	    if (($db = DBI->connect("DBI:mysql:$database:$hostname", $username, $password))) {
		last;		# success on a retry
	    }
	    $tries++;
	} # while
	if ($tries >= $maxtries) {
	    warn "cannot open DBI:mysql:$database:$hostname $username for query $query\n";
	    exit 1;
	}
    } elsif (!($sth = $db->prepare($query))) {
	$em = $db->errstr;
	$db->disconnect;
	warn "cannot prepare query $query $em\n";
	exit 1;
    } elsif (!$sth->execute) {
	$em = $db->errstr;
	$db->disconnect;
	warn "cannot execute query $query $em\n";
	exit 1;
    } else {			# ok
	my $numrows = $sth->rows;
	if ($numrows == 0) {
	   warn "warning: 0 rows for $query\n"; # nonfatal
	} else {	# rows
	    @answer = ();
	    $oneval = '';
	    my @array = $sth->fetchrow_array; # first row returned by query.
	    my @labels = @{$sth->{NAME}}; # get column names.
	    while ($onecol = shift @$colsptr) {
		for ($i=0;  $i<@labels; $i++) {
		    if ($labels[$i] eq $onecol) {
			$oneval = $array[$i];
		    }
		} # for
		#$oneval = "!!!$onecol" if $oneval eq '';
		push @answer, $oneval;
	    } # while
	} # rows
    } # ok
    $sth->finish if defined($sth);
    $db->disconnect if defined($db);
    return @answer;

} # lookupSQL

# ----------------------------------------------------------------
# [not exported]
#   $s = cleanRef($s);
# Remove links and Multics link formatting extensions.  called from &expandMulticsBody()
# Used to create title attributes.
sub cleanRef {
    my $d = shift;
    $d =~ s/\<[^>]+\>//g;	# remove HTML tags
    $d =~ s/\{:([^}]+):}/$1/g;
    $d =~ s/\{\+([^}]+)\+}/$1/g;
    $d =~ s/\{=([^}]+)=}/$1/g;
    $d =~ s/%\[[^]]+\]%//g;	# remove var expansions
    # remove linkages
    $d =~ s/\{\[(\S*) ([^}]+)\]}/$2/g; # take special language and reduce it
    $d =~ s/\{\*(\S*) ([^}]+)\*}/$2/g;
    $d =~ s/\{!(\S*) ([^}]+)!}/$2/g;
    $d =~ s/\{@(\S*) ([^}]+)@}/$2/g;
    $d =~ s/\{\{(\S)(\S*) ([^}]+)}}/$3/g;
    # since this goes in a quoted string, escape the quotes
    $d =~ s/"/\&quot;/g;
    return $d;
} # CleanRef

# ----------------------------------------------------------------
# [not exported]
# generate a short summrary of a definition for Multics title attribute of a glossary link.
# called from &expandMulticsBody()
#  $string = &getFirstSentence($text);
sub getFirstSentence {
    my $d = shift;
    $d = &cleanRef($d);
    # summary is the first nine words
    if ($d =~ /^ *([^ ]+) +([^ ]+) +([^ ]+) +([^ ]+) +([^ ]+) +([^ ]+) +([^ ]+) +([^ ]+) +([^ ]+)/) {
	$d = "$1 $2 $3 $4 $5 $6 $7 $8 $9";
	#$d =~ s/\..*$/./;	# .. or first sentence if shorter
	$d .= '...';
    } elsif ($d =~ /^([^.]*)\./) { # if fewer than nine words, take all
	$d = "$1...";
    } else {
	# leave as is
    }
    return $d;
} # getFirstSentence

# end
