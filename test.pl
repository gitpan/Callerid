#!/usr/bin/perl
#

use strict;
use warnings;
use Test;

BEGIN { plan tests => 38, todo => [3,4] }

use lib qw(/home/mcarr/Callerid/lib);
use Callerid;

my $tmp;

#0
print qq(# Instantiate some blank objects?\n);
ok( $tmp = new Callerid );
ok( $tmp = Callerid->new() );

#2
print qq(# Can we run parse_raw_cid_string as a class method?\n);
ok( Callerid::parse_raw_cid_string(qq(802401083038303731383337070F4B4C415641204D4152592020202020030735363333393733B5)) );

#3
print qq(# Create a Callerid object with bogus info\n);
ok( $tmp = Callerid->new(qq(foo foo the bunny hop)) );

#4
print qq(# Create a Callerid object with malformed info\n);
ok( $tmp = Callerid->new(qq(0123456789)) );

#5
my(%calltypes) = (
	"1_local"         => qq(802401083038303731383337070F4B4C415641204D4152592020202020030735363333393733B5),
	"2_private"       => qq(80100108303831313031303808015004015026),
	"3_long_distance" => qq(80230108303831323137313507074B4C415641204A030B313738303533383430383306014C34),
);
for my $type (sort keys %calltypes) {
print qq(# Create an object to test $type types of calls\n);
ok( $tmp = Callerid->new( $calltypes{ $type }) );
ok( $tmp->{name} );
ok( defined($tmp->{number}) );
ok( $tmp->{month} );
ok( $tmp->{day} );
ok( $tmp->{hour} );
ok( $tmp->{minute} );
}
#26 = 5 + 7*3

#27-30, 31-34, 35-38
{
	my($seven,$eleven,$bogus) = ('1234567', '12345678901', '123');
	print "# testing \$Callerid->format_phone_number(\$number)\n";
ok( $tmp->format_phone_number($seven) eq '123-4567' );
ok( $tmp->format_phone_number($eleven) eq '1-234-567-8901' );
ok( $tmp->format_phone_number($bogus) );
	print "# testing \$Callerid->format_phone_number()\n";
ok( $tmp->{number} = $seven and $tmp->format_phone_number() eq '123-4567' );
ok( $tmp->{number} = $eleven and $tmp->format_phone_number() eq '1-234-567-8901' );
ok( $tmp->{number} = $bogus and $tmp->format_phone_number() );
	print "# testing Callerid::format_phone_number()\n";
ok( Callerid::format_phone_number($seven) eq '123-4567' );
ok( Callerid::format_phone_number($eleven) eq '1-234-567-8901' );
ok( Callerid::format_phone_number($bogus) );
}
