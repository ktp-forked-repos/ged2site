package Gedsite::Display::calendar;

use strict;
use warnings;

# Display the calendar page

use Gedsite::Display::page;
use DateTime;
use DateTime::Locale;

our @ISA = ('Gedsite::Display::page');

sub html {
	my $self = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	my $info = $self->{_info};
	my $allowed = {
		'page' => 'calendar',
		'month' => qr(^\d{1,2}$),	# must be one or two digits
	};
	my $params = $info->params({ allow => $allowed });
	if($params && $params->{'page'}) {
		delete $params->{'page'};
	}

	# unless($params && scalar(keys %{$params})) {
		# # Display the main calendar page
		# # TODO: use the current month as the default
		# return $self->SUPER::html({ months => DateTime::Locale->load($self->{_lingua}->language())->month_format_wide() });
	# }

	if(my $month = $params->{'month'}) {
		# Handles into the databases
		my $history = $args{'history'};

		my @events;

		foreach my $event(@{$history->selectall_hashref({ month => $month })}) {
			# TODO: sort by name
			push @{$events[$event->{'day'} - 1]}, $event;
		}
		my $dt = DateTime->today();
		return $self->SUPER::html({
			events => \@events,
			month => @{DateTime::Locale->load($self->{_lingua}->language())->month_format_wide()}[$month - 1],
			year => DateTime->today()->year()
		});
	} else {
		my $history = $args{'history'};
		return $self->SUPER::html({ events => $history->selectall_hashref() });
	}

	return $self->SUPER::html();
}

1;
