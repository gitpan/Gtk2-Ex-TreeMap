package Gtk2::Ex::TreeMap;

our $VERSION = '0.01';

use strict;
use warnings;
use Data::Dumper;
use Glib qw /TRUE FALSE/;
use GD;
use Gtk2 -init;

sub new {
	my ($class) = @_;
	my $self  = {};
	$self->{rectangles} = undef;
	$self->{eventbox} = undef;
	$self->{image} = undef;
	$self->{selected} = undef;
	bless ($self, $class);
	return $self;
}

sub get_image {
	my ($self) = @_;
	return $self->{eventbox};
}

sub get_rectangles {
	my ($self) = @_;
	return $self->{rectangles};
}

sub draw {
	my ($self, $size, $values) = @_;
	# Get rid of all 0 values
	my @goodvalues;
	foreach my $value (@$values) {
		push @goodvalues, $value if $value > 0;
	}
	my @sortedvalues = reverse sort @goodvalues;
	if ($size->[0] > $size->[1]) {
		$self->_draw_squarified([0,0,@$size], \@sortedvalues, 'horizontal');
	} else {
		$self->_draw_squarified([0,0,@$size], \@sortedvalues, 'vertical');
	}
	my $im = new GD::Image(@$size);
	my $black = $im->colorAllocate(0,0,0);       
	my $count = 0;
	my $incr = 20;
	foreach my $rect(@{$self->{rectangles}}) {
		$im->rectangle(@$rect, $black);
		my $middle_x = ($rect->[0] + $rect->[2])/2;
		my $middle_y = ($rect->[1] + $rect->[3])/2;
		my $color = $im->colorResolve($count,$count, 120);
		$im->fill($middle_x, $middle_y, $color);
		$count += $incr;
	}	
	$self->{image} = $im;
	my $loader = Gtk2::Gdk::PixbufLoader->new;
	$loader->write ($im->png);
	$loader->close;
	my $image = Gtk2::Image->new_from_pixbuf($loader->get_pixbuf);
	my $eventbox = Gtk2::EventBox->new;
	$eventbox->add ($image);
	print Dumper $self->{rectangles};
	$eventbox->add_events (['pointer-motion-mask', 'pointer-motion-hint-mask']);
	$eventbox->signal_connect ('motion-notify-event' => 
		sub {
			my ($widget, $event) = @_;
			my ($x, $y) = ($event->x, $event->y);
			unless ($self->{imageallocatedsize}) {
				my @imageallocatedsize = $image->allocation->values;
				$self->{imageallocatedsize} = \@imageallocatedsize;
			}
			$x -= ($self->{imageallocatedsize}->[2] - $size->[0])/2;
			$y -= ($self->{imageallocatedsize}->[3] - $size->[1])/2;
			my $rectangle_id = $self->_check_inside_rectangle($x,$y);
			if ($rectangle_id >= 0 and (!$self->{selected} or $rectangle_id != $self->{selected})) {
				$self->{selected} = $rectangle_id;
				$self->_highlight_rectangle($self->{rectangles}->[$rectangle_id]);
			}
		}
	);
	$self->{eventbox} = $eventbox;
}

sub _highlight_rectangle {
	my ($self, $rect) = @_;
	my $eventbox = $self->{eventbox};
	my @children = $eventbox->get_children;
	foreach my $child (@children) {
		$eventbox->remove($child);
	}
	my $im = $self->{image}->clone;	
	my $white = $im->colorAllocate(255,255,255);
	$im->rectangle(@$rect, $white);
	my $loader = Gtk2::Gdk::PixbufLoader->new;
	$loader->write ($im->png);
	$loader->close;
	my $image = Gtk2::Image->new_from_pixbuf($loader->get_pixbuf);
	$eventbox->add($image);
	$eventbox->show_all;
}

sub _check_inside_rectangle {
	my ($self, $x, $y) = @_;
	my $count = 0;
	foreach my $rect(@{$self->{rectangles}}) {
		if ($x >= $rect->[0] and $x <= $rect->[2] and $y >= $rect->[1] and $y <= $rect->[3]) {
			return $count;
		}
		$count++;
	}
	return -1;
}

