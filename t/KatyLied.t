#!/usr/bin/env perl

$usage = <<END;

usage: $0 [--help]

END

use strict;
use FindBin qw( $RealBin );
use lib "testlib", "t/testlib", "$RealBin/../lib";
use Data::Dumper;
use Test::Tools;
use WWW::AllMusicGuide;
use Getopt::Long;

use vars qw( $usage );

my ($opt_usage);

GetOptions( "help" => \$opt_usage );

if ($opt_usage) {
    print STDERR $usage;
    exit(1);
}

my $KATY_LIED_ID = "Awif2zfjhehpk";
my $KatyLied = {
    'CREDITS' => [
    {
      'ROLES' => 'Guitar',
      'ARTIST_ID' => 'B51967ui0h0j0',
      'ARTIST' => 'Rick Derringer'
    },
    {
      'ROLES' => 'Piano, Keyboards, Vocals',
      'ARTIST_ID' => 'Blyh9kett7q7x',
      'ARTIST' => 'Donald Fagen'
    },
    {
      'ROLES' => 'Vocals, Vocals (bckgr)',
      'ARTIST_ID' => 'Bt95a8q9tbt94',
      'ARTIST' => 'Michael McDonald'
    },
    {
      'ROLES' => 'Guitar',
      'ARTIST_ID' => 'Bz9x8b5m4tsqj',
      'ARTIST' => 'Larry Carlton'
    },
    {
      'ROLES' => 'Percussion, Keyboards, Vibraphone',
      'ARTIST_ID' => 'Bgm5zeflkhgfn',
      'ARTIST' => 'Victor Feldman'
    },
    {
      'ROLES' => 'Horn',
      'ARTIST_ID' => 'B995f8qxtbtc4',
      'ARTIST' => 'Bill Perkins'
    },
    {
      'ROLES' => 'Bass',
      'ARTIST_ID' => 'Bbx62mps39f8o',
      'ARTIST' => 'Chuck Rainey'
    },
    {
      'ROLES' => 'Guitar',
      'ARTIST_ID' => 'B9p6xlffe5cqy',
      'ARTIST' => 'Elliott Randall'
    },
    {
      'ROLES' => 'Bass, Guitar, Vocals',
      'ARTIST_ID' => 'B9e5h8q9tbt04',
      'ARTIST' => 'Walter Becker'
    },
    {
      'ROLES' => 'Drums',
      'ARTIST_ID' => 'B0mb1z8oajyvj',
      'ARTIST' => 'Hal Blaine'
    },
    {
      'ROLES' => 'Guitar',
      'ARTIST_ID' => 'Bwd9fs30ba3xg',
      'ARTIST' => 'Denny Diaz'
    },
    {
      'ROLES' => 'Bass',
      'ARTIST_ID' => 'B6k77gjurj6i9',
      'ARTIST' => 'Wilton Felder'
    },
    {
      'ROLES' => 'Arranger, Horn',
      'ARTIST_ID' => 'Bfnfixqe5ldte',
      'ARTIST' => 'Jimmie Haskell'
    },
    {
      'ROLES' => 'Producer',
      'ARTIST_ID' => 'Bqjdxlfae5cqq',
      'ARTIST' => 'Gary Katz'
    },
    {
      'ROLES' => 'Vocals, Vocals (bckgr)',
      'ARTIST_ID' => 'B1upyxdkb8old',
      'ARTIST' => 'Myrna Matthews'
    },
    {
      'ROLES' => 'Vocals, Vocals (bckgr)',
      'ARTIST_ID' => 'Bvx3m965odep2',
      'ARTIST' => 'Shirley Matthews'
    },
    {
      'ROLES' => 'Guitar',
      'ARTIST_ID' => 'Bwisxlfhegcqe',
      'ARTIST' => 'Hugh McCracken'
    },
    {
      'ROLES' => 'Engineer',
      'ARTIST_ID' => 'B17d8vwdta9lk',
      'ARTIST' => 'Roger Nichols'
    },
    {
      'ROLES' => 'Piano, Keyboards',
      'ARTIST_ID' => 'Btln8b5f4bsqs',
      'ARTIST' => 'Michael Omartian'
    },
    {
      'ROLES' => 'Piano, Keyboards',
      'ARTIST_ID' => 'B5jd6vwvta92k',
      'ARTIST' => 'David Paich'
    },
    {
      'ROLES' => 'Drums, Dorophone',
      'ARTIST_ID' => 'B46jveae14xa7',
      'ARTIST' => 'Jeff Porcaro'
    },
    {
      'ROLES' => 'Guitar',
      'ARTIST_ID' => 'Bai6zefik7gfj',
      'ARTIST' => 'Dean Parks'
    },
    {
      'ROLES' => 'Vocals, Vocals (bckgr)',
      'ARTIST_ID' => 'Bqmouak4kgm3b',
      'ARTIST' => 'Carolyn Willis'
    },
    {
      'ROLES' => 'Horn, Vocals',
      'ARTIST_ID' => 'B48juea114xd7',
      'ARTIST' => 'Phil Woods'
    },
    {
      'ROLES' => 'Guitar',
      'ARTIST_ID' => 'B6g47gjqr86im',
      'ARTIST' => 'Denny Dias'
    },
    {
      'ROLES' => 'Sound Consultant',
      'ARTIST_ID' => 'B57jyeat24x07',
      'ARTIST' => 'Dinky Dawson'
    },
    {
      'ROLES' => 'Consultant',
      'ARTIST_ID' => 'Boi68mp9g9f5o',
      'ARTIST' => 'Daniel Levitin'
    }
  ],
  'TIME' => '34:56',
  'TONES' => [
    'Cynical/Sarcastic',
    'Wry',
    'Sophisticated',
    'Cerebral',
    'Literate',
    'Quirky',
    'Laid-Back/Mellow',
    'Witty',
    'Refined/Mannered',
    'Bittersweet',
    'Freewheeling'
  ],
  'ARTIST_ID' => 'B3tkzu3u5an8k',
  'ARTIST' => 'Steely Dan',
  'GENRE' => [
    'Rock'
  ],
  'RELEASE_DATE' => '1975',
  'COVER_URL' => 'http://image.allmusic.com/00/amg/cov200/drd400/d475/d475151mt9i.jpg',
  'TRACKS' => [
    {
      'NUMBER' => '1',
      'NAME' => 'Black Friday',
      'LENGTH' => '3:33',
      'CREDIT' => 'Becker/Fagen'
    },
    {
      'NUMBER' => '2',
      'NAME' => 'Bad Sneakers',
      'LENGTH' => '3:16',
      'CREDIT' => 'Becker/Fagen'
    },
    {
      'NUMBER' => '3',
      'NAME' => 'Rose Darling',
      'LENGTH' => '2:59',
      'CREDIT' => 'Becker/Fagen'
    },
    {
      'NUMBER' => '4',
      'NAME' => 'Daddy Don\'t Live in That New York City No...',
      'LENGTH' => '3:12',
      'CREDIT' => 'Becker/Fagen'
    },
    {
      'NUMBER' => '5',
      'NAME' => 'Doctor Wu',
      'LENGTH' => '3:59',
      'CREDIT' => 'Becker/Fagen'
    },
    {
      'NUMBER' => '6',
      'NAME' => 'Everyone\'s Gone to the Movies',
      'LENGTH' => '3:41',
      'CREDIT' => 'Becker/Fagen'
    },
    {
      'NUMBER' => '7',
      'NAME' => 'Your Gold Teeth II',
      'LENGTH' => '4:12',
      'CREDIT' => 'Becker/Fagen'
    },
    {
      'NUMBER' => '8',
      'NAME' => 'Chain Lightning',
      'LENGTH' => '2:57',
      'CREDIT' => 'Becker/Fagen'
    },
    {
      'NUMBER' => '9',
      'NAME' => 'Any World (That I\'m Welcome To)',
      'LENGTH' => '3:56',
      'CREDIT' => 'Becker/Fagen'
    },
    {
      'NUMBER' => '10',
      'NAME' => 'Throw Back the Little Ones',
      'LENGTH' => '3:11',
      'CREDIT' => 'Becker/Fagen'
    }
  ],
  'AMG_RATING' => '5',
  'INPRINT' => 1,
  'MARC_ID' => 'V18946',
  'STYLES' => [
    'Soft Rock',
    'Pop/Rock',
    'Jazz-Rock',
    'Album Rock'
  ],
  'ALBUM_TITLE' => 'Katy Lied'
};


