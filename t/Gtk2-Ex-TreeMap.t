#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 16;

use Gtk2::Ex::TreeMap;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

my $treemap = Gtk2::Ex::TreeMap->new;
isa_ok($treemap, "Gtk2::Ex::TreeMap");
ok($treemap->draw([600,400], [6,6,4,3,2,2,1]));
ok($treemap->get_image);

$treemap = Gtk2::Ex::TreeMap->new;
ok($treemap->draw([600,400], [2,1]));
ok($treemap->get_image);

$treemap = Gtk2::Ex::TreeMap->new;
ok($treemap->draw([300,400], [6,6,4,3,2,2,1]));
ok($treemap->get_image);

$treemap = Gtk2::Ex::TreeMap->new;
ok($treemap->draw([300,400], [6,6,9,10,4,3,2,2,1]));
ok($treemap->get_image);

$treemap = Gtk2::Ex::TreeMap->new;
ok($treemap->draw([600,400], [6,6,4,3,2,2,1]));
ok($treemap->get_image);
ok($treemap->get_rectangles);
my $rectangles = $treemap->get_rectangles;
my $expect = [
          [
            0,
            0,
            300,
            200
          ],
          [
            0,
            200,
            300,
            400
          ],
          [
            300,
            0,
            471,
            233
          ],
          [
            471,
            0,
            599,
            233
          ],
          [
            300,
            233,
            420,
            400
          ],
          [
            420,
            233,
            600,
            344
          ],
          [
            420,
            344,
            600,
            400
          ]
        ];
is(Dumper($rectangles), Dumper ($expect));

$treemap = Gtk2::Ex::TreeMap->new;
ok($treemap->draw([600,400], [6,6,4,0,3,2,2,1]));
ok($treemap->get_image);
ok($treemap->get_rectangles);