sub _draw_squarified {
	my ($self, $rect, $values, $direction) = @_;
	if ($#{@$values} == 0) {
		$self->draw_list([$rect]);
		return;
	}
	my $sum = 0;
	foreach my $x (@$values) {
		$sum += $x;
	}
	my $best_aspect_ratio = 0;
	my $best_rectangles;
	my $width = abs($rect->[2] - $rect->[0]);
	my $height = abs($rect->[3] - $rect->[1]);
	my ($x1, $y1, $x2, $y2);
	if ($direction eq 'horizontal') {
		for (my $i=0; $i<=$#{@$values}; $i++) {
			($x1, $y1) = ($rect->[0], $rect->[1]);
			my @temp;
			my $localsum = 0;
			for (my $j=0; $j<=$i; $j++) {
				$localsum += $values->[$j];
			}
			$x2 = int($x1 + $width*$localsum/$sum);
			for (my $j=0; $j<=$i; $j++) {
				$y2 = int($y1 + $height*$values->[$j]/$localsum);
				push @temp, [$x1, $y1, $x2, $y2];
				$y1 = $y2;
			}
			my $aspect_ratio = _calc_best_aspect_ratio(\@temp);
			if ($aspect_ratio > $best_aspect_ratio) {
				$best_aspect_ratio = $aspect_ratio;
				$best_rectangles = \@temp;
			} else {
				$self->draw_list($best_rectangles);
				my ($x1, $y1, $x2, $y2) = ($best_rectangles->[$i-1]->[2], $rect->[1], $rect->[2], $rect->[3]);
				for (my $j=0; $j<$i; $j++) {
					shift @$values;					
				}
				$self->_draw_squarified([$x1, $y1, $x2, $y2], $values, 'vertical');
				return;
			}
		}
	} elsif ($direction eq 'vertical') {
		for (my $i=0; $i<=$#{@$values}; $i++) {
			($x1, $y1) = ($rect->[0], $rect->[1]);
			my @temp;
			my $localsum = 0;
			for (my $j=0; $j<=$i; $j++) {
				$localsum += $values->[$j];
			}
			$y2 = int($y1 + $height*$localsum/$sum);
			for (my $j=0; $j<=$i; $j++) {
				$x2 = int($x1 + $width*$values->[$j]/$localsum);
				push @temp, [$x1, $y1, $x2, $y2];
				$x1 = $x2;
			}
			my $aspect_ratio = _calc_best_aspect_ratio(\@temp);
			if ($aspect_ratio > $best_aspect_ratio) {
				$best_aspect_ratio = $aspect_ratio;
				$best_rectangles = \@temp;
			} else {
				$self->draw_list($best_rectangles);
				my ($x1, $y1, $x2, $y2) = ($rect->[0], $best_rectangles->[$i-1]->[3], $rect->[2], $rect->[3]);
				for (my $j=0; $j<$i; $j++) {
					shift @$values;					
				}
				$self->_draw_squarified([$x1, $y1, $x2, $y2], $values, 'horizontal');
				return;
			}
		}
	
	}	
}

sub _calc_best_aspect_ratio {
	my ($rectangles) = @_;
	my @aspect;
	foreach my $r (@$rectangles) {
		my $l = abs ( ($r->[0] - $r->[2])/($r->[1] - $r->[3]) );
		my $h = abs ( ($r->[1] - $r->[3])/($r->[0] - $r->[2]) );
		push @aspect, $l < $h ? $l : $h;
	}
	return min(@aspect);
}

sub min {
	my (@values) = @_;
	my $min = $values[0];
	foreach my $x (@values) {
		$min = $x if ($x < $min);
	}
	return $min;
}

sub draw_list {
	my ($self, $list) = @_;	
	foreach my $rect(@$list) {
		push @{$self->{rectangles}}, $rect;
	}
}

1;

__END__

=head1 NAME

Gtk2::Ex::TreeMap - Implementation of TreeMap.

=head1 SYNOPSIS

	use Gtk2::Ex::TreeMap;
	my $treemap = Gtk2::Ex::TreeMap->new;
	my $imagesize = [600, 400];
	my $values = [6,6,4,3,2,2,1];
	$treemap->draw($imagesize, $values);
	my $window = Gtk2::Window->new;
	$window->add($treemap->get_image);
	pring Dumper $treemap->get_rectangles;
	$window->show_all;
	Gtk2->main;

=head1 DESCRIPTION

Treemap is a space-constrained visualization of hierarchical structures. 
It is very effective in showing attributes of leaf nodes using size and 
color coding. http://www.cs.umd.edu/hcil/treemap/

=head1 METHODS

=head2 Gtk2::Ex::TreeMap->new

Just a plain old constructor.

=head2 Gtk2::Ex::TreeMap->draw($size, $values)

Draws the TreeMap internally. Currently uses the B<Squarified TreeMap> algorithm.
http://www.win.tue.nl/~vanwijk/stm.pdf

=head2 Gtk2::Ex::TreeMap->get_image

Returns the TreeMap image as a Gtk2::Image wrapped in a Gtk2::EventBox

=head2 Gtk2::Ex::TreeMap->get_rectangles

Returns and array of rectangles used in the treemap.

=head1 AUTHOR

Ofey Aikon, C<< <ofey_aikon at gmail dot com> >>

=head1 ACKNOWLEDGEMENTS

To the wonderful gtk-perl list.

=head1 COPYRIGHT & LICENSE

Copyright 2004 Ofey Aikon, All Rights Reserved.

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc., 59
Temple Place - Suite 330, Boston, MA  02111-1307  USA.

=cut