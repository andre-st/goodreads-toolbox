#!/usr/bin/perl -w

# Test cases realized:
#   [x] additive absolute progress with custom unit
#   [x] additive percent progress
#   [ ] invalid arguments
#   [ ] 


use diagnostics;  # More debugging info
use warnings;
use strict;
use Test::More qw( no_plan );
use List::MoreUtils qw( any firstval );
use FindBin;
use lib "$FindBin::Bin/../lib/";


use_ok( 'Goodscrapes' );


my $stdout;
{
	local *STDOUT;
	open( STDOUT, ">", \$stdout );
	my $meter;
	
	
	# Absolute progress with custom unit:
	$meter = gmeter( 'test unit' );
	
	$stdout = '';
	$meter->( 1 );
	like( $stdout, qr/1 test unit/, 'Prints number with custom unit' );
	
	$stdout = '';
	$meter->( 20 );  # Adds 20 to previous value 1
	like( $stdout, qr/21 test unit/, 'Prints sum with custom unit' );
	
	
	# Percent progress is enabled by using a second number with a known maximum
	# Any custom unit is ignored.
	$meter = gmeter();
	
	$stdout = '';
	$meter->( 1, 10 );
	like( $stdout, qr/10%/, 'Prints percent number' );
	
	$stdout = '';
	$meter->( 5, 10 );  # Adds another 5 to prev value 1; You must not read this as "5 of 10" or 50%
	like( $stdout, qr/60%/, 'Prints percent number for sum' );
}




