#!/bin/perl -w

############################################################################
#  
#  Author: Dan Littlejohn 
#                                                                        
#  File: mwstuffer.pl                  
#                                                                           
#  Purpose: Converts Moin Moin docs to MediaWiki docs	
#
#  Version: 1.0.2
#  Date: 08/14/05
#                                                                         
#############################################################################

require "shellwords.pl";
use strict;

use File::Path;
use WWW::Mechanize;

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
		my $indir;

		my $file;
		my $page;

		my $urlroot;
		my $url;

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
			if ($ARGV[$i] eq "-d" || $ARGV[$i] eq "--indir") {
				$indir = $ARGV[$i+1];
			}
			if ($ARGV[$i] eq "-u" || $ARGV[$i] eq "--url") {
				$urlroot = $ARGV[$i+1];
			}
		}

		# validate variables
		if (not (defined $infile) && not (defined $indir)) {

			die "\narguments required\n-i - input file\nOR\n-d - to specify a directory\nAND\n-u - output url\n";
		}

		# file arg processing
		if (defined $infile && defined $urlroot) {

			$file = $infile;
			$this->BuildURL(file=>"$file",urlroot=>"$urlroot",url=>\$url);
			
			$this->StuffPage(infile=>$infile,url=>$url);
		}

		# dir arg processing
		if (defined $indir) {			

  			opendir(DIR, $indir)
            			or die "can't opendir $indir: $!";
    			for my $file (readdir(DIR)) {
				next if $file =~ /^\s*$|^\.(.*)/;  # ignore blanks and dots
				print STDERR " ...$file\n";
                                
                                $url = '';
				$this->BuildURL(file=>"$file",urlroot=>"$urlroot",url=>\$url);
                                print STDERR $url ."\n";

				$this->StuffPage(infile=>"$indir/$file",url=>"$url");
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
# StuffPage()
#
# stuffs the text file to a specified media wiki webpage
#
# args: 1) infile - file to stuff into webpage
# args: 2) url - destination webpage
#
#########################################################################
sub StuffPage {

	my $this = shift;
	my $args = {
		infile => " ",
		url => " ",
		@_,			# Override previous attributes
	};
	my $infile = $args->{infile};
	my $url = $args->{url};

	my $body;

	# keeping incase of ripping problems
	open(INFILE, "<$infile");
	while (<INFILE>){

		$body .= $_;
	}
	close INFILE;

	# gave up on wget for the perl module WWW::Mechanize.  Not sure what is missing for wget, seems close, but no cigar.
#	my $cmd = "wget --post-data 'wpTextbox1=test5&wpSummary=&submit=Save page&wpSection=&wpEdittime=' \"$url\"";
#	print STDERR "\n\n$cmd\n\n\n\n";
#	system($cmd);

	# build new mech object
  	my $browser = WWW::Mechanize->new();

  	# tell it to get the main page
  	$browser->get($url);

  	# fill out form and submit
  	$browser->form(1);
  	$browser->field("wpTextbox1", "$body");
  	$browser->click("wpSave");
}

#########################################################################
# ConvertPageName()
#
# converts webpage names to media wiki format
#
# args: 1) file - file name to be converted into a webpage name
# args: 2) url - return converted page name
#
#########################################################################
sub ConvertPageName {

	my $this = shift;
	my $args = {
		file => " ",
		page => " ",
		@_,			# Override previous attributes
	};
	my $file = $args->{file};
	my $page = $args->{page};

	my @words;
	my $i;
	my @parts;

	eval {
		@words = split(/([^a-zA-Z])/, $file);

		for($i=0;$i<$#words+1;$i++){
			if ($words[$i] =~ m/^[a-zA-Z](.*)[a-z][A-Z][a-z](.*)/ &&
					$words[$i] !~ m/HowTo/ &&
					$words[$i] !~ m/HDTV/ && 
					$words[$i] !~ m/LiRc/ &&
					$words[$i] !~ m/MUG/ &&
					$words[$i] !~ m/MySql/ && 
					$words[$i] !~ m/mythTv/ && 
					$words[$i] !~ m/SSH/ && 
					$words[$i] !~ m/TiVo/ &&
					$words[$i] !~ m/XmlTv/ ) {

				@parts = split(/(?=[A-Z])/,$words[$i]);
				$words[$i] = join("_",@parts);
			}
		}

		$$page = join("", @words);
	};
	if ($@) {
		print STDERR "$@\n";	
		return 1;
	} else {
		return 0;
	}
} 

#########################################################################
# BuildURL()
#
# builds the url to be stuffed
#
# args: 1) file - file to stuff into webpage
# args: 2) urlroot - root of url to stuff
# args: 3) url - return url
#
#########################################################################
sub BuildURL {

	my $this = shift;
	my $args = {
		file => " ",
		urlroot => " ",
		ret => " ",
		@_,			# Override previous attributes
	};
	my $file = $args->{file};
	my $urlroot = $args->{urlroot};
	my $url = $args->{url};

	my $page;

	eval {
		$this->ConvertPageName(file=>"$file",page=>\$page);
		if ($urlroot !~ m/^http:\/\//) {
			$$url = "http://";
		}
		$$url .= $urlroot . "?title=" . $page . "&action=edit";
	};
	if ($@) {
		print STDERR "$@\n";	
		return 1;
	} else {
		return 0;
	}
}






