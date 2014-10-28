#!/usr/bin/perl
# This script will convert wig file into a fasta format
# Converting values of the wig file into whatever you want
# This is useful if you want to call states/peaks using StochHMM
#
# For example, "A" is anything below 10, "B" is anything above 10, "N" is anything 0
# variableStep chrom=chr1 span=10
# 1
# 11
# 5.5
# 20
# 0
# 0
#
# Into:
#
# >chr1
# ABABNN

use strict; use warnings; 
use Getopt::Std;
use vars qw($opt_i $opt_o);
getopts("i:o:");

# Usage statement
die "usage: $0 -i <input> [Optional: -o <output>]

-i: Input is a single type variableStep wig file.
-o: Output file (optional). Otherwise it will be <input.customfa>.

" unless defined($opt_i);
main();

# DO NOT CHANGE
sub convert {
	my ($number) = @_;
	return("N") if $number == 0;
	return("L") if $number <= 10;
  return("O") if $number <= 25;
  return("M") if $number <= 40;
  return("H") if $number <= 70;
  return("S") if $number > 70;
}

sub main {
	# Input
	my ($input) = ($opt_i);
	if ($input =~ /.customfa/) {
		die "Input cannot be .customfa!\n";
	}
  # FIXME this may be incorrect regex. Use File::Basename if you want to improve it.
  # Or just use -o option
  my ($name) = $input =~ /\/{0,1}(.+)$/ ; # to get filename without mitochy.pm
	my $output = defined($opt_o) ? $opt_o : "$name.customfa";
	
	# Open input wig file and process
	open (my $in, "<", $input) 	or die "Cannot read from $input: $!\n" if $input !~ /.gz/;
	open ($in, "zcat $input |") 	or die "Cannot read from gunzipped $input: $!\n" if $input =~ /.gz/;
	open (my $out, ">", $output) 	or die "Cannot write to $output: $!\n";
	
	my $chr 	= "INIT";
	my $span 	= 1;
	my $lastpos 	= 0;
	while (my $line = <$in>) {
		chomp($line);
		next if $line =~ /#/;
		next if $line =~ /track/;
	
		# If line is variableStep then extract chromosome
		if ($line =~ /Step/) {
			print $out "\n" if $chr ne "INIT";
			$lastpos = 0;

			($chr, $span) = $line =~ /chrom=(.+) span=(\d+)/;
			($chr) = $line =~ /chrom(.+) / if not defined($chr);
			($chr) = $line =~ /chrom(.+)/  if not defined($chr);
			$span = 1 if not defined($span);
			print "Processing chromosome $chr line is $line\n";
			print $out ">$chr\n";
#			last if $chr ne "chr1";
		}
		else {
			die "Died at $line because line is not a wig file number\n" if $line !~ /^\d+/;
			my ($pos, $val) = split("\t", $line);
			my $number = convert($val);
			if ($lastpos == 0 and $pos != 1) {
				for (my $i = 0; $i < $pos; $i++) {
					print $out "N";
				}
			}
			elsif ($pos != $lastpos + $span) {
				for (my $i = $lastpos; $i < $pos; $i++) {
					print $out "N";
				}
			}
			else {
				for (my $i = $pos; $i < $pos+$span; $i++) {
					print $out "$number";
				}
			}
			$lastpos = $pos;
		}
	}

	close $in;
	close $out;
}

