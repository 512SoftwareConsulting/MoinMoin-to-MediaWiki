#!/usr/bin/perl -w

############################################################################
#  
#  Author: Dan Littlejohn 
#
#  Patches provided by: Tyler Drake
#                                                                        
#  File: mm2mw.pl                  
#                                                                           
#  Purpose: Converts Moin Moin docs to MediaWiki docs	
#
#  Version: 1.0.18
#  Date: 08/23/05
#                                                                         
#############################################################################

require "shellwords.pl";
use strict;

use File::Path;

# one and only entry point for program
main();
exit(0);

#########################################################################
# main()
#########################################################################
sub main {

	my $this;

	eval {
		$this = {}; 
		bless($this);		# didn't make a class (ie bless($this,class)) so don't inherit this to other classes

		my $i;

		my $infile;
		my $outfile;

		my $dir;
		my $file;

		#################################################################
		# attributes
		#################################################################
		# set object attributes 

		print STDERR "started\n";

		# get args
		for($i=0;$i<$#ARGV;$i++) { 

			if ($ARGV[$i] eq "-i" || $ARGV[$i] eq "--infile") {
				$infile = $ARGV[$i+1];
			}
			if ($ARGV[$i] eq "-o" || $ARGV[$i] eq "--outfile") {
				$outfile = $ARGV[$i+1];
			}
			if ($ARGV[$i] eq "-d" || $ARGV[$i] eq "--dir") {
				$dir = $ARGV[$i+1];
			}
		}

		# validate variables
		if (not (defined $infile || defined $outfile) && not defined $dir) {
			die "\narguments required\n-i - input file\n-o - output file\nor use\n-d -  to specify a directory to convert all files it contains -> mm2mw_output directory\n";
		}

		# file arg processing
		if (defined $infile && defined $outfile) {
			$this->Filter(infile=>$infile,outfile=>$outfile);
		}

		# dir arg processing
		if (defined $dir) {			
			rmtree("mm2mw_output");
			mkdir("mm2mw_output", 0777) || die "Cannot make directory: $!";

  			opendir(DIR, $dir)
            			or die "can't opendir $dir: $!";
    			for $file (readdir(DIR)) {
				next if $file =~ /^\s*$|^\.(.*)/;  # ignore blanks and dots
				print STDERR " ...$file\n";
				$this->Filter(infile=>"$dir/$file",outfile=>"./mm2mw_output/$file");
    			}
    			closedir(DIR);
		}

		print STDERR "finished\n";

	};
	if ($@) {
		print STDERR "$@\n";	
		return 1;
	} else {
		return 0;
	}
}



