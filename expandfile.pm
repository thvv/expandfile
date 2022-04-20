#!/usr/local/bin/perl
# Functions for HTML template expansion.
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
# 07/31/20 THVV 5.0 Make Multics expansions optional, depending on '_xf_expand_multics' switch which can be '', 'nosql', or 'all', add getter(), setter(), catter()
# 09/03/20 THVV 5.1 Add tracing tag to &validvarname, internal check on pointers, empty macro and query warnings, remove pre|post and firstnonempty
# 09/03/20 THVV 5.2 Allow multiple args to *set and *concat, concatenate them with no separator
# 03/17/21 THVV 5.21 make *bindcsv warn and return if input file is missing
# 04/09/21 THVV 5.3 Allow multiple args to *shell, *fwrite, *fappend, and *htmlescape, concatenate them with no separator
# 04/11/21 THVV 5.3 do not let *bindcsv set vars beginning with _ or . for security 
# 04/12/21 THVV 5.3 remove debugging code for old comma and vbar syntax. Expanding %[x,y,z]% will look for a var "x,y,z". Expanding %[x|<|>]% will get an error.
# 06/22/21 THVV 5.31 Mark the place where sqlite would be inserted, but comment it out, does not work.

# Copyright (c) 2003-2021 Tom Van Vleck
 
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

package expandfile;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(expandstring expandblocks expandMulticsBody getter setter catter);

use LWP::Simple;
use Term::ANSIColor;

