package Ged2site::Display::descendants;

use strict;
use warnings;

# Display a person's descendants

use Ged2site::Display::page;
use MIME::Base64;

our @ISA = ('Ged2site::Display::page');

sub html {
	my $self = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	my $info = $self->{_info};
	my $allowed = {
		'page' => 'descendants',
		'entry' => undef,	# TODO: regex of allowable name formats
		# 'lang' => qr/^[A-Z][A-Z]/i,
	};
	my %params = %{$info->params({ allow => $allowed })};

	delete $params{'page'};
	delete $params{'lang'};

	my $people = $args{'people'};	# Handle into the database

	unless(scalar(keys %params)) {
		# Display the main index page
		return $self->SUPER::html(updated => $people->updated());
	}

	# Look in the people.csv for the name given as the CGI argument and
	# find their details
	# TODO: handle situation where look up fails
	my $person = $people->fetchrow_hashref(\%params);
	my ($nodes, $edges) = _build_nodes($people, $person, '0', 0);

	my $graph = "var graph = {\n" .
		"nodes: new vis.DataSet([\n" .
		$nodes .
		"]),\n" .
		"edges: new vis.DataSet([\n" .
		$edges .
		"])\n" .
		"};";

	return $self->SUPER::html({
		graph => $graph,
		person => $person,
		decode_base64url => sub {
			MIME::Base64::decode_base64url($_[0])
		},
		updated => $people->updated()
	});
}

sub _build_nodes {
	my $people = shift;
	my $person = shift;
	my $id = shift;
	my $level = shift;

	my $title = $person->{'title'};
	$title =~ s/\s\d{4}.+//;
	if($title =~ /(.+)\s.+\s\(n&eacute;e\s(.+)\)/) {
		$title = "$1 $2";	# Get maiden name
	}
	if($title =~ /(.+)\s.+\s(.+)/) {
		$title = "$1 $2";	# Remove middle name(s)
	}
	my $nodes = "{\"id\": \"$id\", \"label\": \"" . $title . "\", \"level\": $level },\n";
	my $count = 1;
	my $edges;

	$level++;
	foreach my $child(split('----' ,$person->{'children'})) {
		if($child =~ /entry=(I\d+)">.+<\/a>/) {
			$child = $people->fetchrow_hashref({ entry => $1 });

			my ($n, $e) = _build_nodes($people, $child, "$id." . $count, $level);
			$nodes .= $n;
			$edges .= "{\"from\": \"$id\", \"to\": \"$id.$count\"},\n" . $e;

			$count++;
		}
	}

	return ($nodes, $edges);
}

1;