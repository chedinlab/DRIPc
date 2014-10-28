#!/usr/bin/env perl
use warnings;
use strict;

# Shift-wig normalization 
# Assumes constant span

my ($wig, $outfile) = @ARGV;
die "usage: $0 <wigfile> <outfile>\n" unless @ARGV;

open (IN, "<", $wig) or die "Could not open $wig\n";

my @values;

while (<IN>) {
  my $line = $_;
  chomp $line; 

  if ($line =~ /^\d+/) {
    my ($pos, $val) = split(/\t/, $line);
    push (@values, int($val));
  }
}

close IN;

my $median = int(@values / 2);
my $quart = int($median / 2);
my $third = $quart * 3; # index of third quartile

my @sort = sort {$a<=>$b} @values; 
# delete values array
@values = (); 

# find value of third quartile
my $third_val = $sort[$third]; 

my $iter = $third;

# find the next largest value after the value of the third quartile
# FIXME replace this loop with something better
while ($sort[$iter] <= $sort[$third]) { 
  $iter++;                              
} 

my @small = @sort[$iter..(@sort - 1)];
# delete sort array
@sort = (); 

# find index of median of remaining values
my $third_median = int(@small / 2); 

# Divide the original DRIP NT2 median -- which the model was trained
# on -- by the third quartile median to find the multiplication factor
my $shift = 10/$small[$third_median];
# delete small array
@small = ();

open (IN, "<", $wig);
open (OUT, ">", $outfile) or die "Could not open outfile\n";

while(<IN>) {
  my $line = $_;
  chomp $line;

  if ($line !~ /^\d+/) {
    print OUT "$line\n";
  }
  else {
    my ($pos, $val) = split(/\t/, $line);
# linearly shift values by factor
    $val *= $shift;
    print OUT "$pos\t$val\n";
  }
}

close IN;
close OUT;