# ================================================================
# packages used by expandfile

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
# This function should be called on the result of &expandblocks(), ie call expandblocks first.
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
    my $c;			# current char

    my $argptrcheck = ref $symtbptr;
    die "badcall" if $argptrcheck !~ /HASH/;

    $$symtbptr{'pct'} = '%';	# used for double expansion, set every time
    $$symtbptr{'lbkt'} = '[';
    $$symtbptr{'rbkt'} = ']';
    $$symtbptr{'quote'} = '"';    
    $$symtbptr{'lbrace'} = '{';
    $$symtbptr{'rbrace'} = '}';
    $$symtbptr{'_xf_ssvsep'} = ' ' if &getter($symtbptr, '_xf_ssvsep') eq ""; #never useful to have this undefined
    $$symtbptr{'me'} = 'expandfile' if $$symtbptr{'me'} eq ''; # for error messages
       
    while ($i < $n) {
	$c = substr($s, $i, 1);
	if ($c eq '\\') {	# Always treat backslash as escape.
	    $o .= substr($s, $i+1, 1); # Copy escaped char without looking.
	    $i++;
	} elsif (($state == 1) && ($c eq "\"")) { # Inside brackets, look for open quote.
	    $state = 2;		# Start of quoted string: don't copy the quote.
	    $peek = substr($s, $i-10, 11); # Save the start of the quoted string for error msg.
	} elsif (($state == 2) && ($c eq "\"")) { # Inside quotes, look for close.
	    $state = 1;		# End of quoted string: don't copy the quote.
	} elsif (($state == 1) && ($c eq ",")) {  # Inside brackets, look for comma.
	    #warn "trace push $o\n"; ## DEBUG
	    push @args, $o;	# Comma ends this argument.
	    $o = '';
	} elsif (($state == 1) && (substr($s, $i, 2) eq "]%")) { # inside brackets, look for end of evaluation
	    #warn "trace ket push $o\n"; ## DEBUG
	    #warn "   stack  @stack\n";
	    #warn "   args   @args\n";
	    #warn "   svargs @svargs\n";
	    push @args, $o;	# Save last argument.
	    $o = pop @stack;	# Restore the saved string from before evaluation started.
	    #warn "trace popped $o, args @args\n"; ## DEBUG
	    $level --;          # Decrease bracket nesting level.
	    $state = 0 if $level == 0;
	    $charbefore = substr($o, -1, 1) if $o ne '' && $level == 0; # Peek at the output so far.
	    $v = &getv($symtbptr, @args); # Call getv() to evaluate args.. either a variable value or a builtin function.
	    #warn "trace getv @args returned '$v'\n"; ## DEBUG
	    $o .= $v;		# Add the result of evaluation to the output or arg being built.
	    $nargs = pop @svargs; # Restore the arg count.
	    @args = ();
	    while ($nargs-- > 0) { # Restore the old saved args.
		my $onearg = pop @svargs;
		unshift @args, $onearg;
	    }
	    #warn "trace restored args to @args\n"; ## DEBUG
	    $i++ if (substr($s, $i+2, 1) eq "\n") && ($charbefore eq "\n"); # If a whole input line is %[...]%, do not generate an empty line.
	    $i++;		# 2-char item
	} elsif (($state != 2) && (substr($s, $i, 2) eq "%[")) { # Not inside quotes, look for open pct-bracket
	    #warn "trace bra\n"; ## DEBUG
	    #warn "   stack  @stack\n";
	    #warn "   args   @args\n";
	    #warn "   svargs @svargs\n";
	    push @stack, $o;	# Save what we were working on.
	    $o = '';		# Work on a new string.
	    push @svargs, @args; # Save the args.
	    $nargs = @args;	# Save arg count.
	    push @svargs, $nargs;
	    @args = ();		# Empty the argstack.
	    $state = 1;		# We're inside %[ ]%
	    $level++;		# Increase bracket nesting depth.
	    $i++;		# 2-char item.
	} else {		# ($state == 0) Plain character, copy it. Quotes are not special.
	    $o .= $c;		# Regular character, ravel onto the output.
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

    my $argptrcheck = ref $symtbptr;
    die "badcall" if $argptrcheck !~ /HASH/;
        
    my $outval = '';		# the template without blocks
    my $itx = -1;		# itx is the cursor
    my $oitx = 0;
    my $state = 0;		# 0=normal chars, 1=inside a block
    my $line;
    my $blockname;
    my $tailrexp;
    my $oldfunc = &getter($symtbptr, '_xf_currentfunction');
    &setter($symtbptr, '_xf_currentfunction', 'expandblocks');
#my $x = substr($tpt,0,50);
#warn "trace expandblocks $x\n";
    while (($itx = index($tpt, "\n", $oitx)) > -1) {
	$line = substr($tpt, $oitx, $itx-$oitx+1);
	if ($state == 1) {	# accumulating a block
	    if ($line =~ /$tailrexp/) {
		$state = 0;	# found end
	    } else {
		&catter($symtbptr, $blockname, $line);
	    }
	} else {		# not in a block
	    if ($line =~ /^%\[\*block,&?(\S+),([^]]+)\]%$/) {
		$blockname = $1; # remember block
		$tailrexp = $2;
		&validvarname($symtbptr, $blockname, "expandblocks"); # ensure it is valid
		&errmsg($symtbptr, 0, "trace: binding block $blockname") if (&getter($symtbptr,'_xf_tracebind') ne '');
		$state = 1;
	    } else {		# regular case
		$outval .= $line;
	    }
	}
	$oitx = $itx+1;
    } # while
    if ($state == 1) {		# missing tail rexp
	&catter($symtbptr, $blockname, substr($tpt, $oitx));
	&errmsg($symtbptr, 1, "error: missing end of *block $blockname -- $tailrexp"); # should we exit?
    } else {
	$outval .= substr($tpt, $oitx); # copy rest of tpt if no NL
    }
    &setter($symtbptr, '_xf_currentfunction', $oldfunc);
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
#  %[*set,&var,val...]%       assigns concatenated vals to var, returns nothing
#    if a val begins with = it is a literal
#    else it is a variable name
#
#  %[*include,=filename]%     Return expanded contents of filename, processes *block
#  %[*includeraw,=filename]%  Return non-expanded contents of filename
#  %[*callv,val,v1,v2,...]%   Bind v1 to param1, etc, then expand val
#  %[*expand,val]%            Expand val, return expanded value
#  %[*expandv,&var,val]%      Expand val, assigns to var, return nothing
#  %[*concat,&var,val...]%    Append val to var, return nothing
#  %[*format,&var,fmt,a1,a2,a3,...]%   Use fmt as a format string, replace $1 $2 $3 etc, result in var, return nothing
#  %[*ncopies,&var,val,n]%    Append val to var n times, return nothing
#  %[*increment,&var,val]%    Add val to var, return nothing
#  %[*decrement,&var,val]%    Subtract val from var, return nothing
#  %[*product,&result,val1,val2]% Compute val1*val2, store in result, return nothing
#  %[*quotient,&result,val1,val2]% Compute int(val1/val2), store in result, return nothing
#  %[*quotientrounded,&result,val1,val2]% Compute int((val1+(val2/2))/val2), store in result, return nothing
#  %[*scale,&result,val1,val2,val3]% Compute int((val1*val3)/val2), store in result, return nothing
#  %[*popssv,&var,&ssv]%      Pop one value off ssv, put it in var, rewrite ssv, return nothing
#  %[*subst,&var,left,right]% Do var =~ s/left/right/ig, return nothing
#  %[*fread,&var,=filename]%  Read filename or URL into var
#  %[*fwrite,=filename,val...]%  Write val to filename, return nothing
#  %[*fappend,=filename,val...]% Append val to filename, return nothing
#  %[*urlfetch,&var,url]%     Read URL into var
#  %[*bindcsv,=csvfile]%      Read local or remote CSV file, row1 is vars, row2 is values
#  %[*if,op,v1,v2,rest]%      Perform "rest" if (v1 op v2) .. op may be "==" "!=" ">" "<" "=~" and "!~" (etc)
#  %[*dirloop,&outvar,iterator,=dirname,starrex]% List dirname, expand iterator once per entry matching starrex
#  %[*csvloop,&outvar,iterator,=csvfile]% Read CSV file, expand iterator once per row, output in outvar
#  %[*ssvloop,&outvar,iterator,sslist]% Expand iterator once per ssv item binding _ssvitem, output in outvar
#  %[*sqlloop,&outvar,iterator,query]% Run SQL query, expand iterator once per row, output in outvar
#  %[*xmlloop,&outvar,iterator,=xmlfile,path]% Expand iterator once per XML item, output in outvar
#  %[*onchange,var,command]%  Execute command when var changes
#  %[*onnochange,var,command]% Execute command if var does not change
#                             (put before onchange if using both)
#  %[*htmlescape,s...]%       Escape HTML constructs in s, returns value
#  %[*shell,&result,str...]%  Execute a shell command and put output (if any) in result
#  %[*dump]%                  Output entire symbol table
#  %[*exit,anything]%         Print error message on STDERR and call exit(0)
#  %[*warn,anything]%         Print message on STDERR and keep going
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
    my $argptrcheck = ref $symtbptr;
    die "badcall" if $argptrcheck !~ /HASH/;
        
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
	&setter($symtbptr, '_xf_currentfunction', $cmd);
	if ($cmd eq 'set') {	    # *set,&varname,val...
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    my $temp = '';
	    foreach $val (@_) {	# concatenate all args with no separator
		$temp .= &gvalue($val, $symtbptr); # get variable value or literal value
	    }
	    &setter($symtbptr, $varname, $temp); # *set symbol table
	    #&errmsg($symtbptr, 0, "trace: bound $varname = \"$temp\"") if &getter($symtbptr, '_xf_tracebind') ne ''; ## DEBUG
	} elsif ($cmd eq 'include') { # *include,=filename
	    $fn = &argshouldbeginwith($symtbptr, '=', shift); # **************** fix to gvalue later
	    &checkextraargs($symtbptr, @_);
	    return &insert_and_expand_file($fn, $symtbptr);
	} elsif ($cmd eq 'includeraw') { # *includeraw,=filename
	    $fn = &argshouldbeginwith($symtbptr, '=', shift); # **************** fix to gvalue later
	    &checkextraargs($symtbptr, @_);
	    return &insert_raw_file($fn, $symtbptr);
	} elsif ($cmd eq 'if') { # %[*if,lt,v1,v2,command...]%
	    my $temp = join(' ', @_);
	    $op = shift;
	    $v1 = shift;
	    $v2 = shift;
	    &errmsg($symtbptr,0,"warning: blank arg2 in '*if $temp'") if $v2 eq "";
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
	    return &expandstring(&expandMulticsBody($val, $symtbptr), $symtbptr); # optional Multics expansion
	} elsif ($cmd eq 'expandv') { # *expandv,&varname,val -- store expansion of val into varname
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $v0 = shift;
	    &checkextraargs($symtbptr, @_);
	    $val = &gvalue($v0, $symtbptr); # fetch value to expand
	    &setter($symtbptr, $varname, &expandstring(&expandMulticsBody($val, $symtbptr), $symtbptr)); # optional Multics expansion
	} elsif ($cmd eq 'concat') { # *concat,&varname,val... -- ravels val onto varname
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    my $v0 = '';
	    foreach $val (@_) {	# concatenate all args with no separator
		$v0 .= &gvalue($val, $symtbptr); # get variable value or literal value
	    }
	    &catter($symtbptr, $varname, $v0); # append to varname
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
	    &setter($symtbptr, $varname, $v0);
	} elsif ($cmd eq 'ncopies') { # *ncopies,&varname,val,n -- store n copies of val into varname
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $v0 = shift;
	    $v1 = shift;
	    &checkextraargs($symtbptr, @_);
	    $val = &gvalue($v0, $symtbptr);
	    $v2 = &gvalue($v1, $symtbptr);
	    &setter($symtbptr, $varname,  $val x $v2);
	} elsif ($cmd eq 'increment') { # *increment,&varname,val -- varname += val
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $v0 = shift;
	    &checkextraargs($symtbptr, @_);
	    $val = &gvalue($v0, $symtbptr);
	    &setter($symtbptr, $varname, &getter($symtbptr, $varname) + $val);
	} elsif ($cmd eq 'decrement') { # *decrement,&varname,val -- varname -= val
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $v0 = shift;
	    &checkextraargs($symtbptr, @_);
	    $val = &gvalue($v0, $symtbptr);
	    &setter($symtbptr, $varname, &getter($symtbptr, $varname) - $val);
	} elsif ($cmd eq 'product') { # *product,&varname,top,base -- store top*base into varname
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $v1 = shift;
	    $v2 = shift;
	    &checkextraargs($symtbptr, @_);
	    $val = &gvalue($v1, $symtbptr);
	    $v0 = &gvalue($v2, $symtbptr);
	    &setter($symtbptr, $varname, $val * $v0);
	} elsif ($cmd eq 'quotient') { # *quotient,&varname,top,base -- store int(top/base) into varname
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $v1 = shift;
	    $v2 = shift;
	    &checkextraargs($symtbptr, @_);
	    $val = &gvalue($v1, $symtbptr);
	    $v0 = &gvalue($v2, $symtbptr);
	    if (($v0+0) == 0) {
		&setter($symtbptr, $varname, 0); # divide by 0
	    } else {
		&setter($symtbptr, $varname, int($val / $v0));
	    }
	} elsif ($cmd eq 'quotientrounded') { # *quotientrounded,&result,val1,val2 store int((val1/val2)+0.5) into varname
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $v1 = shift;
	    $v2 = shift;
	    &checkextraargs($symtbptr, @_);
	    $val = &gvalue($v1, $symtbptr);
	    $v0 = &gvalue($v2, $symtbptr);
	    if (($v0+0) == 0) {
		&setter($symtbptr, $varname, 0); # divide by 0
	    } else {
		&setter($symtbptr, $varname, int(($val / $v0) + 0.5));
	    }
	} elsif ($cmd eq 'scale') { # *scale,&varname,val,range,base -- store int(((val*base)/range)+0.5) into varname
	    # for example, *scale,&ans,observedvar,biggestvalue,containersize
	    # or *scale,&percent,observed,max,=100
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $v1 = shift; # val
	    $v2 = shift; # maxval
	    $v3 = shift; # containersize
	    &checkextraargs($symtbptr, @_);
	    $val = &gvalue($v1, $symtbptr); # value to be scaled
	    $val = 0 if $val eq ""; # avoid -w errors
	    $v0 = &gvalue($v2, $symtbptr); # max value observed
	    $v0 = 0 if $v0 eq ""; # avoid -w errors
	    $v3 = &gvalue($v3, $symtbptr); # max scaled value, container size
	    $v3 = 0 if $v3 eq ""; # avoid -w errors
	    if (($v0+0) == 0) {
		&setter($symtbptr, $varname, 0); # divide by 0
	    } else {
		&setter($symtbptr, $varname, int((($val * $v3) / $v0) + 0.5));
	    }
	} elsif ($cmd eq 'popssv') { # *popssv,&varname,&ssvvar -- pop one item off ssvvar into varname
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $v0 = &argshouldbeginwith($symtbptr, '&', shift); # literal not allowed, cause we rewrite it
	    &checkextraargs($symtbptr, @_);
	    $val = &getter($symtbptr, $v0); # get the old SSV value
	    &setter($symtbptr, '_xf_ssvsep', ' ') if &getter($symtbptr, '_xf_ssvsep') eq "";
	    $v1 = index($val, &getter($symtbptr, '_xf_ssvsep')); # look for the first item on the SSV
	    if ($v1 == -1) {
		&setter($symtbptr, $varname, $val);  # no separator found, return what we got
		&setter($symtbptr, $v0, "");
	    } else {
		&setter($symtbptr, $varname, substr($val, 0, $v1));  # pop off the head of the SSV
		&setter($symtbptr, $v0, substr($val, $v1+1)); # rewrite the SSV with the tail
	    }
	} elsif ($cmd eq 'subst') { # *subst,&varname,left,right -- regexp substitution applied to varname
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $pre = shift;
	    $v1 = &gvalue($pre, $symtbptr);
	    $post = join ',', @_; # take all remaing args .. wonder why i do this
	    $v2 = &gvalue($post, $symtbptr);
	    # sanitize v1 and v2, which must not contain '/' .. backtick seems to be ok
	    $v3 = &getter($symtbptr, $varname); # get old value in case eval fails
	    $v0 = "\$v3 =~ s/$v1/$v2/ig";
	    eval($v0);		# run this on sanitized arguments only
	    &setter($symtbptr, $varname, $v3);
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
	    &setter($symtbptr, $varname, $content);
	} elsif ($cmd eq 'urlfetch') { # *urlfetch,&varname,=url
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    $filen = &argshouldbeginwith($symtbptr, '=', shift); # **************** fix to gvalue later
	    &checkextraargs($symtbptr, @_);
	    my $content = LWP::Simple::get $filen;
	    $content = '' if !defined($content); # if not found, set varname empty
	    &setter($symtbptr, $varname, $content); # ugh: this value ends in a newline.
	} elsif ($cmd eq 'bindcsv') { # *bindcsv,=url_or_filename
	    $filen = &argshouldbeginwith($symtbptr, '=', shift); # **************** fix to gvalue later
	    &checkextraargs($symtbptr, @_);
	    &bindCSV($filen, $symtbptr);
	} elsif ($cmd eq 'fwrite') { # *fwrite,filename,varname...
	    $filen = &argshouldbeginwith($symtbptr, '=', shift); # **************** fix to gvalue later
	    my $v0 = '';
	    foreach $val (@_) {	# concatenate all args into the command with no separator
		$v0 .= &gvalue($val, $symtbptr); # get variable value or literal value
	    }
	    if (!open(++$incl, ">$filen")) {
		&errmsg($symtbptr, 1, "error: cannot *fwrite '$filen' $!");
	    } else {
		print $incl "$v0\n";
		close $incl;
	    }
	} elsif ($cmd eq 'fappend') { # *fappend,filename,varname...
	    $filen = &argshouldbeginwith($symtbptr, '=', shift); # **************** fix to gvalue later
	    my $v0 = '';
	    foreach $val (@_) {	# concatenate all args into the command with no separator
		$v0 .= &gvalue($val, $symtbptr); # get variable value or literal value
	    }
	    if (!open(++$incl, ">>$filen")) {
		&errmsg($symtbptr, 1, "error: cannot *fappend '$filen' $!");
	    } else {
		print $incl "$v0\n";
		close $incl;
	    }
	} elsif ($cmd eq 'shell') { # *shell,&varname,command...
	    $varname = &argshouldbeginwith($symtbptr, '&', shift);
	    my $v0 = '';
	    foreach $val (@_) {	# concatenate all args into the command with no separator
		$v0 .= &gvalue($val, $symtbptr); # get variable value or literal value
	    }
	    &setter($symtbptr, $varname, &execute_command($v0, $symtbptr));
	} elsif ($cmd eq 'callv') { # *callv,varname -- set up args and expand a var
	    $v0 = shift;	    # get the template name
	    $val = &gvalue($v0, $symtbptr); # get template value (macro name)
	    #warn "trace *callv,$v0,@_\n";
	    if ($val ne "") {
		my $prevfilename = &getter($symtbptr, '_xf_currentfilename');
		&catter($symtbptr, '_xf_currentfilename', '>' . $v0);
		# if a function peeks at its args, it might see leftover args from a previous callv
		$i = 1;
		@savedparams = ();  # save the old values of paramX
		while (@_) {	    # save old params, bind given ones
		    $v1 = 'param'.$i++; # varname to bind
		    push @savedparams, &getter($symtbptr, $v1); # save old value
		    $v2 = shift; # new value to bind
		    #warn "trace *callv bind $v1 $v2\n";
		    &setter($symtbptr, $v1, &gvalue($v2, $symtbptr)); 
		}
		&setter($symtbptr, '_xf_n_callv_args', $i); # in case the macro needs to know how many args it got
		$v2 = &expandstring(&expandMulticsBody($val, $symtbptr), $symtbptr); # recurse optional Multics expansion, output in v2
		$i = 1;
		while (@savedparams) { # restore params to prior value
		    $v1 = 'param'.$i++;
		    &setter($symtbptr, $v1, shift @savedparams);
		}
		&setter($symtbptr, '_xf_currentfilename', $prevfilename); # pop filename
	    }else {
		&errmsg($symtbptr, 0, "warning: empty *callv macro $v0");
		$v2 = '';	# return nothing
	    }
	    return '' if $v2 eq "\n";
	    return $v2;
	} elsif ($cmd eq 'dirloop') { # *dirloop,iterator,dirname,namerexp
	    # The problem with this one is that you can't select "no symlinks" etc.??
	    $varname = &argshouldbeginwith($symtbptr, '&', shift); # outvar
	    $v1 = shift;	# iterator
	    $v2 = shift;	# dirname
	    $v3 = shift;	# name regexp
	    &checkextraargs($symtbptr, @_);
	    &setter($symtbptr, $varname, &iterateDir(&gvalue($v1, $symtbptr), &gvalue($v2, $symtbptr), &gvalue($v3, $symtbptr), $symtbptr));
	} elsif ($cmd eq 'csvloop') { # *csvloop,&varname,iteratorvar,csvfile -- loop over a CSV
	    $varname = &argshouldbeginwith($symtbptr, '&', shift); # outvar
	    $v1 = shift;	# iterator
	    $v2 = shift;	# csv file
	    &checkextraargs($symtbptr, @_);
	    &setter($symtbptr, '_xf_ssvsep', ' ') if &getter($symtbptr, '_xf_ssvsep') eq "";
	    &setter($symtbptr, $varname, &iterateCSV(&gvalue($v1, $symtbptr), &gvalue($v2, $symtbptr), $symtbptr));
	} elsif ($cmd eq 'ssvloop') { # *ssvloop,&varname,iteratorvar,ssvvar
	    $varname = &argshouldbeginwith($symtbptr, '&', shift); # outvar
	    $v1 = shift;	# iterator
	    $v2 = shift;	# ssv
	    &checkextraargs($symtbptr, @_);
	    &setter($symtbptr, '_xf_ssvsep', ' ') if &getter($symtbptr, '_xf_ssvsep') eq "";
	    &setter($symtbptr, $varname, &iterateSSV(&gvalue($v1, $symtbptr), &gvalue($v2, $symtbptr), $symtbptr));

	# ----------------------------------------------------------------
	# --- external guts in readbindsql.pm
	} elsif ($cmd eq 'sqlloop') { # *sqlloop,&varname,iteratorvar,query
	    $varname = &argshouldbeginwith($symtbptr, '&', shift); # outvar
	    $v1 = shift;	# iterator
	    $v2 = join ',', @_; # take all remaing args for query, commas are allowed
	    if ($v2 eq '') {
		&errmsg($symtbptr, 0, "warning: empty *sqlloop query");
		&setter($symtbptr, '_xf_nrows', 0);
		&setter($symtbptr, '_xf_colnames', '');
	    } else {
		&setter($symtbptr, $varname, &iterateSQL(&gvalue($v1, $symtbptr), &gvalue($v2, $symtbptr), $symtbptr));
	    }
	# --- external guts in readbindxml.pm
	} elsif ($cmd eq 'xmlloop') { # *xmlloop,&varname,iteratorvar,xmlfile[,xpath] -- loop over a XML file
	    $varname = &argshouldbeginwith($symtbptr, '&', shift); # outvar
	    $v1 = shift;	# iterator
	    $v2 = shift;	# xml file
	    $v3 = shift;	# optional XPath
	    &checkextraargs($symtbptr, @_);
	    if (defined($v3)) {
		$v3 =  &gvalue($v3, $symtbptr); # xpatn
	    }
	    &setter($symtbptr, '_xf_ssvsep', ' ') if &getter($symtbptr, '_xf_ssvsep') eq ""; # if ssvsep is null, make it a space
	    &setter($symtbptr, $varname, &iterateXML(&gvalue($v1, $symtbptr), &gvalue($v2, $symtbptr), $symtbptr, $v3));
	# ----------------------------------------------------------------

	} elsif ($cmd eq 'onchange') { # *onchange,var,command -- useful in iterators
	    $v0 = shift;	       # var
	    $v1 = '_xf_old_'.$v0;
	    $v2 = &getter($symtbptr, $v0);
	    $v3 = &getter($symtbptr, $v1);
	    if ($v2 ne $v3) {
		&setter($symtbptr, $v1, &getter($symtbptr, $v0)); # set _xf_old_var to value of var
		return &getv($symtbptr, @_); # execute rest of args
	    } else {
		return '';	# return with unconsumed args
	    }
	} elsif ($cmd eq 'onnochange') { # *onnochange,var,command -- useful in iterators
	    # do this before "onchange" if doing both, else it fires too often
	    $v0 = shift; 
	    $v1 = '_xf_old_'.$v0;
	    $v2 = &getter($symtbptr, $v0);
	    $v3 = &getter($symtbptr, $v1);
	    if ($v2 eq $v3) {
		return &getv($symtbptr, @_); # recurse with rest of args
	    } else {
		return '';	# return with unconsumed args
	    }
	} elsif ($cmd eq 'exit') { # *exit -- should replace this with "*exec" cmd?
	    # Calling this function causes the calling program to abort with no output.
	    # This is pretty brutal.  Currently there is no way to say "simulate an EOF on your input."
	    &errmsg($symtbptr, 1, "error exit @_");
	} elsif ($cmd eq 'dump') { # *dump -- dump the symbol table onto stdout, good for debugging
	    return &dump_symtb($symtbptr);
	} elsif ($cmd eq 'warn') { # print message on STDERR and keep going
	    warn color("green")."@_".color("reset")."\n"; # user does not want expandfile in the message
	} elsif ($cmd eq 'htmlescape') { # *htmlescape,val... -- concat all args, return htmlescaped value
	    my $v0 = '';
	    foreach $val (@_) {	# concatenate all args into the command with no separator
		$v0 .= &gvalue($val, $symtbptr); # get variable value or literal value
	    }
	    return &htmlEscape($v0);
        } else {
	    &errmsg($symtbptr, 1, "error: unknown builtin *$cmd,@_"); # this is a fatal error, stop dead
	}
	return '';
    } # * is followed by a command name
    
