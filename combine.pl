use strict;
use warnings;
use Data::Dumper;

my $main_filename		= 'HMRC-data-v-1-2-hooksep.txt';
my $counties_filename	= 'HMRC objects by county.txt';

my %county_for_desc;

open my $ifh, '<:encoding(utf8)', $counties_filename or die "Unable to open $counties_filename: $!\n";
while (my $line = <$ifh>) {
	chomp $line;
	my ($desc, $county, $cat) = split /\t/, $line;
	$desc =~ s/^"//;
	$desc =~ s/"$//;
	$desc =~ s/ +$//;
	#print "$county\n";
	$county_for_desc{$desc} = $county;
}
close $ifh;
#print Dumper \%county_for_desc;
my %match_type;

open my $ofh, ">", "HMRC-data-combined.tsv";
open $ifh, "<", $main_filename or die "Unable to open $main_filename: $!\n";
<$ifh>;
while (my $line = <$ifh>) {
	chomp $line;
	# the number of tabs per line seems to be pretty much random, with tab being a character within some fields.
	my @field = split /¬/, $line;
	my $desc = $field[9];
	if (!defined $desc || $desc eq "") {
#		print "Found a blank description for line:\n$line\n";
		$match_type{blank_desc}++;
		print $ofh "$line¬\n";
	}
	else {
		my $county = get_county_for($desc);
		if (defined $county) {
			#print "$desc\n$county_for_desc{$desc}\n";
			print $ofh "$line¬$county\n";
		}
		else {
			print $ofh "$line¬\n";
		}
	}
}
close $ifh;
print Dumper \%match_type;

sub get_county_for {
	my ($desc) = @_;
	my $original_desc = $desc;
	if (defined $county_for_desc{$desc}) {
		my $county = $county_for_desc{$desc};
		#print "$county\n";
		$match_type{exact}++;
		return $county;
	}
	else {
#		print "No county found for:\n'$desc'\n";
		$desc =~ s/ +/ /g;
		if (defined $county_for_desc{$desc}) {
			#print "Found after stripping double spaces\n";
			my $county = $county_for_desc{$desc};
			#print "$county\n";
			$match_type{stripped_double_spaces}++;
			return $county;
		}
		else {
			if ($desc =~ m|\t+Undertakings$|) {
				$desc =~ s|\t+Undertakings$||;
				if (defined $county_for_desc{$desc}) {
					#print "Found after stripping tabs+Undertakings\n";
					my $county = $county_for_desc{$desc};
					#print "$county\n";
					$match_type{stripped_tabs_and_undertakings}++;
					return $county;
				}
			}
			else {
				print "county lookup failed:\n$original_desc\n";
				$match_type{none}++;
				#<STDIN>;
				return undef;
			}
		}
	}
}