#########################################################################
# Filter()
#
# filters lines to correct syntax
#
# args: 1) infile - file to have words converted
# args: 2) outfile - file to output
#
#########################################################################
sub Filter {

	my $this = shift;
	my $args = {
		infile => " ",
		outfile => " ",
		@_,			# Override previous attributes
	};
	my $infile = $args->{infile};
	my $outfile = $args->{outfile};

        my @slashparts;
        my $filename;
	my @spaceparts;
        my $name;

	open(INFILE, "<$infile");
	open(OUTFILE, ">$outfile");
	while (<INFILE>){

		##########
		# line skips
		#
		next if /^----$/; 	# remove unneeded header lines

		##########
		# regexp substitutions
		#

		# list convert - 1st layer
		#
  		s/^ \*(.*?)/\*$1/g;

		# list convert - 2nd layer
		#
  		s/^  \*(.*?)/\*\*$1/g;

		# list convert - 3rd layer
		#
  		s/^   \*(.*?)/\*\*\*$1/g;

		# list convert - 4th layer
		#
  		s/^    \*(.*?)/\*\*\*\*$1/g;

		# list convert - 5th layer
		#
  		s/^     \*(.*?)/\*\*\*\*\*$1/g;

		# link convert - [[BR]] -> <br>
		#
  		s/\[\[BR\]\]/\<br\>/g;

		# link convert superscripted - ^ * ^ -> <sup> * </sup>
		#
  		s/\^(.*?)\^/\<sup\>$1\<\/sup\>/g;

		# link convert subscripted - ,, * ,, -> <sub> * </sub>
		#
  		s/\,\,(.*?)\,\,/\<sub\>$1\<\/sub\>/g;

		# link convert - [# * ] -> [[ * ]]
		#
  		s/\[\#(.*?)\]/\[\[\#$1\]\]/g;

		# link convert - [" * "] -> [[ * ]]
		#
  		s/\[\"(.*?)\"\]/\[\[$1\]\]/g;

		# link convert - [: * ] -> [[ * ]]
		#
  		s/\[\:(.*?)\]/\[\[$1\]\]/g;

		# link convert - __ * __ -> <u> * </u>
		#
  		s/__(.*?)__/\<u\>$1\<\/u\>/g;

		# link convert - {{{ * }}} -> <code><nowiki> * </nowiki></code> 
                # (if on same line)
		#
	        s/\{\{\{(.*?)\}\}\}/<code\>\<nowiki\>$1\<\/nowiki\>\<\/code\>/g;

		# link convert - {{{ *  -> <pre><nowiki> * 
                # (}}} on different line)
		#
  		s/\{\{\{(.*?)/\<pre\>\<nowiki\>$1/g;

		# link convert -  * }}} ->  * <\pre><\nowiki> 
                # (if on same line)
		#
  		s/(.*?)\}\}\}/$1\<\/nowiki\><\/pre\>/g;

		# link convert - [wiki:cat * ] -> [[cat| * ]]
		#
		$this->ConvertWikiLinks(line=>\$_);

		# convert CamelCase links
		#
		$this->ConvertCamelLinks(line=>\$_);

		# link convert - /CommentPage -> Talk:PageName
		#
		@slashparts = split(/\//,$infile);
                my $filename = $slashparts[$#slashparts];
		@spaceparts = split(/(?=[A-Z])/,$filename);
		$name = join(" ",@spaceparts);
  		s/\/CommentPage/\[\[Talk:$name\]\]/g;

                # Convert definition lists
                #
                # Partially built out, but not implemented
                #
                # MM has term, colon, colon, space, definition
                # MW has semicolon, space, term, space, colon, space, definition
  		# s/(.*)\:\:\s(.*)/\;\s$1\s\:\s$2/g;

		##########
		# deletions
		#

		# `` - don't need these (ex Myth``Blog on front page)
		#
  		s/``//g;

		print OUTFILE "$_";
	}
	close OUTFILE;
	close INFILE;
}

#########################################################################
# ConvertWikiLinks()
#
# converts wiki links to correct syntax
# link convert - [wiki:cat * ] -> [[cat| * ]]
#
# args: 1) line - line to have words converted
#
#########################################################################
sub ConvertWikiLinks {

	my $this = shift;
	my $args = {
		line => " ",
		@_,			# Override previous attributes
	};
	my $line = $args->{line};

	eval {
		if ($$line =~ m/\[wiki:(.*?)\s(.*?)\]/) {

			s/\[wiki:(.*?)\s(.*?)\]/\[\[$1\|$2\]\]/g;

			$this->BreakPhrases(line=>\$$line,prefix=>"",suffix=>"");
		}
	};
	if ($@) {
		print STDERR "$@\n";	
		return 1;
	} else {
		return 0;
	}
} 


#########################################################################
# ConvertCamelLinks()
#
# converts camel case links to correct syntax
#
# args: 1) line - line to have words converted
#
#########################################################################
sub ConvertCamelLinks {

	my $this = shift;
	my $args = {
		line => " ",
		@_,			# Override previous attributes
	};
	my $line = $args->{line};

	eval {
			$this->BreakPhrases(line=>\$$line,prefix=>"[[",suffix=>"]]");
	};
	if ($@) {
		print STDERR "$@\n";	
		return 1;
	} else {
		return 0;
	}
} 

#########################################################################
# BreakPhrases()
#
# breaks phrases without spaces into phrases with spaces
#
# args: 1) line - line to have words converted
#       2) prefix - prefix to add to word after it is broken
#       3) variable - line to have words converted
#
#########################################################################
sub BreakPhrases {

	my $this = shift;
	my $args = {
		line => " ",
		prefix => " ",
		suffix => " ",
		@_,			# Override previous attributes
	};
	my $line = $args->{line};
	my $prefix = $args->{prefix};
	my $suffix = $args->{suffix};

	my @words;
	my $i;
	my @parts;

	eval {
		@words = split(/([^a-zA-Z])/, $$line);

		for($i=0;$i<$#words;$i++) {

			if ($words[$i] =~ m/HardWare/ &&
                                        $words[$i] =~ m/MythPeople/ &&
                                        $words[$i] =~ m/MythTv/ &&
                                        $words[$i] =~ m/MythTV/ &&
                                        $words[$i] =~ m/NewsForge/ &&
                                        $words[$i] =~ m/SoftWare/) {

				$words[$i] = $prefix . join(" ",@words) . $suffix;
			}
                        elsif ($words[$i] =~ m/^[a-zA-Z](.*)[a-z][A-Z][a-z](.*)/ &&
					$words[$i] !~ m/Random Quote/ &&
					$words[$i] !~ m/Fortune Cookies/ &&
					$words[$i] !~ m/TiVo/ &&
					$words[$i] !~ m/HDTV/ &&
					$words[$i] !~ m/CommentPage/ ) {

				@parts = split(/(?=[A-Z])/,$words[$i]);
				$words[$i] = $prefix . join(" ",@parts) . $suffix;
			}
		}

		$$line = join("", @words);
	};
	if ($@) {
		print STDERR "$@\n";	
		return 1;
	} else {
		return 0;
	}
} 