# Didn't begin with a *command, so it is the variable name case, e.g. %[fred]%.  Look in symbol table or $ENV
    unshift @_, $cmd;	      # put the varname back on the arglist
    $varname = join(',', @_); # create a varname from all args, with the commas as chars, e.g. %[fred,jane]% (comma is legal in varname)
    $oldcurfunc = &getter($symtbptr, '_xf_currentfunction');
    &setter($symtbptr, '_xf_currentfunction', "eval '$varname'"); # set current function name to indicate evaluation
    &validvarname($symtbptr, $varname, "eval");   # .. complain if illegal chars in varname (comma ok, pipe and backtick not ok)
    $vgetv = &getter($symtbptr, $varname); # look it up and return its value
    &setter($symtbptr, '_xf_currentfunction', $oldcurfunc);
    return $vgetv;
} # getv

# ================================================================
# check if valid varname
#   &validvarname($symtbp, $vn, $trace);
sub validvarname {
    my $xp = shift;
    my $vn = shift;
    my $tt = shift;
#warn "trace: validvarname '$vn'\n";
    my $curfunc = &getter($xp, '_xf_currentfunction');
    if ($vn eq '') {		# usually indicates a syntax error in a builtin call, like using "" instead of =""
	# &errmsg($xp, 0, "warning: blank varname in *$curfunc $tt"); this is sometimes harmless
    } elsif ($vn !~ /^[-()\/.,;@+=&#_ 0-9a-zA-Z]+$/) { # sometimes we use a title as a varname (e.g. changes-old.htmx) .. if it has e.g. &#39; don't fuss
	&errmsg($xp, 0, "warning: invalid chars in varname '$vn' in *$curfunc $tt");
    }
    if  ($vn =~ /^[0-9]+$/) {
	&errmsg($xp, 0, "warning: all numeric varname '$vn' in *$curfunc $tt");
    }
#warn "trace validvarname returns\n";
} # validvarname

# ================================================================
# check if extra args, complain and die if so
#   &checkextraargs($symtbp, @_);
sub checkextraargs {
    my $xp = shift;
    my $ea = shift;
    return if !defined($ea);
    my $curfunc = &getter($xp, '_xf_currentfunction');
    unshift @_, $ea;
    $ea = join(',', @_);
    &errmsg($xp, 1, "error: extra args '$ea' to *$curfunc");
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
	my $curfunc = &getter($xp, '_xf_currentfunction');
	&errmsg($xp, 0, "warning: '$fn' should begin with $ch in *$curfunc");
	# **************** make fatal later
    }
    return $fn if $ch eq '=';	# literal, can have invalid characters
    &validvarname($xp, $fn, "asbw");	# check that the trimmed varname is valid and fuss if bad chars in it
    return $fn;			# lvalue
} # argshouldbeginwith

