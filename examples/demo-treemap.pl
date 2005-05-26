use strict;
use warnings;
use Data::Dumper;

use Gtk2 -init;
use Glib qw /TRUE FALSE/;

use Gtk2::Ex::TreeMap;

my $treemap = Gtk2::Ex::TreeMap->new;

my $imagesize = [600, 400];
my $values = [6,6,4,3,2,2,1];

$treemap->draw($imagesize, $values);
my $window = Gtk2::Window->new;
$window->signal_connect(destroy => sub { Gtk2->main_quit; });
$window->add($treemap->get_image);
$window->show_all;
Gtk2->main;
