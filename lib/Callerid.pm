package Callerid;

use 5.008004;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

# This allows declaration	use Callerid ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	parse_raw_cid_string format_phone_number
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';

#

=pod

=head1 NAME

Callerid - Perl extension for interpreting raw caller ID information (a la AT#CID=2)

=head1 SYNOPSIS

  use Callerid;
  my($hex) = "8024010830...";

  # OO-style
  my($cid) = new Callerid($hex);
  print $cid->{name}; # prints callers name

  -or-

  # Procedural style
  my(%cid) = Callerid::parse_raw_cid_string($hex);
  print $cid{name}; # prints callers name
  
  # prints phone number pretty
  print Callerid::format_phone_number($cid{number});

=head1 DESCRIPTION

The Callerid module aims to provide a quick and easy method (YMMV) of decoding raw caller ID information as supplied by a modem.

This module does not talk to modems. It also does not mangle input. If you don't supply a hex string of the right format then you lose.

=head2 Methods

=head3 C<< Callerid->new() >>

=head3 C<< Callerid->new($string_of_hex) >>

=over 4

Returns a newly created C<< Callerid >> object. If you supply it with a hex string then (assuming it's not malformed) it will populate data fields in the new C<< Callerid >> object appropriately.

Currently the (public) fields provided are C<< qw(name number hour minute month day) >>.

=back

=head3 C<< $Callerid->parse_raw_cid_string($string_of_hex) >>

=head3 C<< %info = Callerid::parse_raw_cid_string($string_of_hex) >>

=over 4

When called as an object method C<< parse_raw_cid_string() >> will fill the objects data fields with appropriate information. When called as a class method C<< parse_raw_cid_string() >> will return a hash with the same data fields.

=back

=head3 C<< $Callerid->format_phone_number() >>

=head3 C<< Callerid::format_phone_number($number) >>

=over 4

When called as an object method, C<< format_phone_number() >> will return the object's number field formatted pretty. When called as a class method, C<< format_phone_number() >> will take a single argument and will do the same thing.

"Formatted pretty" means 7-digit phone numbers become ###-####, 10-digit numbers become ###-###-#### and everything else is passed through unchanged.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Device::Modem> to do I/O with a modem

Modem command set for putting modem into caller ID mode

=head1 AUTHOR

Mike Carr, E<lt>mcarr@pachogrande.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Mike Carr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

use fields qw(_raw_cid_string name number hour minute month day);

sub new {
	my Callerid $self = shift;
	unless( ref $self ) {
		$self = fields::new($self);
	}
	my($raw_cid_string) = shift;
	if($raw_cid_string) {
		eval {
			my(%results);
			my($href) = $self->parse_raw_cid_string($raw_cid_string);
			if(ref $href) {
				%results = %{ $href };
			}
			for my $field qw(name number hour minute month day) {
				$self->{$field} = $results{$field} if($results{$field});
			}
			$self->{_raw_cid_string} = $raw_cid_string;
		};
		if($@) {
			warn $@;
			return $self->new();
		} else {
			return $self;
		}
	} else {
		$self->{_raw_cid_string} = "";
		for my $field qw(name number hour minute month day) {
			$self->{$field} = "";
		}
	}
	return $self;
}

sub parse_raw_cid_string(;$$) {
	my($_arg) = shift;
	my($self);
	my($c);
	if(ref $_arg) {
		$self = $_arg;
		$c = shift;
	} else {
		$self = {};
		$c = $_arg;
	}

	unless($c) {
		if($self->{_raw_cid_string}) {
			$c = $self->{_raw_cid_string};
		} else {
			warn( __PACKAGE__ . "::parse_raw_cid_string() can't find a string to parse");
			return { };
		}
	}
	
	chomp $c;
	
	unless($c =~ /^[0-9a-fA-F]*$/) {
		croak(__PACKAGE__ . "::parse_raw_cid_string() can't find a valid string to parse");
	}

	
	my(@c) = split //, $c;                    # break each character of the line into the array @c
#	die "nope" unless ($#c == 77);

# Data from modem starts at 8024...; I've noted times beside the data set and a ruler above:
#
# Call  1 - "KLAVA MARY", 		563-3973
# Call  2 - "KLAVA MARY", 		563-3973
# Call  3 - "Brit Columbia", 		961-9279
# Call  4 - "MOEN BRANDON",		612-0539
# Call  5 - "STAFFORD BLAINE",		561-0702
# Call  6 - "STAFFORD BLAINE",		561-0702
# Call  7 - "MOEN BRANDON",		612-0539
# Call  8 - "STUDNEY S",		964-8390
# Call  9 - "STEWART L M",		563-6930
#
#                                0         1         2         3         4         5         6         7      7 
#                                012345678901234567890123456789012345678901234567890123456789012345678901234567
#                                |         |         |         |         |         |         |         |      |
# Call  1 - Aug  7 18:37 2004 => 802401083038303731383337070F4B4C415641204D4152592020202020030735363333393733B5
# Call  2 - Aug  7 19:06 2004 => 802401083038303731393036070F4B4C415641204D4152592020202020030735363333393733B8
# Call  3 - Aug  8 12:45 2004 => 802401083038303831323435070F4B4C415641204D4152592020202020030735363333393733BB
# Call  4 - Aug  8 14:22 2004 => 802401083038303831343232070F4B4C415641204D4152592020202020030735363333393733BE
# Call  5 - Aug 11 13:24 2004 => 802401083038313131333234070F4272697420436F6C756D626961202003073936313932373907
# Call  6 - Aug 11 18:14 2004 => 802401083038313131383134070F4D4F454E204252414E444F4E2020200307363132303533397E
# Call  7 - Aug 11 19:10 2004 => 802401083038313131393130070F53544146464F524420424C41494E4503073536313037303215
# Call  8 - Aug 11 19:30 2004 => 802401083038313131393330070F53544146464F524420424C41494E4503073536313037303213
# Call  9 - Aug 11 19:42 2004 => 802401083038313131393432070F4D4F454E204252414E444F4E2020200307363132303533397C
# Call 10 - Aug 11 19:45 2004 => 802401083038313131393435070F535455444E45592053202020202020030739363438333930C0
# Call 11 - Aug 11 19:46 2004 => 802401083038313131393436070F53544557415254204C204D20202020030735363336393330A2
#                                         N n D d H h M m                                                     
#                                                            ______________________________                   
#                                                                                               # # # # # # # 
#
# local call has 78 characters in it:
# Nn        = month digits
# Dd        = day digits
# Hh        = hour digits
# Mm        = minute digits
# __        = string encoded into hexadecimal using hex(); every two characters turn into one letter
# ##        = phone number digits
#
# 3 appears to be used as a generic seperator digit
# I believe the starting sequence of digits (@c[0 .. 8]) indicates that it's a local call
# I believe (@c[24 .. 27]) is just padding
# I believe (@c[68 .. 62]) is just padding
# I hope that (@c[76 .. 77]) is a checksum, otherwise it's padding
# 
	my($month, $day, $hour, $minute, $name, $number);
	$month    = (sprintf "%d", $c[9]  . $c[11]) if($#c > 11);
	$day      = (sprintf "%d", $c[13] . $c[15]) if($#c > 15);
	$hour     = (sprintf "%d", $c[17] . $c[19]) if($#c > 19);
	$minute   = (sprintf "%d", $c[21] . $c[23]) if($#c > 23);
	{{{ # name calculation
		if($#c > 57) {
			my $hex = join('', @c[28 .. 57]);        		# form a substring from the array
			if($hex =~ /^(.*?)03/) {
				$hex = $1;
			}
			my @parts = unpack("a2" x (length($hex)/2), $hex);      # break the substring 0x00's
			for my $p (@parts) {                               # go through the list of digits
				#       printf "%s becomes %c\n", $p, hex($p);
				$name .= sprintf "%c", hex($p);            # and convert each to a character
			}
		} else {
			if($c =~ /..0401/) {
				$name = "*PRIVATE";
				$number = "";
			} else {
				$name = "ERROR"; warn "error parsing name, too short, yet not private";
			}
		}
	}}}
	{{{ # number calculation
		if($c =~ /..0401/) {
			$number = "";
		} else {
			for my $n qw(11 7) {
				if($c =~ m/^.*((3\d){$n})/) {
					my($three_coded) = $1;
					my(@three_coded) = split //, $three_coded;
					my($toggle) = 1;
					my(@number) = grep { $toggle = !($toggle) } @three_coded;
					$number ||= join('', @number);
				}
			}
			
			unless($number) { warn("didn't parse number, doesn't match as private"); }
		}
	}}}

	# Reset all fields that we should be filling. aka "sanity checking"
	for my $field qw(name number month day hour minute _raw_cid_string) {
		$self->{$field} = "";
	}

	$self->{name} = $name if $name;
	$self->{number} = $number if($number || $name =~ /^\*PRIVATE$/);
	$self->{month} = $month if $month;
	$self->{day} = $day if $day;
	$self->{hour} = $hour if $hour;
	$self->{minute} = $minute if $minute;
	$self->{_raw_cid_string} = $c;

	return $self;
}

sub format_phone_number(;$$) {
	my($_arg) = shift;
	my($self);
	my($number);

	if(ref $_arg) {
		$self = $_arg;
		if(@_) {
			$number = shift;
		} else {
			$number = $self->{number};
		}
	} else {
		$self = { };
		$number = $_arg;
	}

	# this all might become a regex someday... let's try substr() first
	if(length($number) == 7) {
		return( 
			substr($number, 0, 3) . 
			'-' . 
			substr($number, 3, 4) 
		);
	} elsif(length($number) == 11) {
		return( 
			substr($number, 0, 1) . 
			'-' . 
			substr($number, 1, 3) .
			'-' .
			substr($number, 4, 3) .
			'-' .
			substr($number, 7, 4)
		);
	} else {
		return $number;
	}
}

1;

# vim: set ts=2:
