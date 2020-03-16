#!/usr/local/bin/perl

# module to read an xml file and bind its contents .. the XML file
# has a toplevel <list> of <item> structures.
# if the XML values have things like <cite> in them this causes XML::LibXML to return HASH values instead of scalar strings.
# .. this will work if the entire value of the field is enclosed in <cite> etc.
# .. otherwise, the hash keys will come out in random order, and anything not enclosed in any sublevel will be concatenated together.
# So use !!cite!!whatever!!/cite!! instead.
# HTML entities like &aacute; will fail ... use &amp;aacute;
#
### NOTE: this file will not compile under Perl 5.12.. it works with Perl 5.16
#
# Sample input
#<?xml version='1.0'?>
#<list>
# <!-- prototype
# <item type="" sequence="">
#   <title></title>
#   <authors></authors>
#   <pubdate></pubdate>
#   <refinfo></refinfo>
#   <link></link>
#   <commentlink1anchor></commentlink1anchor>
#   <commentlink1target></commentlink1target>
#   <commentlink2anchor></commentlink2anchor>
#   <commentlink2target></commentlink2target>
#   <comment></comment>
# </item>
# ...
# </list>
#
# USAGE:
#   open(CFG, $configfile);
#   my @lines = <CFG>;
#   close(CFG);
#   my $xmlstring = join('', @lines);
#   &readbindxml($xmlstring, \%symtb, \&dumpit);
#   .. where &dumpit() is a closure that accesses $symtb{item.title}, etc.
##
# 2015-03-25 THVV new
# 2015-05-13 THVV added flattening of hashes
# 2018-02-15 THVV use XML::LibXML instead of XML::Simple, add optional XPath
# 2018-08-18 THVV add tracebind
# 2018-10-12 THVV fix tracebind, export main program, add warning on bad XML
# 2018-10-15 THVV if multiple daughters, concat their values in a CSV
# 2018-10-15 THVV if attribute and daughter have same name, rename attribute with _attr
# 2019-01-25 THVV do not call LibXML on empty string
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

package readbindxml;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(iterateXML readbindxml);
# export reaadbindxml because it is used by xml2sql

use XML::LibXML;

# ================================================================
# XML iteration function used by *xmlloop in expandfile.pm
# the XML file has outermost <list> ... </list> containing multiple <item>... </item>
# the iterator will be able to access %[item.fieldname]% for each element of <item>
# sets %[_nxml]% to number of rows
# sets %[_xmlfields]% to space separated list of field names

sub iterateXML {
    my $iterator = shift;
    my $xmlfile = shift;
    my $symtbptr = shift;
    my $xpath = shift;		# optional xpath
    my $result = '';
    my $fh = $incl++;		# increase global filehandle counter
    if ($xmlfile =~ /\.gz$|\.z$/i) {
    	if (!open($fh, "gzcat $xmlfile |")) {
	    &errmsg($symtbptr, 1, "missing compressed XML file '$xmlfile' $! in *xmlloop");
	}
    } else {
    	if (!open($fh, "$xmlfile")) {
	    &errmsg($symtbptr, 1, "missing XML file '$xmlfile' $! in *xmlloop");
	}
    }
    my @lines = <$fh>; # read whole file
    close($fh);
    my $xmlstring = join('', @lines);
    # ---------------- closure invoked on each item in the XML
    my $xmlexpandfunc = sub {
        if ($iterator ne '') {
	    $result .= &expandfile::expandstring($iterator, $symtbptr);
        }
    };
    # ----------------
    my $nitems = 0;
    if ($xmlstring ne "") {	# do not call LibXML on empty string 
	$nitems = &readbindxml($xmlstring, $symtbptr, $xmlexpandfunc, $xpath);  # for each item, bind its vars, expand $iterator and append to $result
    }
    $$symtbptr{'_nxml'} = $nitems;  # Report results.
    warn "readbindxml: _nxml $$symtbptr{'_nxml'}\n" if ($$symtbptr{'_tracebind'} eq 'yes') || ($ENV{'_tracebind'} eq 'yes');
    return $result;
} # iterateXML

# ================================================================
# XML iteration function used by *xmlloop
#     my $nitems = &readbindxml($xmlstring, $symtbptr, $xmlexpand[, $xpath]);
# for each item, bind vars, epand iterator tpt by calling $xmlexpand, append to result
# also sets %[_xmlfields]% to space separated list of field names
#
# an optional $xpath argument is allowed to generate the path to nodes to be considered.
#   .. if xpath is not supplied, use default '/*/*'
# for instance, using '/computer_group/computers/*' on the Jamf data works great

