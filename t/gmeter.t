#!/usr/bin/perl -w

# Test cases realized:
#   [x] additive percent progress
#   [x] additive absolute progress with custom unit
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
	
	
	# Percent progress:
	$meter = gmeter();
	
	$stdout = '';
	$meter->( 1, 10 );
	like( $stdout, qr/10%/, 'Prints percent number' );
	
	$stdout = '';
	$meter->( 5, 10 );  # Adds 50% to previous value 10%
	like( $stdout, qr/60%/, 'Prints added percent number' );
	
	
	# Absolute progress with custom unit:
	$meter  = gmeter( 'test unit' );
	
	$stdout = '';
	$meter->( 1 );
	like( $stdout, qr/1 test unit/, 'Prints number with unit' );
	
	$stdout = '';
	$meter->( 20 );  # Adds 20 to previous value 1
	like( $stdout, qr/21 test unit/, 'Prints added number with unit' );
}