sub make_album_tests
{
    my ($album) = @_;

    my @album_tests;

    foreach my $key (qw( ARTIST ALBUM_TITLE TIME GENRE TONES RELEASE_DATE
                         AMG_RATING STYLES INPRINT MARC_ID )) {
        push @album_tests, [ $key, 
                             ref($album->{ $key }) eq "ARRAY" ? "list" : "scalar",
                             "eq",
                             $album->{ $key } ];
    }

    return \@album_tests;
}

my $amg = new WWW::AllMusicGuide(-progress => undef,
                                 -dump => undef);

my $results = $amg->lookup_object($KATY_LIED_ID);

#print Dumper($results);

my $num_tests = 1 + scalar(@{$results->{ "TRACKS" }});

print "1..$num_tests\n";

my $katy_lied_tests = make_album_tests($KatyLied);
test_hash $results, $katy_lied_tests;

for (my $i=0; $i<scalar @{$results->{ "TRACKS" }}; $i++) {
    my $track = $results->{ "TRACKS" }[$i];
    my @track_tests;
    foreach my $key (keys %{$KatyLied->{ "TRACKS" }[$i]}) {
        push @track_tests, [ $key, "scalar", "eq", $KatyLied->{ "TRACKS" }[$i]{$key} ];
    }
    test_hash $track, \@track_tests;
}

# FIXME - Need test for credits

sub DESTROY
{
}

exit 0;