# ================================================================
# [not exported]
# directory iteration function used by *dirloop
#   $val = &iterateDir($iterator, $dirname, $starname, \%values)
#
# Lists directory, matches starname, stats each file, binds values
# then expands iterator once per file and binds %[_xf_nrows]% to the number of files found
#
# if dirname is not found, does nothing, binds %[_xf_nrows]% to 0
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
	    &setter($symtbptr, '_xf_nrows', 0);
	    return '';
	}
	my(@allfiles) = sort grep !/^\./, readdir DH;
	closedir DH;

	foreach $f (@allfiles) {
	    if ($f =~ /$starx/) { # How can i select dirs/files/links??
		$nfiles++;
		&setter($symtbptr, 'file_name', $f);
		&setter($symtbptr, 'file_type', 'f');
		&setter($symtbptr, 'file_type', 'd') if -d $f;	# dir
		&setter($symtbptr, 'file_type', 'l') if -l $f; # symlink
		&setter($symtbptr, 'file_type', 'p') if -p $f; # pipe
		&setter($symtbptr, 'file_type', 's') if -S $f; # socket

		my $stat_dev;     # device number of fs
		my $stat_ino;     # inode number
		my $stat_rawmode; # file mode, needs conversion to rwx
		my $stat_nlink;   # number of hardlinks
		my $stat_uid;     # uid of file owner
		my $stat_gid;     # gid of file owner
		my $stat_rdev;    # device ID for special files
		my $stat_size;    # size in bytes
		my $stat_atime;   # access time
		my $stat_mtime;   # modification time (used below)
		my $stat_ctime;   # inode change time
		my $stat_blksize; # preferred block size
		my $stat_blocks;  # actual 512-byte blocks allocated
		my $localtime_sec;
		my $localtime_min;
		my $localtime_hour;
		my $localtime_mday;
		my $localtime_mon;
		my $localtime_year;
		my $localtime_wday;
		my $localtime_yday;
		my $localtime_isdst;  # 1 if DST, 0 if not, -1 if unknown
		
		($stat_dev, $stat_ino, $stat_rawmode, $stat_nlink, $stat_uid, $stat_gid, $stat_rdev, $stat_size, $stat_atime, $stat_mtime, $stat_ctime, $stat_blksize, $stat_blocks) = stat("$dn/$f");
		($localtime_sec,
		 $localtime_min,
		 $localtime_hour,
		 $localtime_mday,
		 $localtime_mon,
		 $localtime_year,
		 $localtime_wday,
		 $localtime_yday,
		 $localtime_isdst) = localtime($stat_mtime);

		$localtime_year -= 100 if $localtime_year >= 100; # show 2005 as 05
		$localtime_year = &twodigit($localtime_year);
		$localtime_mday = &twodigit($localtime_mday);
		$localtime_mon = &twodigit($localtime_mon+1);
		$localtime_hour = &twodigit($localtime_hour);
		$localtime_min = &twodigit($localtime_min);
		$localtime_sec = &twodigit($localtime_sec);
		
		my $file_datemod = "$localtime_mon/$localtime_mday/$localtime_year $localtime_hour:$localtime_min";
		my $file_modshort = "$localtime_mon/$localtime_mday/$localtime_year";
		my $file_sizek = int(($stat_size+1023)/1024);
		my $file_age = int((time - $stat_mtime)/86400);
		
		&setter($symtbptr, 'file_dev', $stat_dev);
		&setter($symtbptr, 'file_ino', $stat_ino);
		&setter($symtbptr, 'file_mode', &rwxmode($stat_rawmode));
		&setter($symtbptr, 'file_nlink', $stat_nlink);
		&setter($symtbptr, 'file_uid', $stat_uid);
		&setter($symtbptr, 'file_gid', $stat_gid);
		&setter($symtbptr, 'file_rdev', $stat_rdev);
		&setter($symtbptr, 'file_size', $stat_size);
		&setter($symtbptr, 'file_atime', $stat_atime);
		&setter($symtbptr, 'file_mtime', $stat_mtime);
		&setter($symtbptr, 'file_ctime', $stat_ctime);
		&setter($symtbptr, 'file_blksize', $stat_blksize);
		&setter($symtbptr, 'file_blocks', $stat_blocks);
		&setter($symtbptr, 'file_sec', $localtime_sec);
		&setter($symtbptr, 'file_min', $localtime_min);
		&setter($symtbptr, 'file_hour', $localtime_hour);
		&setter($symtbptr, 'file_mday', $localtime_mday);
		&setter($symtbptr, 'file_mon', $localtime_mon);
		&setter($symtbptr, 'file_year', $localtime_year);
		&setter($symtbptr, 'file_wday', $localtime_wday);
		&setter($symtbptr, 'file_yday', $localtime_yday);
		&setter($symtbptr, 'file_isdst', $localtime_isdst);
		&setter($symtbptr, 'file_datemod', $file_datemod);
		&setter($symtbptr, 'file_modshort', $file_modshort);
		&setter($symtbptr, 'file_sizek', $file_sizek);
		&setter($symtbptr, 'file_age', $file_age);

       		# for each dir entry, expand the iterator once with values bound to the file's attributes.
		$result .= &expandstring($iterator, $symtbptr);
	    } # if starname
	} # foreach $f
    } else { # not dir
	&errmsg($symtbptr, 0, "warning: '$dn' not a dir in *dirloop");
    }
    &setter($symtbptr, '_xf_nrows', $nfiles);
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
# Expands iterator once per element of the ssv, binding the element to %[_xf_ssvitem]%
# Does not destroy the ssv
# skips null entries in the ssv
# returns the concatenation of all expansions and sets %[_xf_nssv]% to the count
#
sub iterateSSV {
    my $iterator = shift;
    my $val = shift;
    my $symtbptr = shift;
    my $result = '';
    my $n = 0;
    my $more = 1;
    my $v1;
    &setter($symtbptr, '_xf_ssvsep', ' ') if &getter($symtbptr, '_xf_ssvsep') eq "";
    if ($val ne "") {
	while ($more) {
	    my $m;
	    $v1 = index($val, &getter($symtbptr, '_xf_ssvsep')); # find separator
	    if ($v1 == -1) {
		$m = $val; # no sep, take whole thing, maybe null
		$more = 0;
	    } else {
		$m = substr($val, 0, $v1); # peel off one item
		$val = substr($val, $v1+1); # rewrite the ssv with one less
	    }
	    &setter($symtbptr, '_xf_ssvitem', $m);
	    &errmsg($symtbptr, 0, "trace: bound _xf_ssvitem = $m") if &getter($symtbptr, '_xf_tracebind') ne '';
	    $result .= &expandstring($iterator, $symtbptr) if $m ne ''; # expand iterator and ravel result
	    $n++;
	}
    }
    &setter($symtbptr, '_xf_nssv', $n);
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
# binds %[_xf_nrows]% to the count of rows
# binds %[_xf_colnames]% to the column names
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
    my $colnames = join &getter($symtbptr, '_xf_ssvsep'), @labels;
    &setter($symtbptr, '_xf_colnames', $colnames); # bind list of column names for reflection
    &errmsg($symtbptr, 0, "trace: bound _xf_colnames = $colnames") if (&getter($symtbptr, '_xf_tracebind') ne ''); 
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
	    &setter($symtbptr, $tablecol, $v);
	    &errmsg($symtbptr, 0, "trace: bound $tablecol = $v") if (&getter($symtbptr, '_xf_tracebind') ne '');
	} # for
	if ($iterator ne '') {
	    $result .= &expandstring($iterator, $symtbptr);
	} # iterator nonblank
    } # while fetchrow
    close($fh);
    &setter($symtbptr, '_xf_nrows', $nrows); # Report results.
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
# binds %[_xf_colnames]% to the column names
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
	&errmsg($symtbptr, 0, "error: missing remote CSV file '$csvfile' in *bindcsv") if $content eq '';
    } else {			# not http, local file
	my $fh = $incl++;
	if ($csvfile =~ /\.gz$|\.z$/i) {
	    if (!open($fh, "gzcat $csvfile |")) {
		&errmsg($symtbptr, 0, "error: missing compressed CSV file '$csvfile' $! in *bindcsv");
	    }
	} else {
	    if (!open($fh, "$csvfile")) {
		&errmsg($symtbptr, 0, "error: missing CSV file '$csvfile' $! in *bindcsv");
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
    my $j = index($content, "\n"); # look for the NL delimiting the header line from the body line
    if ($j < 0) {
	&errmsg($symtbptr, 0, "error: no values in CSV file '$csvfile' in *bindcsv");
	return;
    }
    $line = substr($content, 0, $j); 
    @labels = &csvparse($line);
    $line = substr($content, $j+1); # rest of file should be one line of comma separated values
    chomp $line;		# trim trailing NL if any
    #warn "trace $line\n";
    &errmsg($symtbptr, 1, "error: malformed CSV file '$csvfile' in *bindcsv") if $line eq '' || index($line, "\n") >= 0; # if no values or too many
    &setter($symtbptr, '_xf_ssvsep', ' ') if &getter($symtbptr, '_xf_ssvsep') eq "";
    my $cols = join &getter($symtbptr, '_xf_ssvsep'), @labels;
    &setter($symtbptr, '_xf_colnames', $cols); # bind list of column names for reflection
    &errmsg($symtbptr, 0, "trace: bound $tablecol = $cols") if (&getter($symtbptr, '_xf_tracebind') ne '');
    @vals = &csvparse($line); # parse the row into an array of strings
    for ($i=0;  $i<@labels; $i++) {
	$tablecol = $labels[$i];
	$v = shift @vals;     # if there are too few values, this will be empty, so missing ones will be set to ""
	my $firstletter = substr($tablecol, 0, 1);
	if ($firstletter eq '_' || $firstletter eq '.') { # cannot set vars beginning with underscore or period
	    &errmsg($symtbptr, 0, "*bindcsv: invalid CSV column $tablecol ignored");
	} else {
	    &setter($symtbptr, $tablecol, $v);
	    &errmsg($symtbptr, 0, "trace: bound $tablecol = $v") if (&getter($symtbptr, '_xf_tracebind') ne '');
	}
    } # for
    return;
} # bindCSV

# ================================================================
# [not exported]
# Given a builtin argument reference, return a value.
#   $result = &gvalue($varname, \%symtb);
# -- Literals begin with = and will have \n expanded
# -- otherwise it's a variablename, look up in the symbol table and the ENV.  If not found, return empty string.
# XXX could put in a quoting convention here for punctuation (now i forget what i meant by this)
sub gvalue {
    my $x = shift;
    my $xptr = shift;
    my $v;

    my $argptrcheck = ref $xptr;
    die "badcall" if $argptrcheck !~ /HASH/;

    if ($x =~ /^=(.*)/) {	# literal
	$v = $1;
	$v =~ s/\\n/\n/g;	# change escaped NL to real
	return $v;
    }
    # not a special case, take symbol table or cmd envir
    &validvarname($xptr, $x, "gvalue");	# getting contents of a variable, e.g. %[*set,&x,y]%
    $v = &getter($xptr, $x);
    return $v if $v ne '';
    # if $x is all digits, probably forgot an equal sign
    &errmsg($xptr, 0, "warning: missing = before numeric argument '$x'") if $x =~ /^[0-9]+$/; # i do this sometimes, ,0 instead of ,=0
    # optionally alert if there is no value for the arg.. not a bug.. some code may count on this.
    &errmsg($xptr, 0, "warning: no value for argument '$x'") if &getter($xptr, '_xf_debug') ne '';
    return '';

} # gvalue

# ================================================================
# There are 41 special variables with names _xf_something

my %xf_keys = (
    # 3 are set by the user to control expandfile debugging and features
    expand_multics => 1, debug => 1, tracebind => 2,
    # 10 are set by expandfile as it runs
    currentfilename => 2, currentfunction => 2, colnames => 2, nrows => 2, nssv => 2, nxml => 1, xmlfields => 1, ssvitem => 2, ssvsep => 2, n_callv_args => 1,
    # 4 are set by the user to connect to MySQL
    hostname => 1, username => 1, password => 1, database => 1,
    # 24 are parameters set by the user used by Multics expansions
    bracketcolonclass => 1, bracketequalclass => 1, bracketminusclass => 1, bracketplusclass => 1,
    escape => 1, # (not used, probably could be deleted)
    extrefkeycol => 1, extreftable => 1, extrefvalcol => 1,
    fixlocallink => 1,   
    glossbase => 1, glosskeycol => 1, glosstable => 1, glossvalcol => 1, 
    loclinkkeycol => 1, loclinktable => 1,
    multicianskeycol => 1, multicianstable => 1, multiciansvalcol => 1, multicssourceroot => 1, mxrelative => 1,
    innewwindow => 1, newwindow => 1,
    peoplefile => 1,
    tinyglob => 1,
 );

# ================================================================
# [exported for use by readbindsql and readbindxml]
# $value = &getter(\%symtb, $varname);
sub getter {
    my $xptr = shift;		# symtb ptr
    my $x = shift;		# var name
    my $v = '';			# return value

    my $argptrcheck = ref $xptr; # safety check
    die "badcall" if $argptrcheck !~ /HASH/;

    if (defined($$xptr{$x})) {	  # check symtb
	$v = $$xptr{$x};	  # .. return its value
    } elsif (defined($ENV{$x})) { # check shell ENV (set by export command)
	$v = $ENV{$x};		  # .. return shell value
    } else {			  # don't have a value, fuss
	&errmsg($xptr, 0, "warning: Undefined val ref $x, returned empty") if $$xptr{'_xf_debug'} ne ''; # failed to find _xf_ version and no alternative
    }
    return $v;
} # getter

# ================================================================
# [exported for use by readbindsql and readbindxml]
# &setter(\%symtb, $varname, $value);
sub setter {
    my $xptr = shift;		# symtb ptr
    my $x = shift;		# var name
    my $v = shift;		# value to set

    my $argptrcheck = ref $xptr; # safety check
    die "badcall" if $argptrcheck !~ /HASH/;

#warn "trace calling setter $x $v\n";
    $$xptr{$x} = $v;		# set requested in symtb

    # check if setting X when _xf_X is defined, and fuss if debugging
    if (substr($x, 0, 4) ne '_xf_') {
	my $xhat = '_xf_' . $x;
	$xhat =~ s/__/_/;
	if (defined($$xptr{$xhat})) {
	    my $xhatv = $$xptr{$xhat};
	    &errmsg($xptr, 0, "trace: setting $x to $v when $xhat = '$xhatv'") if $$xptr{'_xf_debug'} ne '';
	}
    } # if substr
} # setter

# ================================================================
# [exported for use by readbindsql and readbindxml]
# &catter(\%symtb, $varname, $value);
sub catter {
    my $xptr = shift;
    my $x = shift;
    my $v = shift;

    my $argptrcheck = ref $xptr;
    die "badcall" if $argptrcheck !~ /HASH/;

#warn "trace calling catter $x $v\n";
    $$xptr{$x} .= $v;		# concat arg onto the value

    # check if setting X when _xf_X is defined, and fuss if debugging
    if (substr($x, 0, 4) ne '_xf_') {
	my $xhat = '_xf_' . $x;
	if (defined($$xptr{$xhat})) {
	    &errmsg($xptr, 0, "trace: setting $x when $xhat is defined") if $$xptr{'_xf_debug'} ne '';
	}
    }
} # catter

# ================================================================
# FUTURE CODE .. nobody calls this yet
# [not exported]
# &settrace($ssv, \%symtb);
# there is a global hash %tracelist.  loop over the SSV and set all elements to 1
# later, in getter and setter, see if the var is in the tracelist and if so, print it
sub settrace {
    my %tracelist;		# for now
    my $tracenames = shift;
    my $xptr = shift;
    my @tvars = split(' ',$tracenames);
    foreach $vvar (@tvars) {
	$tracelist{$vvar} = 1;
    }
    
} # settrace

# ================================================================
# [not exported]
# given a filename, read it in, expand its contents, and return the content
#   $v = &insert_and_expand_file($filename, \%values);
# sets global: incl
# include files can include other files, should all work..
sub insert_and_expand_file {
    my $filename = shift;	# This filename is unchecked.. don't let users from outside specify it.
    my $xptr = shift;
    my $argptrcheck = ref $xptr;
    die "badcall" if $argptrcheck !~ /HASH/;
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
    my $oldfilename = &getter($xptr, '_xf_currentfilename');
    &catter($xptr, '_xf_currentfilename', '>' . $filename);
    my $ans = &expandstring(&expandMulticsBody($content, $xptr), $xptr); # rescan its value to execute *set, *include, etc
    &setter($xptr, '_xf_currentfilename', $oldfilename); # pop
    return $ans;
} # insert_and_expand_file

# ================================================================
# [not exported]
# given a filename, read it in, and return the content without expanding
#   $v = &insert_raw_file($filename, \%values);
sub insert_raw_file {
    my $filename = shift;	# This filename is unchecked.. don't let users from outside specify it.
    my $xptr = shift;
    my $argptrcheck = ref $xptr;
    die "badcall" if $argptrcheck !~ /HASH/;
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
    my $argptrcheck = ref $xptr;
    die "badcall" if $argptrcheck !~ /HASH/;
    &setter($xptr, '_xf_ssvsep', ' ') if &getter($xptr, '_xf_ssvsep') eq "";
    my $sep =  &getter($xptr, '_xf_ssvsep');
    my $content = '';
    my $fh = $incl++;
    if (!open($fh, "$cmd|")) {
	&errmsg($xptr, 0, "warning: cannot execute external command '$cmd' $!");
    }
    while (<$fh>) {	# ravel all lines, space separated
	chomp;
	$content .= $sep if $content ne '';
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
# [exported for use by readbindsql and readbindxml]
# write a warning with program name, current filename, message
# &errmsg(\%v, 0, "message");
# param2 = 0 if warning, else fatal
sub errmsg {
    my $sym = shift;		# symbol tbl ptr to hash
    my $fatal = shift;		# 0 or not
    my $msg = shift;		# message string
    my $argptrcheck = ref $sym;
    die "badcall" if $argptrcheck !~ /HASH/;
    my $chosencolor = color("green");
    my $me = $$sym{'me'};	# don't call getter(), loops
    my $cf = $$sym{'_xf_currentfilename'};
    $chosencolor = color("red") if $fatal==1;
    warn $chosencolor."$me: $cf $msg".color ("reset")."\n";
    exit($fatal) if $fatal != 0;
} # errmsg

# ================================================================
# Expand special HTMX constructs for Multics web pages if _xf_expand_multics is set
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
    my $symtbptr = shift;	# ptr to the symbol table

    return $d if index($d, '{') == -1; # if the string does not need attention, be fast.

    my $enabled = &getter($symtbptr, '_xf_expand_multics');
    return $d if $enabled eq '';	# have no effect if Multics expansion features are not enabled

    # expansions that do not require SQL
    my $bcc = &gvalue('_xf_bracketcolonclass', $symtbptr);
    my $bec = &gvalue('_xf_bracketequalclass', $symtbptr);
    my $bpc = &gvalue('_xf_bracketplusclass', $symtbptr);
    my $bmc = &gvalue('_xf_bracketminusclass', $symtbptr);
    # make sure these have a value if not configured
    $bcc = 'cmd' if $bcc eq '';
    $bec = 'pathname' if $bec eq '';
    $bpc = 'code' if $bpc eq '';
    $bmc = 'special' if $bmc eq '';

    # do these first, since some of the DB expansions may surround SPAN shortcuts .. otherwise it fucks up
    # change {:xxx:} to surround it with "bracketcolonclass"
    $d =~ s/([^\\])\{:([^}]+):\}/$1\<span class=\"$bcc\"\>$2\<\/span\>/g; # TEST
    # change {=xxx=} to surround it with "bracketequalclass"
    $d =~ s/\{=([^}]+)=\}/\<span class=\"$bec\"\>$1\<\/span\>/g;
    # change {+xxx+} to surround it with "bracketplusclass"
    $d =~ s/\{\+([^}]+)\+\}/\<span class=\"$bpc\"\>$1\<\/span\>/g;
    # change {+xxx+} to surround it with "bracketminusclass"
    $d =~ s/\{-([^}]+)-\}/\<span class=\"$bmc\"\>$1\<\/span\>/g;

    return $d if $enabled eq 'nosql'; # we are done if SQL is not enabled
    my $hostname = &gvalue('_xf_hostname', $symtbptr);
    return $d if $hostname eq '';    # we are done if there is no database

    my $ekc = &gvalue('_xf_extrefkeycol', $symtbptr);
    my $ert = &gvalue('_xf_extreftable', $symtbptr);
    my $evc = &gvalue('_xf_extrefvalcol', $symtbptr);
    my $fll = &gvalue('_xf_fixlocallink', $symtbptr);
    my $gbs = &gvalue('_xf_glossbase', $symtbptr);
    my $gkc = &gvalue('_xf_glosskeycol', $symtbptr);
    my $gtb = &gvalue('_xf_glosstable', $symtbptr);
    my $gvc = &gvalue('_xf_glossvalcol', $symtbptr);
    my $inw = &gvalue('_xf_innewwindow', $symtbptr); # ='new window:'
    my $lkc = &gvalue('_xf_loclinkkeycol', $symtbptr);
    my $llt = &gvalue('_xf_loclinktable', $symtbptr);
    my $mkc = &gvalue('_xf_multicianskeycol', $symtbptr);
    my $msr = &gvalue('_xf_multicssourceroot', $symtbptr);
    my $mtt = &gvalue('_xf_multicianstable', $symtbptr);
    my $mvc = &gvalue('_xf_multiciansvalcol', $symtbptr);
    my $mxr = &gvalue('_xf_mxrelative', $symtbptr);
    my $nwx = &gvalue('_xf_newwindow', $symtbptr); # ='target="_blank"'
    my $pfi = &gvalue('_xf_peoplefile', $symtbptr);
    my $tyg = &gvalue('_xf_tinyglob', $symtbptr); # ="<img src=\"mulimg/tinyglob.gif\" alt=\"\" width=\"12\" height=\"11\" border=\"0\" style=\"display: inline;\">"
    $ekc = 'exturl' if $ekc eq '';
    $ert = 'extref' if $ert eq '';
    $evc = 'extname' if $evc eq '';
    $fll = '' if $fll eq '';
    $gbs = 'mg' if $gbs eq '';
    $gkc = 'tag' if $gkc eq '';
    $gtb = 'glossary' if $gtb eq '';
    $gvc = 'def' if $gvc eq '';
    $inw = 'new window:' if $inw eq '';
    $lkc = 'filename' if $lkc eq '';
    $llt = 'pages' if $llt eq '';
    $mkc = 'nametag' if $mkc eq '';
    $msr = '' if $msr eq '';	# for later
    $mtt = 'm' if $mtt eq '';
    $mvc = 'did' if $mvc eq '';
    $mxr = '' if $mxr eq '';	# unless in a subdirectory
    $nwx = 'target="_blank"' if $nwx eq '';
    $pfi = 'multicians' if $pfi eq '';
    $tyg = '<img src="mulimg/tinyglob.gif" alt="" width="12" height="11" border="0" style="display: inline;">' if $tyg eq '';

    # change {[tag string]} to a link into peoplefile with a TITLE attribute derived from "did"
    while ($d =~ /\{\[(\S+) ([^}]+)\]\}/) {
        my $key = $1;
	# warn "key = '$key'";
	if ($key ne "") {
	    my $did;
	    my @cols = ($mvc);
	    ($did) = &lookupSQL($key, $mtt, $mkc, "", \@cols, $symtbptr);
	    $did = &cleanRef($did);
	    $d =~ s/\{\[(\S+) ([^}]+)\]\}/\<a href=\"$mxr$pfi.html\#$1\" title=\"Multician: $did\"\>$2\<\/a\>/;
	}
    } # while

    # change {*string*} to a link into source -- does not currently work
    while ($d =~ /\{\*(\S*)\*\}/) {
        my $key = $1;
	my $root = $msr; # a CGI that looks up the source loc and redirects
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
    my $hostname = &gvalue('_xf_hostname', $symtbptr);
    my $database = &gvalue('_xf_database', $symtbptr);
    my $username = &gvalue('_xf_username', $symtbptr);
    my $password = &gvalue('_xf_password', $symtbptr);
    my $i;
    my $onecol;
    my $onekey;
    my $oneval= '###' . $x;
    my @answer = ($oneval);
    my $db;
    my $sth;
    my $em;			# error message
    if (($database eq '') || ($extreftable eq '') || ($extrefkeycol eq '')) {
	&expandfile::errmsg($symtbptr, 0, "error: database parameters not set: key=$x _xf_database=$database extreftable=$extreftable extrefkeycol=$extrefkeycol");
	exit 1;
    }
    if ($hostname eq 'sqlite') {
	&errmsg($symtbptr, 1, "error: sqlite is not supported"); # see expandfile-internal.html
    } else {			# MySQL database
	if (($hostname eq '') || ($database eq '') || ($username eq '') || ($password eq '') || ($extreftable eq '') || ($extrefkeycol eq '')) {
	    &errmsg($symtbptr, 1,
		    "error: database parameters not set: key=$x _xf_database=$database _xf_hostname=$hostname _xf_username=$username (password) extreftable=$extreftable extrefkeycol=$extrefkeycol");
	}
    }
    my $query = "SELECT * FROM $extreftable WHERE $extrefkeycol = '$x'$selectcond";
    my $fail = 1;
    # if ($hostname eq 'sqlite') { 
    # 	if ($db = DBI->connect("DBI:SQLite:dbname=$database", "", "")) {
    # 	    $fail = 0;		# success
    # 	}
    # } else {
    if (($db = DBI->connect("DBI:mysql:$database:$hostname", $username, $password))) {	# MySQL database
	$fail = 0;		# success
    }

    if ($fail) {
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
	    &errmsg($symtbptr, 1, "error: cannot open DBI:mysql:$database:$hostname $username for query $query");
	}
    } elsif (!($sth = $db->prepare($query))) {
	$em = $db->errstr;
	$db->disconnect;
	&errmsg($symtbptr, 1, "cannot prepare query $query $em");
    } elsif (!$sth->execute) {
	$em = $db->errstr;
	$db->disconnect;
	&errmsg($symtbptr, 1, "cannot execute query $query $em");
    } else {			# ok
	my $numrows = $sth->rows;
	if ($numrows == 0) {
	   &errmsg($symtbptr, 0, "warning: 0 rows for $query"); # nonfatal
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
# Used to create TITLE attributes, which can't have HTML in them.
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