sub readbindxml {
    my $xmlstring = shift;
    my $vp = shift;
    my $iteratorclosure = shift;
    my $nodepath = shift;
    if (!defined($nodepath)) {
	$nodepath = '/*/*';
    }
    
    my $dom = XML::LibXML->load_xml(string => $xmlstring);  # do I need to call Encode::encode_utf8() ?? guess not
    
    my %keynames;
    my %attnames;
    my $namect = 0;
    my $basename;
    
    # First pass. generate the whole list of possible fieldnames
    foreach my $item ($dom->findnodes($nodepath)) { # find all sub-items of items
	$basename = $item->nodeName;		 # this better not change.. could check
	foreach my $field ($item->findnodes('./*')) {
	    my $aa = $basename . '.' . $field->nodeName;
	    $keynames{$aa}++; # accumulate the HTMX var names
	    $namect++;
	}
    } # find all sub-items of items
    foreach my $att ($dom->findnodes($nodepath . '/@*')) { # get all attributes of items
	my $a0 = $att->nodeName;
	my $aa = $basename . '.' . $a0;
	# .. if this attribute name duplicates a node name, this will cause bad SQL with a duplicate name.
	if (defined($keynames{$aa})) { 
	    $aa .= "_attr";
	    warn "warning: $a0 is both a node name and an attribute name: renaming attribute field to $aa\n" if !defined($attnames{$aa});
	}
	$attnames{$aa}++;
	$namect++;
    } # get all attributes of items

    warn "readbindxml: no names" if $namect == 0;

    my $tf = join(' ', keys %keynames);
    $tf .= ' ' . join(' ', keys %attnames);
    $tf =~ s/  / /g; # make sure xmlfields has no empty fields
    $tf =~ s/^ //g; # make sure xmlfields does not begin with a space
    $$vp{'_xmlfields'} = $tf;	# ensure _xmlfields is bound before iterator uses it in expansion
    warn "readbindxml: _xmlfields $$vp{'_xmlfields'}\n" if ($$vp{'_tracebind'} eq 'yes') || ($ENV{'_tracebind'} eq 'yes');
    
    # Second pass. Go over the items again, bind the values, and call $iteratorclosure on each one.
    my $nitems = 0;
    foreach my $item ($dom->findnodes($nodepath)) { # second pass
	my $basename = $item->nodeName;
	# bind all the attributes and subfields, even if this item doesn't have one.. otherwise values would leak from one item to another.
	foreach $field (keys %keynames) {
	    $$vp{$field} = "";
	}
	foreach $field (keys %attnames) {
	    $$vp{$field} = "";
	}
	# process all the items contained inside the node.
	foreach my $field ($item->findnodes('./*')) {
	    $x = $basename . '.' . $field->nodeName;
	    my $value = $field->findvalue('.');
	    #warn "readbindxml: debug $x $value\n"; #DEBUG
	    if ((ref $value eq "") || (ref $value eq "SCALAR")) {
		$value =~ s/!!\/(.*?)!!/\<\/$1\>/g; # fix the angle brackets
		$value =~ s/!!(.*?)!!/\<$1\>/g;
		$value =~ s/^\s*//;	# eliminate leading whitespace
		$value =~ s/\s*$//;	# eliminate trailing whitespace
		$value =~ s/\n\s*/ /g;  # change NL and leading whitespace to single blank
	    } else { # HASH ARRAY CODE REF GLOB LVALUE FORMAT IO VSTRING Regexp
		$value = &flattenRef($value); # flatten hash or array ????
		warn "readbindxml: nonscalar $x $value\n";
	    }
	    if (defined($$vp{$x})) {   # if we have multiple daughters with the same name for an item..
		#warn "readbindxml: concat $x $$vp{$x} $value\n" if $$vp{$x} ne ''; # DEBUG
		$$vp{$x} .= ',' if $$vp{$x} ne ""; # concatenate values separated by "," (shd this be _ssvsep?)
		$$vp{$x} .= $value;
	    } else {
		$$vp{$x} =  $value;
	    }
	    warn "readbindxml: bound $x = $$vp{$x}\n" if ($$vp{'_tracebind'} eq 'yes') || ($ENV{'_tracebind'} eq 'yes');
	} # foreach
	# process all the attributes of $item and bind their values
	my $att_field;
	foreach $att_field ($item->findnodes('./@*')) {
	    my $name = $att_field->nodeName;
	    my $value = $att_field->findvalue('.');
	    my $aa = $basename . '.' . $name;
	    # what if it was renamed?  If so, use the new name.
	    if (defined($attnames{$aa.'_attr'})) {
		$aa .= "_attr";
	    }
	    $$vp{$aa} =  $value;
	    warn "readbindxml: bound $aa = $value\n" if ($$vp{'_tracebind'} eq 'yes') || ($ENV{'_tracebind'} eq 'yes');
	} # foreach
	$nitems++;
	$iteratorclosure -> ();		# all fields bound: invoke the closure to expand the iterator
    } # second pass
    return $nitems;		# return count of items

} # readbindxml

# flattenRef
sub flattenRef {
    my $p = shift;
    warn "debug flattenRef $p\n";
    my $v = '';
    my $sep = '';
    if (ref $p eq "") {
	return $p;		# SCALAR
    } elsif (ref $p eq ref {}) { # does this even happen in LibXML?
	# flatten hash
	foreach $f (keys %$p) {	# comes out in hashkey order, not as in file
	    if ($f eq "content") { 
		$v .= &flattenRef($p->{$f});
	    } else {
		$v .= "<$f>" . &flattenRef($p->{$f}) . "</$f>";
	    }
	}
	return $v;
    } elsif (ref $p eq ref []) {# does this happen in LibXML?
	# flatten array
	foreach (@{$p}) {
	    $v .= $sep . &flattenRef($_);
	    $sep = ' ';
	}
	return $v;
    } else {
	warn "trouble with " . (ref $p) . " " . $p . "\n";
	return "";
    }
} # flattenRef

