=head1 NAME

WWW::AllMusicGuide - An object to search the All Music Guide (www.allmusic.com)

=head1 SYNOPSIS

 use WWW::AllMusicGuide;

 my $amg = new WWW::AllMusicGuide();
 my $result = $amg->search_artist(-name => "The Beatles");

 if (ref($result) eq "ARRAY") {
    # process search results
 } else {
    # process parsed artist information
 }

 $result = $amg->search_album(-name => "Abbey Road");
 $result = $amg->lookup_object($object_id);

=head1 DESCRIPTION

The WWW::AllMusicGuide module provides an object that you can use to search 
the All Music Guide (http://www.allmusic.com).  Currently, you can search 
for artists and albums.  Artist and album pages are parsed into hash references
containing the information (e.g. name, year, group members, etc).  This 
information is useful in writing tools to maintain large collections of MP3
files, their ID3 tags and metadata.

NOTE: (from the website)

"The All Music Guide is protected by a unique data fingerprinting process to 
insure that the data and its format can be identified.  This data cannot be
distributed in any form without the express written permission of the AEC
One Stop Group, Inc."

=head1 METHODS

=head2 new

 new %params

Creates a WWW::AllMusicGuide object.  The following parameters are recognized:

  -progress => File handle on which to send progress messages
  -url      => URL of the All Music Guide (defaults to
               "http://www.allmusic.com"). Useful for testing 
               to redirect traffic to a local server so you can
               see what\'s going on.
  -agent    => User agent string to send in requests (defaults to
               "Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.0)")

=head2 search_artist

 search_artist %params

Searches for an artist matching the specified parameters.  Valid parameters:

  -name  => The name of the artist as typed into the AMG search box.
  -id    => Find the artist with the specified AMG id.
  -auto  => Automatically select a likely match (if possible) when
            multiple search results are returned.

You must specify one of -name or -id.  AMG id\'s are obtained in the return
values for many methods.  The return value is either a hash reference
containing artist info OR a list reference containing search results.
See L<"RETURN VALUES"> below for more info.

If -auto is specified, search results will be analyzed and if a reasonable
guess can be made as to what was intended, the method will automatically
navigate to that artist page.  The algorithm is simple:

  * If there is only one artist that is highlighted in the search 
    results, that is the likely match.
  * If there is more than one highlighted artist in the search results 
    and one of them case-insensitively matches the passed-in -name use 
    the matching one.
  * Otherwise return search results.

=head2 search_album

 search_album %params

Searches for an album matching the specified parameters.  Valid parameters:

  -name  => The name of the album as typed into the AMG search box.
  -id    => Find the album with the specified AMG id.

You must specify one of -name or -id.  AMG id\'s are obtained in the return 
values for many methods.  The return value is either a hash reference 
containing album info OR a list reference containing search results.
See L<"RETURN VALUES"> below for more info.

=head1 RETURN VALUES

In general data is returned in hash references with ALLCAPS keys.  Search
results are returned as list references containing a hash reference describing
each search result.  Most keys are optional and values are strings unless 
otherwise specified.  The format for date strings varies.

=head2 Artist Info (hashref)

Contains the following keys:

  FORMED_DATE, FORMED_LOCATION, DISBANDED_DATE, DISBANDED_LOCATION 
  BORN_DATE, BORN_LOCATION, DIED_DATE, DIED_LOCATION

  YEARS_ACTIVE  (listref, e.g. [ '70s', '80s', '90s' ])

  MEMBERS       (listref of hashrefs) example:
                [{'NAME' => 'Donald Fagen', 'ARTIST_ID' => 'Bjgjyeat04'},
                 {'NAME' => 'Walter Becker', 'ARTIST_ID' => 'B9pec97l7k'}]

  GENRES          (listref, e.g. [ 'ROCK' ])
  STYLES          (listref, e.g. [ 'Album Rock', 'Jazz-Rock' ])
  LABELS          (listref, e.g. [ 'MCA', 'Magnum', 'Giant' ])
  TONES           (listref, e.g. [ 'Irreverent', 'Humorous', 'Snide' ]
  INSTRUMENTS     (listref, e.g. [ 'Vocals','Keyboards', 'Synthesizer' ]

  DISCOGRAPHY     (listref of hashrefs)  

  In the discography, each album/single/compilation is represented as a 
  hash reference with the following keys:

    YEAR
    ALBUM_ID
    AMG_RATING  (number of stars)
    AMG_PICK    (0/1)
    LABEL
    TYPE        (album/boxset/compilation/ep/single/bootleg/video)
    IN_PRINT    (0/1)
    TITLE       Name of the album/single/etc.

=head2 Album Info (hashref)

Each Album Info hashref may contain the following keys:

  ARTIST, ARTIST_ID, ALBUM_TITLE, INPRINT, RELEASE_DATE, AMG_RATING, 
  MARC_ID, TIME,

  GENRE   (listref, e.g. [ 'Rock' ])
  STYLES  (listref, e.g. [ 'Jazz-Rock', 'Pop/Rock' ])
  TONES   (listref, e.g. [ 'Lush', 'Refined/Mannered' ])

  TRACKS  (listref of hashrefs)

    Each track hashref may contain the following keys:

    NAME      The track name
    NUMBER    The position of the track in the album
    AMG_PICK  (0/1)
    CREDIT    Songwriting credit

  CREDITS (listref of hashrefs)

    Each credit hashref may contain the following keys: 

    ARTIST
    ARTIST_ID
    ROLES  (comma-separated list of roles, e.g.
            "Sax (Baritone), Sax (Tenor)")

=head2 Artist Search Results (list reference)

Documentation not written yet.  Use Data::Dumper to see result structure.

=head2 Album Search Results (list reference)

Documentation not written yet.  Use Data::Dumper to see result structure.

=head1 AUTHOR

Mohamed Hendawi (moe AT hendawi DOT com)

=head1 WARNING

The API and format of structures may change between subsequent versions.

=head1 COPYRIGHT

Copyright (c) 2002 Mohamed Hendawi. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

package WWW::AllMusicGuide;

no strict 'vars';

require Exporter;

@ISA       = qw( Exporter );
@EXPORT    = qw();
@EXPORT_OK = qw();

$VERSION = "0.03";

use strict;
use Carp;
use File::Basename;
use File::Path;
use File::Spec;
use Data::Dumper;
use HTML::TreeBuilder;
use LWP::Simple;
use HTTP::Request;
use HTTP::Response;

# ----- ALBUM PAGE -----------------------------------------------------------
#
# The following defines are used in parsing the AMG album page.
#
# $TRACKS_IMG - "Songs/Tracks" image that identifies table containing tracks
# $TRACK_LIST_ROW_CLASS - Rows of table containing tracks have this class.

my $TRACKS_IMG = '/img/htrk1.gif';
my $TRACK_LIST_ROW_CLASS = 'co1';

# $CREDITS_IMG - "Credits" images that identifies table containing credits
# $CREDITS_ROW_CLASS - Rows of table containing album credits have this class.

my $CREDITS_IMG       = '/img/hcred1.gif';
my $CREDITS_ROW_CLASS = 'co1';

# ----- ALBUM SEARCH RESULTS -------------------------------------------------
#
# To identify an album search results page we look for a special sentinel <th>
# cell that has $ALBUM_RESULTS_HEADER_BG as a background and 
# $ALBUM_RESULTS_SENTINEL as text content.

my $ALBUM_RESULTS_HEADER_BG = '/img/bgr02.gif';
my $ALBUM_RESULTS_SENTINEL  = 'AMG Rating';
my $ALBUM_RESULTS_ROW_CLASS = 'co1';

# ----- ARTIST SEARCH RESULTS -------------------------------------------------
#
# To identify an artist search results page we look for a special sentinel <td>
# cell that has $ARTIST_RESULTS_HEADER_BG as a background and regex matches
# $ARTIST_RESULTS_SENTINEL as text content.  $ARTIST_RESULTS_LIKELY_CLASS
# indicates the class of rows that indicate a "likely match" as determined
# by the AMG search engine.

my $ARTIST_RESULTS_HEADER_BG    = '/img/bgr02.gif';
my $ARTIST_RESULTS_SENTINEL     = 'NAMES STARTING WITH';
my $ARTIST_RESULTS_LIKELY_CLASS = 'co4';


my $FEATURED_ALBUMS_BG = '/img/bgr01.jpg';
my $SEARCH_BUTTON_IMG  = 'img/mus_3.gif';
my $DISCO_ALBUMS_IMG   = '/img/hdisc11.gif';
my $DISCO_COMPS_IMG    = '/img/hdisc21.gif';
my $DISCO_EPS_IMG      = '/img/hdisc31.gif';
my $DISCO_BOOTLEGS_IMG = '/img/hdisc41.gif';
my $NOT_AMG_PICK_IMG   = '/img/nopick.gif';
my $YES_AMG_PICK_IMG   = '/img/pick.gif';
my $RATING_0           = '/img/rt0.gif';
my $RATING_0a          = '/img/st_r0.gif';
my $RATING_1           = '/img/rt1.gif';
my $RATING_1a          = '/img/st_r1.gif';
my $RATING_2           = '/img/rt2.gif';
my $RATING_2a          = '/img/st_r2.gif';
my $RATING_3           = '/img/rt3.gif';
my $RATING_3a          = '/img/st_r3.gif';
my $RATING_4           = '/img/rt4.gif';
my $RATING_4a          = '/img/st_r4.gif';
my $RATING_5           = '/img/rt5.gif';
my $RATING_5a          = '/img/st_r5.gif';
my $RATING_6           = '/img/rt6.gif';
my $RATING_6a          = '/img/st_r6.gif';
my $RATING_7           = '/img/rt7.gif';
my $RATING_7a          = '/img/st_r7.gif';
my $RATING_8           = '/img/rt8.gif';
my $RATING_8a          = '/img/st_r8.gif';
my $RATING_9           = '/img/rt9.gif';
my $RATING_9a          = '/img/st_r9.gif';

my $NOT_IN_PRINT_IMG   = '/img/av0.gif';
my $IN_PRINT_IMG       = '/img/av1.gif';
my $MORE_INFO_IMG      = '/img/continue2.jpg';


my %Images = ( $NOT_AMG_PICK_IMG => [ "AMG_PICK", 0 ],
               $YES_AMG_PICK_IMG => [ "AMG_PICK", 1 ],
               $RATING_0         => [ "AMG_RATING", 0.0 ],
               $RATING_0a        => [ "AMG_RATING", 0.0 ],
               $RATING_1         => [ "AMG_RATING", 0.5 ],
               $RATING_1a        => [ "AMG_RATING", 0.5 ],
               $RATING_2         => [ "AMG_RATING", 1.0 ],
               $RATING_2a        => [ "AMG_RATING", 1.0 ],
               $RATING_3         => [ "AMG_RATING", 1.5 ],
               $RATING_3a        => [ "AMG_RATING", 1.5 ],
               $RATING_4         => [ "AMG_RATING", 2.0 ],
               $RATING_4a        => [ "AMG_RATING", 2.0 ],
               $RATING_5         => [ "AMG_RATING", 2.5 ],
               $RATING_5a        => [ "AMG_RATING", 2.5 ],
               $RATING_6         => [ "AMG_RATING", 3.0 ],
               $RATING_6a        => [ "AMG_RATING", 3.0 ],
               $RATING_7         => [ "AMG_RATING", 4.0 ],
               $RATING_7a        => [ "AMG_RATING", 4.0 ],
               $RATING_8         => [ "AMG_RATING", 4.5 ],
               $RATING_8a        => [ "AMG_RATING", 4.5 ],
               $RATING_9         => [ "AMG_RATING", 5.0 ],
               $RATING_9a        => [ "AMG_RATING", 5.0 ],
               $IN_PRINT_IMG     => [ "IN_PRINT", 1 ],
               $NOT_IN_PRINT_IMG => [ "IN_PRINT", 0 ],
             );

my $Def_Agent_Str    = "Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.0)";

sub new
{
    my ($class, %params) = @_;

    my $browser_log_fn = $params{ '-browser_log'  };
    my $agent_str      = $params{ '-agent'        } || $Def_Agent_Str;
    my $url            = $params{ '-url'          } || "http://www.allmusic.com";
    my $progress_fh    = $params{ '-progress'     };
    my $cache_dir      = $params{ '-cache_dir'    };
    my $expire_cache   = $params{ '-expire_cache' };
    my $save_covers    = $params{ '-save_covers'  };
    my $dump_flags     = $params{ '-dump'         };
    
    my $browser = new Browser(-log          => $browser_log_fn,
                              -agent        => $agent_str,
                              -cache_dir    => $cache_dir,
                              -expire_cache => $expire_cache,
                              -progress     => $progress_fh,
                              );

    my $self = { 'browser'      => $browser,
                 'amg_base_url' => $url,
                 'progress_fh'  => $progress_fh,
                 'save_covers'  => $save_covers,
             };

    if (ref($dump_flags) eq "ARRAY") {
        $self->{ "dump_flags" } = { map { $_, 1 } @{$dump_flags} };
    } elsif ($dump_flags) {
        $self->{ "dump_flags" } = { map { $_, 1 } split(/\s*,\s*/, $dump_flags) };
    }

    bless $self, $class;

    return $self;
}


sub search_artist
{
    my ($self, %params) = @_;

    my $name = $params{ '-name' };
    my $id   = $params{ '-id'   };
    my $auto = $params{ '-auto' };

    if (!$name && !$id) {
        croak "Must specify one of -name or -id\n";
    }

    my $browser = $self->browser;
    my $response;

    if ($name) {

        $self->navigate_amg_home();

        $self->progress("Searching for artist...");
        $browser->fillin('sql', $name);
        $response = $browser->press(-src => $SEARCH_BUTTON_IMG);
        $self->progress("ok\n");

    } elsif ($id) {

        $response = $self->navigate_to_object_page($id, "Loading artist page");

    }

#    $browser->tree->dump();

    my $search_results = $self->parse_artist_search_results(-tree => $browser->tree);

    if (@$search_results) {

        if (@$search_results > 1) {
            $self->progress(@$search_results . " search results found\n");
        }

        my $result = $self->analyze_artist_search_results(-desired_name => $name,
                                                          -search_results => $search_results);

        if ($result && $auto) {
            if (@$search_results > 1) {
                $self->progress("Automatically selecting likely match.\n");
            }
            $response = $self->navigate_to_object_page($result->{ "ARTIST_ID" },
                                                      "Loading artist page");
        } else {
            return $search_results;
        }
    }

    # Our browser is looking at an artist page now.  If the artist page has a
    # link to "read more", it means that some of the data for the artist is not
    # displayed.  Follow that link so we get all the data.

    my $more_info_img = $browser->tree->look_down('_tag', 'img',
                                                  'src',  $MORE_INFO_IMG);
    if ($more_info_img) {
        my $link = $more_info_img->look_up('_tag', 'a');
        if ($link) {
            my $artist_id = extract_object_id($link->attr('href'));
            if ($artist_id !~ m/^R/) {
                $response = $self->navigate_to_object_page($artist_id,
                                                           "Getting complete artist info");
            }
        }
    }

    # Now we know we have an artist page with full data displayed.  
    # Parse it and return the parsed hash.

    my $content = $response->content();
    my $artist_info = $self->parse_artist_page(-html => $content);
    return $artist_info;
}



sub search_album
{
    my ($self, %params) = @_;

    my $name = $params{ '-name' };
    my $id   = $params{ '-id'   };

    if (!$name && !$id) {
        croak "Must specify one of -name or -id\n";
    }

    my $browser = $self->browser;
    my $response;

    if ($name) {

        $self->navigate_amg_home();

        $self->progress("searching for album...");
        $browser->fillin('sql', $name);

        $browser->set_radio_button("opt1", 2);

        $response = $browser->press(-src => $SEARCH_BUTTON_IMG);
        $self->progress("ok\n");

    } elsif ($id) {

        $response = $self->navigate_to_object_page($id, "Loading album page");

    }

    my $search_results = $self->parse_album_search_results(-tree => $browser->tree);

    if (@$search_results == 1 && exists($search_results->[0]->{ "ALBUM_ID" })) {
        $response = $self->navigate_to_object_page($search_results->[0]->{ "ALBUM_ID" },
                                                   "Loading album page");
    } elsif (@$search_results) {
        return $search_results;
    } else {
        return $self->parse_album_page(-html => $response->content());
    }
}



sub parse_artist_page
{
    my ($self, %params) = @_;

    my $html = $params{ '-html' };
    my $dump = $params{ '-dump' };

    $self->progress("Parsing artist info...");

    my $artist = {};

    my $tb = $self->new_tree_builder($html, $self->dump( "artists" ));

    my @elem_keys = $tb->look_down('_tag', 'td',
                                   'class', 'co3');

    foreach my $elem_key (@elem_keys) {
        my $elem_val = $elem_key->right();
        my $key = strip($elem_key->as_text());
        my $val = strip($elem_val->as_text());

        if ($key =~ m/formed/i) {

            if ($val =~ m/^(.*?)\s+in\s+(.*)$/i) {
                $artist->{ "FORMED_DATE"     } = $1;
                $artist->{ "FORMED_LOCATION" } = $2;
            } else {
                $artist->{ "FORMED_DATE" } = $val;
            }

        } elsif ($key =~ m/disbanded/i) {

            if ($val =~ m/^(.*?)\s+in\s+(.*)$/i) {
                $artist->{ "DISBANDED_DATE"     } = $1;
                $artist->{ "DISBANDED_LOCATION" } = $2;
            } else {
                $artist->{ "DISBANDED_DATE" } = $val;
            }

        } elsif ($key =~ m/born/i) {

            if ($val =~ m/^(.*?)\s+in\s+(.*)$/i) {
                $artist->{ "BORN_DATE"     } = $1;
                $artist->{ "BORN_LOCATION" } = $2;
            } else {
                $artist->{ "BORN_DATE" } = $val;
            }

        } elsif ($key =~ m/died/i) {

            if ($val =~ m/^(.*?)\s+in\s+(.*)$/i) {
                $artist->{ "DIED_DATE"     } = $1;
                $artist->{ "DIED_LOCATION" } = $2;
            } else {
                $artist->{ "DIED_DATE" } = $val;
            }

        } elsif ($key =~ m/years active/i) {

            my @images = $elem_val->look_down('_tag', 'img');
            my @decades;
            foreach my $img (@images) {
                if ($img->attr('src') =~ m/dec(\d)x.gif/i) {
                    push @decades, "${1}0s";
                }
            }

            $artist->{ "YEARS_ACTIVE" } = \@decades;

        } elsif ($key =~ m/group members/i) {

            my @links = $elem_val->look_down('_tag', 'a');

            my @members;
            foreach my $link (@links) {
                push @members, { 'NAME' => $link->as_text(), 
                                 'ARTIST_ID' => extract_object_id($link->attr('href')) };
            }

            $artist->{ "MEMBERS" } = \@members;

        } elsif ($key =~ m/genres/i) {

            $artist->{ "GENRES" } = parse_links_text($elem_val);

        } elsif ($key =~ m/styles/i) {

            $artist->{ "STYLES" } = parse_links_text($elem_val);

        } elsif ($key =~ m/tones/i) {

            $artist->{ "TONES" } = [ split(/\s*,\s*/, $val) ];

        } elsif ($key =~ m/labels/i) {

            $artist->{ "LABELS" } = parse_links_text($elem_val);

        } elsif ($key =~ m/instruments/i) {

            $artist->{ "INSTRUMENTS" } = [ split(/\s*,\s*/, $val) ];

        }
    }

    $self->progress("ok\n"); # done parsing artist info

    # Parsing discography

    $self->progress("Parsing discography...");
    $self->parse_discography($html, $artist);
    $self->progress("ok\n");

    return $artist;
}


sub parse_album_page
{
    my ($self, %params) = @_;

    my $html = $params{ "-html" };

    $self->progress("parsing album info...");

    my $album = {};

    my $tb = $self->new_tree_builder($html, $self->dump( "albums" ));

    my @elem_keys = $tb->look_down('_tag', 'td',
                                   'class', 'co3');

    foreach my $elem_key (@elem_keys) {
        my $elem_val = $elem_key->right();
        my $key = strip($elem_key->as_text());
        my $val = strip($elem_val->as_text());

        if ($key =~ m/artist/i) {

            $album->{ "ARTIST" } = $val;

            if (my $link = $elem_val->look_down('_tag', 'a')) {
                $album->{ "ARTIST_ID" } = extract_object_id($link->attr('href'));
            }

        } elsif ($key =~ m/album title/i) {

            $album->{ "ALBUM_TITLE" } = $val;

        } elsif ($key =~ m/date of release/i) {

            $album->{ "INPRINT" } = ($val =~ s/inprint//i) ? 1 : 0;

            $val =~ s/\(release\)//i;

            $album->{ "RELEASE_DATE" } = strip($val);

        } elsif ($key =~ m/rating/i) {

            $self->parse_images($elem_val, $album);

        } elsif ($key =~ m/genre/i) {

            $album->{ "GENRE" } = parse_links_text($elem_val);

        } elsif ($key =~ m/tones/i) {

            $album->{ "TONES" } = [ split(/\s*,\s*/, $val) ];

        } elsif ($key =~ m/styles/i) {

            $album->{ "STYLES" } = parse_links_text($elem_val);

        } elsif ($key =~ m/time/i) {

            $album->{ "TIME" } = $val;

        } elsif ($key =~ m/library view/i) {

            my $link = $elem_val->look_down('_tag', 'a');
            if ($link) {
                $album->{ "MARC_ID" } = extract_object_id($link->attr('href'));
            }
        }
    }

    $self->progress("ok\n"); # done parsing album info

    $self->parse_album_tracks($tb, $album);
    $self->parse_album_credits($tb, $album);
    $self->parse_album_cover($tb, $album);

    return $album;
}


# ==============================================================================
# PRIVATE METHODS
# ==============================================================================

sub parse_artist_search_results
{
    my ($self, %params) = @_;

    my $tree = $params{ '-tree' } || croak "Must specify -tree\n";
    my $desired_name = $params{ '-desired_name' };

    my $elem = $tree->look_down('_tag', 'td',
                                'background', $ARTIST_RESULTS_HEADER_BG,
                                sub { $_[0]->as_text() =~ /$ARTIST_RESULTS_SENTINEL/ });

    my @search_results;
    if ($elem) {
        my $table = $elem->look_up('_tag', 'table');

        foreach my $table_row ($table->look_down('_tag', 'tr')) {
            next if ($table_row->as_text() =~ /$ARTIST_RESULTS_SENTINEL/);

            my @cells = $table_row->look_down('_tag', 'td');
            my ($artist, $genre, $decades) = @cells;

            my $artist_name = strip($artist->as_text());
            my $link        = $artist->look_down('_tag', 'a');
            my $artist_id   = extract_object_id($link->attr('href')) if ($link);

            my $record;

            $record->{ 'ARTIST'    } = $artist_name;
            $record->{ 'ARTIST_ID' } = $artist_id;
            $record->{ 'GENRE'     } = strip($genre->as_text());
            $record->{ 'DECADES'   } = strip($decades->as_text());

            $record->{ 'LIKELY_MATCH' } = 
                ($table_row->attr('class') eq $ARTIST_RESULTS_LIKELY_CLASS) ? 1 : 0;

            if (lc($artist_name) eq lc($desired_name)) {
                return ( $record );
            } else {
                push @search_results, $record;
            }
        }
    }

    return \@search_results;
}


sub parse_album_search_results
{
    my ($self, %params) = @_;

    my $tree = $params{ '-tree' } || croak 'Must specify -tree\n';

    my $elem = $tree->look_down('_tag', 'th',
                                'background', $ALBUM_RESULTS_HEADER_BG,
                                sub { $_[0]->as_text() =~ /$ALBUM_RESULTS_SENTINEL/ });

    my @search_results;
    if ($elem) {
        my $table = $elem->look_up('_tag', 'table');

        my @results;
        foreach my $table_row ($table->look_down('_tag', 'tr', 
                                                 'class', $ALBUM_RESULTS_ROW_CLASS)) {
            my @cells = $table_row->look_down('_tag', 'td');
            my ($rating, $artist, $title, $year, $genre) = @cells;

            my $record;

            $self->parse_images($rating, $record);
            $record->{ 'ARTIST' } = strip($artist->as_text());
            $record->{ 'ALBUM_TITLE' } = strip($title->as_text());

            my $link = $title->look_down('_tag', 'a');
            if ($link) {
                $record->{ 'ALBUM_ID' } = extract_object_id($link->attr('href'));
            }

            $record->{ 'YEAR' } = strip($year->as_text());
            $record->{ 'GENRE' } = strip($genre->as_text());

            push @search_results, $record;
        }
    }

    return \@search_results;
}


# Parses the discography on an artist page and sets the 'discography' key
# in the $artist hash that is passed in.  The discography key is a list of
# of hash references representing albums/discs/singles etc.  Each hash 
# reference may contain the following keys:
#
# TITLE -
# TYPE -
# ID  - 
# YEAR -
# AMG_PICK - 
# AMG_RATING - 
# IN_PRINT - 
#
# Within the artist page HTML, the discography is contained within 4 distinct 
# sections that I've identified so far - albums, compilations and boxsets, eps 
# and singles, and bootlegs/videos.  The content for each of these sections is 
# contained in a table and is preceded by another table containing an image for 
# each section.  We use these images to identify the sections.  The actual 
# tables of data are 5-6 columns:
# 
# 1. AMG_PICK (image), Rating (image)
# 2. Year (text), In Print (image)
# 3. Title (text/link)
# 4. BUY (image/link)
# 5. Label (text/optional link)
# 6. Type (single character) - this column does not appear in albums table

sub parse_discography
{
    my ($self, $html, $artist) = @_;

    # Make sure the HTML contains one of our recognized discography sections
    # and extract part of the HTML from the first table containing a discography
    # image and on.

    if ($html =~ m/($DISCO_ALBUMS_IMG|$DISCO_COMPS_IMG|$DISCO_EPS_IMG|$DISCO_BOOTLEGS_IMG)/g) {
        my $begin_disco_tables = rindex($html, '<table', pos($html));
        $html = substr($html, $begin_disco_tables);
    } else {
        $artist->{ 'discography' } = [];
        return;
    }

    # Parse the HTML into a tree, and then extract all of the tables.  The first
    # table should contain one of the discography images now.  We look through
    # all the tables, and assemble a list of the discography data tables that
    # we are going to parse.  For each table we are going to parse, store the
    # the type of table it is (albums,compilations,eps,etc) in the 'DISCO_TYPE'
    # field so we can use it later on to interpret our parsed data.

    my $tb = new HTML::TreeBuilder();
    $tb->parse($html);

    my @tables = $tb->look_down('_tag', 'table');
    my @tables_to_parse;

    my @DISCO_TYPES = ( $DISCO_ALBUMS_IMG, $DISCO_COMPS_IMG, $DISCO_EPS_IMG, $DISCO_BOOTLEGS_IMG);

    my $table;
    while (@tables) {
        $table = shift @tables;

        foreach my $disco_type (@DISCO_TYPES) {
            if ($table->look_down('_tag', 'img', 'src', $disco_type)) {
                $table = shift @tables;

                # Sometimes the albums list will be preceded by another table
                # containing album cover links to featured albums.  We ignore
                # this table if we recognize it by it's table background.

                if (($disco_type eq $DISCO_ALBUMS_IMG) && 
                    ($table->attr('background') eq $FEATURED_ALBUMS_BG)) {
                    $table = shift @tables;
                }

                $table->{ 'DISCO_TYPE' } = $disco_type;
                push @tables_to_parse, $table;
                last;
            }
        }
    }

    # Now loop through tables and parse out the data, adding records
    # to the array @discography.  At the end of the process we'll have all
    # of the discography data parsed 

    my @discography;
    foreach my $table (@tables_to_parse) {
        my $disco_type = $table->{ 'DISCO_TYPE' };

        foreach my $table_row ($table->look_down('_tag', 'tr')) {
            my @cells = $table_row->look_down('_tag', 'td');
            next if (@cells < 5);

            my $record = {};

            # First cell - AMG Pick, Rating

            my $cell = shift @cells;
            $self->parse_images($cell, $record);

            # Second cell - Year, In Print

            $cell = shift @cells;
            $self->parse_images($cell, $record);
            $record->{ 'YEAR' } = strip($cell->as_text());

            # Third cell - Album title, link

            $cell = shift @cells;
            my $link = $cell->look_down('_tag', 'a');
            if ($link) {
                $record->{ 'TITLE'    } = $link->as_text();
                $record->{ 'ALBUM_ID' } = extract_object_id($link->attr('href'));
            }

            # Fourth cell - BUY from CDNOW link (IGNORE THIS)
            $cell = shift @cells;

            # Fifth cell - Label

            $cell = shift @cells;
            $record->{ 'LABEL' } = strip($cell->as_text());

            # Sixth cell - (optional) type (e.g. album, single, ep, box set, etc)

            $cell = shift @cells;

            if ($cell) {
                my $amg_type = strip($cell->as_text());

                if ($disco_type eq $DISCO_COMPS_IMG) {
                    if ($amg_type eq 'x') {
                        $record->{ 'TYPE' } = 'boxset';
                    } elsif (!$amg_type) {
                        $record->{ 'TYPE' } = 'compilation';
                    }
                } elsif ($disco_type eq $DISCO_EPS_IMG) {
                    if (!$amg_type) {
                        $record->{ 'TYPE' } = 'ep';
                    } elsif ($amg_type eq 's') {
                        $record->{ 'TYPE' } = 'single';
                    }
                } elsif ($disco_type eq $DISCO_BOOTLEGS_IMG) {
                    if ($amg_type eq 'b' || !$amg_type) {
                        $record->{ 'TYPE' } = 'bootleg';
                    } elsif ($amg_type eq 'v') {
                        $record->{ 'TYPE' } = 'video';
                    }
                } elsif ($disco_type eq $DISCO_ALBUMS_IMG) {
                    $record->{ 'TYPE' } = 'album';
                }
            } else {
                $record->{ 'TYPE' } = 'album';

            }

            push @discography, $record;
        }
    }

    $artist->{ 'DISCOGRAPHY' } = \@discography;

}


sub parse_album_tracks
{
    my ($self, $tb, $album) = @_;

    my $img = $tb->look_down('_tag', 'img',
                             'src', $TRACKS_IMG);

    return unless ($img);

    my $table = $img->look_up('_tag', 'table');

    if (!$table) {

        croak <<END;

Found image $TRACKS_IMG identifying table containing tracks in the album page.
However, I could not find the containing table tag.  This probably means that
the structure of the AMG album page has changed and the parsing code will need
to be updated to reflect the changes.

END
    ; 

    }

    my @tracks;
    foreach my $table_row ($table->look_down('_tag', 'tr', 
                                             'class', $TRACK_LIST_ROW_CLASS)) {
        my @cells = $table_row->look_down('_tag', 'td');
        next if (@cells < 5);
        
        if (@cells > 6) {
            $table_row = $table_row->look_down('_tag', 'td')->look_down('_tag', 'tr');
            @cells = $table_row->look_down('_tag', 'td');
        }
        
        # XXX: DEBUG
        # print "CELLS is ",scalar @cells,"\n";
        # print $table_row->as_HTML(undef, "\t"),"-"x78,"\n";

        splice(@cells,2,1) if @cells == 6; # kill extra spacer

        my $track = {};

        # First cell - Link to AMG review

        my $cell = shift @cells;
        if ($cell->as_text() =~ m/review/i) {
            my $link = $cell->look_down('_tag', 'a');
            $track->{ 'REVIEW_ID' } = extract_object_id($link->attr('href'));
        } else { # maybe pick/nopick
            $self->parse_images($cell, $track);
        }

        # Second cell - AMG Pick

        $cell = shift @cells;
        $self->parse_images($cell, $track);

        # Third cell - Track Number

        $cell = shift @cells;
        if ($cell->as_text() =~ m/(\d+)\./) {
            $track->{ 'NUMBER' } = $1;
        }

        # Fourth cell - IGNORE (spacer??)
        $cell = shift @cells;

        # Fifth cell - Label

        $cell = shift @cells;
        my $trackinfo = strip($cell->as_text());
        if ($trackinfo =~ s/\s*-?\s*(\d\d?:\d\d)//) {
            $track->{ 'LENGTH' } = $1;
        }

        if ($trackinfo =~ s/(.*)\(([^\)]+)\)//) {
            $track->{ 'CREDIT' } = $2;
            $trackinfo = $1;
        }

        $track->{ 'NAME' } = strip($trackinfo);

        push @tracks, $track;
    }

    $album->{ 'TRACKS' } = \@tracks;
}


sub parse_album_credits
{
    my ($self, $tb, $album) = @_;

    my $img = $tb->look_down('_tag', 'img',
                             'src', $CREDITS_IMG);

    return unless ($img);

    my $table = $img->look_up('_tag', 'table');

    if (!$table) {

        croak <<END;

Found image $CREDITS_IMG identifying table containing credits in the album page.
However, I could not find the containing table tag.  This probably means that
the structure of the AMG album page has changed and the parsing code will need
to be updated to reflect the changes.

END
    ;

    }


    my @credits;
    foreach my $table_row ($table->look_down('_tag', 'tr', 
                                             'class', $CREDITS_ROW_CLASS)) {
        my @cells = $table_row->look_down('_tag', 'td');
        next if (@cells < 3);

        my $record = {};

        # First cell - Artist Link

        my $cell = shift @cells;
        my $link = $cell->look_down('_tag', 'a');
        if ($link) {
            $record->{ 'ARTIST'    } = strip($link->as_text());
            $record->{ 'ARTIST_ID' } = extract_object_id($link->attr('href'));
        } else {
            $record->{ 'ARTIST'    } = strip($cell->as_text());
        }

        # Second cell - just a dash - ignore
        $cell = shift @cells;

        # Third cell - roles

        $cell = shift @cells;
        $record->{ 'ROLES' } = strip($cell->as_text());

        push @credits, $record;
    }

    $album->{ 'CREDITS' } = \@credits;    
}


sub analyze_artist_search_results
{
    my ($self, %params) = @_;

    my $desired_name   = $params{ '-desired_name'   };
    my $search_results = $params{ '-search_results' };

    # If there is only one search result just return it immediately 
    if (@$search_results == 1) {
        return $search_results->[0];
    }

    my $single_likely_match;
    foreach my $result (@$search_results) {
        if ($result->{ 'LIKELY_MATCH' }) {
            return $result if (lc($result->{ 'ARTIST' }) eq $desired_name);

            if ($single_likely_match) {
                $single_likely_match = undef;
            } else {
                $single_likely_match = $result;
            }
        }
    }

    return $single_likely_match;
}


sub parse_album_cover
{
    my ($self, $tb, $album) = @_;

    my $review_table = $tb->look_down('_tag', 'table',
                                      'class', 'ft3');

    return if (!$review_table);

    my $album_img = $review_table->look_down('_tag', 'img',
                                             sub { $_[0]->attr('width') > 100 });

    return if (!$album_img);

    my $cover_url = $album_img->attr('src');

    my ($extension) = ($cover_url =~ m/\.([^.]+)$/);

    $album->{ "COVER_URL" } = $cover_url;

    my $cover_filename = "$album->{ ARTIST } $album->{ ALBUM_TITLE }.$extension";
    $cover_filename =~ s/[\'()\"]//g;
    $cover_filename =~ s/\s/-/g;

    $self->progress("saving album cover $cover_filename...");

    my $response_code = getstore( $cover_url, $cover_filename);

    if ( HTTP::Response->new($response_code)->is_success ) {
        $album->{ "COVER_FILE" } = $cover_filename;
        $self->progress("ok\n");
    } else {
        $self->progress("failed\n");
    }

    return if (!$self->save_covers);
}


sub navigate_amg_home
{
    my ($self) = @_;

    my $url = $self->amg_base_url;
    my $simple_url = $url; $simple_url =~ s|http://||;
    $self->progress("Contacting $simple_url...");
    $self->browser->navigate(-url => $url);
    $self->progress("ok\n");
}


sub navigate_to_object_page
{
    my ($self, $object_id, $mesg) = @_;

    $self->progress("$mesg...");

    my $browser = $self->browser;
    my $response = $browser->navigate(-url => $self->make_amg_url($object_id));
    $self->progress("ok\n");
    return $response;
}



sub extract_object_id
{
    my ($str) = @_;
    if ($str =~ m/sql=([^&]+)/) {
        return $1;
    } else {
        die "Cannot extract object ID from string $str\n";
    }
}


sub identify_object_id
{
    my ($self, $object_id) = @_;

    if ($object_id =~ m/^a/i) {
        return "album";
    } elsif ($object_id =~ m/^b/i) {
        return "artist";
    } else {
        croak "Unrecognized type of AMG object id ($object_id)\n";
    }
}


sub make_amg_url
{
    my ($self, $id) = @_;
    $id = "$id~C" if ($id !~ m/~C$/i);
    return sprintf("%s/cg/amg.dll?p=amg&sql=%s", $self->amg_base_url, $id);
}


sub dump            
{
    my ($self, $flag_name) = @_;
    if (exists($self->{ "dump_flags" }{ $flag_name })) {
        return $self->{ "dump_flags" }{ $flag_name };
    } else {
        return undef;
    }
}

sub save_covers   { $_[0]->{ 'save_covers' }};
sub browser       { $_[0]->{ 'browser'      }}
sub amg_base_url  { $_[0]->{ 'amg_base_url' }}
sub progress_fh   { $_[0]->{ 'progress_fh'  }}


sub cleanstr
{
	my ($str) = @_;
	$str =~ s/^\s+//;
	$str =~ s/\s+$//;
	$str =~ s/^[\r\n]+//;
	$str =~ s/[\r\n]+$//;
	my($s) = chr(hex('a0'));
	$str =~ s/$s//g;
	return $str;
}


sub strip
{
    my $str = shift;
	$str =~ s/^\s+//;
	$str =~ s/\s+$//;
	$str =~ s/^[\r\n]+//;
	$str =~ s/[\r\n]+$//;
	my($s) = chr(hex('a0'));
	$str =~ s/$s//g;
    return $str;
}


sub parse_links_text
{
    my ($elem) = @_;

    my @links = $elem->look_down('_tag', 'a');

    my @textvals;
    foreach my $link (@links) {
        push @textvals, strip($link->as_text());
    }

    return \@textvals;
}



sub parse_images
{
    my ($self, $element, $record) = @_;

    foreach my $img ($element->look_down('_tag', 'img')) {
        my $val = $Images{ $img->attr('src') };
        if ($val) {
            $record->{ $val->[0] } = $val->[1];
        }
    }
}


sub lookup_object
{
    my ($self, $object_id) = @_;
    my $method = 'search_' . $self->identify_object_id($object_id);
    my $result = $self->$method(-id => $object_id);
    return $result;
}


sub new_tree_builder
{
    my ($self, $html, $dump) = @_;

    $html || croak 'Must specify html argument\n';

    my $tb = new HTML::TreeBuilder();
    $tb->parse($html);

    if ($dump) {
        if (ref($dump)) {
            $tb->dump($dump) 
        } else {
            $tb->dump();
        }
    }

    return $tb;
}


sub progress
{
    my $self = shift @_;
    my $fh = $self->progress_fh;
    if ($fh) {
        print $fh @_;
    }
}



# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# This next module is a Browser object that the AMG object uses internally to
# access the allmusic site.  It wraps most of the LWP stuff.  The object is
# not really designed for reuse as of now and so should be pretty much ignored
# (unless it's broken)

# Subclass LWP::UserAgent to override redirect_ok so we can handle our
# own redirects

package FormUserAgent;
use LWP::UserAgent;

no strict 'vars';

@ISA = qw( LWP::UserAgent );
sub redirect_ok { return 0; };

# Begin Browser module here

package Browser;

use strict;
use Carp;

use FileHandle;
use HTTP::Cookies;
use HTTP::Request;
use HTTP::Response;
use File::Path;
use HTML::TreeBuilder;
use URI::URL;
use URI::Escape;

use Data::Dumper;

$Browser::Def_Num_Attempts = 5;
$Browser::Def_Retry_Delay  = 2;
$Browser::Def_Form_Name    = 'form0';
$Browser::Def_Expire_Cache = 7 * 24 * 60 * 60;   # Specified in seconds

# INPUT TYPES
#
# Specifies the kinds of form INPUT tags that will be recognized during parsing

my %Input_Types = (
                   'submit'    => { category => 'buttons' },
                   'image'     => { category => 'buttons' },
                   'hidden'    => { category => 'hidden' },
                   'checkbox'  => { category => 'checkboxes', 
                                    selected_attr => 'checked' },
                   'text'      => { category => 'textboxes' },
                   'textfield' => { category => 'textboxes' },
                   'password'  => { category => 'textboxes' },
                   'radio'     => { category => 'radioboxes', 
                                    selected_attr => 'checked' }
                  );

# TAG TYPES

my %Tag_Types = ('select'   => { category => 'selectboxes', 
                                 selected_attr  => 'selected' },
                 'textarea' => { category => 'textareas' }
                );


sub cache_dir       { $_[0]->{ 'cache_dir'    }}
sub expire_cache    { $_[0]->{ 'expire_cache' }}
sub caching_enabled { $_[0]->{ 'cache_dir' } ? 1 : 0 }
sub progress_fh     { $_[0]->{ 'progress_fh'  }}

sub new 
{
	my ($class, %params) = @_;

    my $cache_dir    = $params{ "-cache_dir"    };
    my $expire_cache = $params{ "-expire_cache" } || $Browser::Def_Expire_Cache;
    my $log_fn       = $params{ "-log"          };
    my $agent_str    = $params{ "-agent"        };
    my $progress_fh  = $params{ "-progress"     };

	my $self = {
                'ua'           => new FormUserAgent,
                'cookie_jar'   => new HTTP::Cookies,
                'current_url'  => undef,
                'cache_dir'    => $cache_dir,
                'expire_cache' => $expire_cache,
                'progress_fh'  => $progress_fh,
                };


    if ($log_fn) {
        my $log_fh = new FileHandle;
        $self->{ 'log_fh' } = $log_fh;
        $log_fh->open(">$log_fn") || croak "ERROR opening $log_fn: $!\n";
    }

    if ($cache_dir) {
        if (-e $cache_dir && !-d $cache_dir) {
            croak "Cache dir $cache_dir exists, but is not a directory\n";
        }
        elsif (!-e $cache_dir) {
            mkpath($cache_dir, 0, 0777);
        }
    }


    $self->{ "ua" }->agent($agent_str) if ($agent_str);
        
	$self->{ "text_format_tags" } =  [
                                      ['basefont', '<BASEFONT[^>]*>|</BASEFONT>'],
                                      ['font', '<FONT[^>]*>|</FONT>'],
                                      ['b', '<B>|</B>'],
                                      ['i', '<I>|</I>'],
                                      ['s', '<S>|</S>'],
                                      ['strike', '<STRIKE>|</STRIKE>'],
                                      ['u', '<U>|</U>'],
                                      ['blink', '<BLINK>|</BLINK>'],
                                      ['small', '<SMALL>|</SMALL>'],
                                      ['big', '<BIG>|</BIG>'],
                                      ['sub', '<SUB>|</SUB>'],
                                      ['sup', '<SUP>|</SUP>'],
                                      ['center', '<CENTER>|</CENTER>'],
                                      ['marquee', '<MARQUEE[^>]*>|</MARQUEE>]']
                                     ];
	
	bless($self, $class);
	return $self;
}


sub redirect 
{
	my ($self, $request, $response) = @_;

	if (defined $response) {
		if ($response->is_error()) {
			return undef;
		}

		if (!$response->is_redirect()) {
			return undef;
		}
		
		my($url) = new URI::URL($response->header('Location'), $request->url()->as_string());

		$self->{ "cookie_jar" }->extract_cookies($response);
		$request = $request->clone();
		$request->method('GET');
		$request->protocol('HTTP/1.0');
		$request->content_type('text/html');
		$request->url($url->abs());
	}
    
	$self->{ "cookie_jar" }->add_cookie_header($request);

	return [$request, $self->{ua}->request($request)];
}


sub cache_file_expired
{
    my ($self, $filename) = @_;
    my $mtime = (stat($filename))[9];
    return (time > ($mtime + $self->expire_cache));
}


sub cache_serialize_response
{
    my ($self, $response, $filename) = @_;

    open(CACHE_FILE, ">$filename") || croak "Cannot write to cache file $filename: $!\n";
    print CACHE_FILE Dumper($response);
    close(CACHE_FILE);
}


sub cache_deserialize_response
{
    my ($self, $filename) = @_;

    if (open(CACHE_FILE, "$filename")) {
        $self->progress("(found in cache)...");
        my $contents = join("", <CACHE_FILE>);
        my $VAR1;
        eval($contents);
        my $response = $VAR1;
        return $response;
    }
    
    return undef;
}



sub make_cache_filename
{
    my ($self, $request) = @_;

    my $uri     = $request->uri;
    my $method  = $request->method;
    my $content = $request->content;

    $uri =~ s|^http://||;
    $uri =~ s|/|-|g;

    my $cache_fn = "$method-$uri";
    if ($content !~ m/^\s*$/) {
        $cache_fn .= "-$content";
    }

    $cache_fn =~ s|\-$||g;
    
    return File::Spec->catfile($self->cache_dir, $cache_fn);
}


sub progress
{
    my $self = shift @_;
    my $fh = $self->progress_fh;
    if ($fh) {
        print $fh @_;
    }
}


sub request 
{
	my ($self, $type, $resource, $base_url, $content) = @_;

#    print "\n*** request(): $type $base_url $resource content = $content\n";

	my $url = new URI::URL($resource, $base_url);
	if (($type eq 'GET') && (defined $content)) {
        $url->equery($content);
	}

    my $request = new HTTP::Request( $type => $url->abs() );

	$request->protocol("HTTP/1.0");
	$request->header( 'Accept-Language' => 'en-us' );
	$request->header( 'Accept' => 'image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, */*' );
	$request->user_agent( $self->{ "ua" }->agent() );

	if ($type eq 'POST') {
		my $length = length($content);
		$request->content_type('application/x-www-form-urlencoded');
		$request->content_length($length);
		$request->content($content);
	}

    my $cache_fn = $self->make_cache_filename($request) if ($self->cache_dir);

    if ($self->caching_enabled) {
        if ((-e $cache_fn) && !$self->cache_file_expired($cache_fn)) {
            my $response = $self->cache_deserialize_response($cache_fn);
            return $response if (defined($response));
        } 
    }

    # Make request and follow all redirects

	my $response;
	while (my $refvals = $self->redirect($request, $response)) {
		$request = $refvals->[0];
		$response = $refvals->[1];
	}
    
    if ($self->caching_enabled) {
        $self->cache_serialize_response($response, $cache_fn);
    }

	return $response;
}


sub do_navigate
{
	my ($self, %params) = @_;

    my $method = $params{ "-method" } || "GET";
    my $url    = $params{ "-url"    } || croak "Must specify -url\n";
    my $base   = $params{ "-base"   };

	$self->writelog("open(): METHOD: $method, URL: $url\n");

	my $response = $self->request($method, $url, $base, undef);
	if ($response->is_error()) {
		$self->writelog("ERROR: Unable to process response due to HTTP error code " . 
                        $response->code() . "\n");
		return undef;
	}
	
	$self->parse($response);

	$self->{ "current_url" } = $response->request()->url();
	$self->writelog("The current url is $self->{current_url}\n");

	return $response;
}


sub do_navigate_from_cache
{
    my ($self, %params) = @_;

    my $response = $params{ "-response" } || croak "Must specify -response\n";

	$self->parse($response);

	$self->{ "current_url" } = $response->request()->url();

	return $response;
}


sub clean_string 
{
	my ($self, $text) = @_;

	$text =~ s/^\s+//;
	$text =~ s/\s+$//;
	$text =~ s/^[\r\n]+//;
	$text =~ s/[\r\n]+$//;
	my($s) = chr(hex('a0'));
	$text =~ s/$s//g;
	return $text;
}


sub get_string 
{
	my ($self, $element) = @_;

	my($text) = undef;
	if (!ref($element)) {
		$element = $self->clean_string($element);
		if (length($element) <= 0) {
			$element = "";
		}
		$text = $element;
	}
	return $text;
}

	
sub get_element_text 
{
	my ($self, $root) = @_;

	my($text) = $self->get_string($root);
	if (not defined $text) {
		foreach my $element (@{$root->{'_content'}}) {
			$text = $self->get_string($element);
			if (defined $text) {
				last;
			}

			foreach my $tag (@{$self->{text_format_tags}}) {
				if (lc($element->tag()) eq $tag->[0]) {
					$text = $self->get_element_text($element);
					last;
				} elsif (defined $element->attr('href')) {
					$text = $self->get_element_text($element);
					last;
				}
			}
		}
	}

	if (defined $text && length($text) <= 0) {
		$text = undef;
	} 
	
	return $text;
}


sub recurse_form
{
    my ($self, $element, $form) = @_;

    $form ||= $element;  # to allow for one argument form to kick things off

    my $tag = lc($element->tag());
        
    if ($tag eq 'input') {
        my $input_type = lc($element->attr('type') || 'text');
        my $category   = $Input_Types{ $input_type }{ 'category' };

        if ($category) {
            push(@{ $form->{ $category }}, $element);
        }
    }
    elsif (exists($Tag_Types{ $tag })) {
        push(@{ $form->{ $Tag_Types{ $tag }->{ 'category' }}}, $element);
    }
    
    foreach my $child ($element->content_list) {
        $self->recurse_form($child, $form) if (ref($child)); # ignore text nodes
    }
}



sub recurse_html 
{
	my ($self, $root, $depth) = @_;

	my $last_element = undef;
	my $before_text  = $root->{ 'associated_text' };

	foreach my $element (@{$root->{ '_content' }}) {
		if (ref($element)) {
            my $tag_name = lc($element->tag());

			if (defined $element->attr('href')) {
				push(@{$self->{ 'hrefs' }}, $element);
			}

			my $get_text = 1;
			if (defined $before_text) {
				if (($tag_name ne 'a') && ($tag_name ne 'option')) {
					$element->{ 'before_text' } = $before_text;
				}
				$before_text = undef;
			}

			foreach my $tag (@{$self->{ 'text_format_tags' }}) {
				if ($tag_name eq $tag->[0]) {
                    $get_text = 0;
					last;
				}
			}
		
			if ($get_text) {
				my $text = $self->get_element_text($element);
				if (defined $text) {
					$element->{ 'associated_text' } = $text;
					$before_text = $text;
				}
			} 
	
			if (ref($last_element)) {
				if (not defined $last_element->{ 'associated_text' }) {
					if (($tag_name eq 'input') || ($tag_name eq 'select')) {
						$last_element->{ 'associated_text' } = $before_text;
					}
				}
			}

			$self->recurse_html($element, $depth + 1);

			$last_element = $element;

		} else {
			my $string = $self->get_string($element);
			if (defined $string) {
				if (length($string)) {
					$before_text = $string;
				}
			}
		}
	}
}


sub remove_text_attributes 
{
	my ($self, $content) = @_;

	#$content =~ s!<PRE>|</PRE>!!ig;
	$content =~ s!<H[1-6]>|</H[1-6]>!!ig;

	$content =~ s!<BASEFONT[^>]*>|</BASEFONT>!!ig;
	$content =~ s!<B>|</B>!!ig;
	$content =~ s!<I>|</I>!!ig;
	$content =~ s!<S>|</S>!!ig;
	$content =~ s!<U>|</U>!!ig;
	$content =~ s!<BLINK>|</BLINK>!!ig;
	$content =~ s!<SMALL>|</SMALL>!!ig;
	$content =~ s!<BIG>|</BIG>!!ig;
	$content =~ s!<CITE>|</CITE>!!ig;
	$content =~ s!<EM>|</EM>!!ig;
	$content =~ s!<STRONG>|</STRONG>!!ig;
	$content =~ s!<FONT[^>]*>|</FONT>!!ig;
	$content =~ s!<DD>|</DD>!!ig;
	$content =~ s!<DL>|</DL>!!ig;
	$content =~ s!<NOBR>|</NOBR>!!ig;
	#$content =~ s!<BR>|</BR>!!ig;
	#$content =~ s!<P>|</P>!!ig;
	#$content =~ s!<DIV[^>]*>|</DIV>!!ig;
	$content =~ s!<CENTER>|</CENTER>!!ig;

	return $content;
}


sub parse 
{
	my ($self, $response) = @_;

    # Clear out any old data 

    my $tb = $self->{ 'tb' };
    $tb->delete() if ($tb);

    foreach my $form_name (keys %{ $self->{ 'forms' }}) {
        $self->{ 'forms' }{ $form_name }{ 'tree' }->delete();
    }
    $self->{ 'forms' } = undef;
    $self->{ 'hrefs' } = undef;

    # Now create a new TreeBuilder object, and parse the content after first
    # getting rid of formatting tags.

	$tb = new HTML::TreeBuilder;

	my $content = $self->remove_text_attributes($response->content());
    $tb->parse($content);

	$self->recurse_html($tb, 0);
    $self->{ 'tb' } = $tb;

    # Parse forms separately

    my $start_form_content = 0;
    my $form_content;

    while ($content =~ m|<\s*form[^>]*>|ig) {
        $start_form_content = pos($content) - length($&);
        
        if ($content =~ m|</form>|ig) {
            $form_content = substr($content, $start_form_content, 
                                   pos($content) - $start_form_content);
        } else {
            $form_content = substr($content, $start_form_content);
        }

        $form_content = $self->remove_text_attributes($form_content);

#        print "FORM = ", $form_content, "\n";

        my $tree = new HTML::TreeBuilder;
        $tree->parse($form_content);
        $tree->eof();

        my $form = $tree->look_down('_tag', 'form');
        my $form_name = $form->attr('name') || $self->generate_default_form_name();
        $form->{ 'tree' } = $tree;

        $self->recurse_form($form);
        $self->{ 'forms' }{ $form_name } = $form;
    }

	return $response;
}


sub generate_default_form_name 
{
    my ($self) = @_;
    my $i=0;
    while (exists($self->{ 'forms' }{ "form$i" })) {
        $i++;
    }
    return "form$i";
}

sub do_click 
{
	my ($self, %params) = @_;

    my $href = $params{ "-href" } || croak "Must specify -href\n";
    
	foreach my $element (@{$self->{hrefs}}) {
		my($thishref) = $element->attr('href');
		if (defined $thishref) {
			if (lc($href) eq lc($thishref)) {
				my($response) = $self->open(-resource => $href, 
                                            -base_url => $self->{current_url}->abs());
				return $response;
			}
		}
	}
	return undef;
}


sub do_select_option 
{
	my ($self, $name, $item) = @_;

	my($selectbox) = $self->get_element('select', $name);
	if (not defined $selectbox) {
		$self->writelog("WARNING: select box with name $name not found!\n");
		return 0;
	}
	my($multiple) = 0;
	if (defined $selectbox->attr('multiple')) { #'
		$multiple = 1;
	}

	if (not defined $selectbox->{options}) {

		$selectbox->traverse(sub 
                             {
                                 my ($element, $start, $depth) = @_;

                                 if (defined $element) {
                                     if (ref($element) eq "HTML::Element") {
                                         if ($element->tag() eq 'option') {
                                             push(@{$selectbox->{options}}, $element);	
                                             return 0;
                                         }
                                     }
                                 }
                                 return 1;
                             },
                             'ignoretext');
	}

	foreach my $option (@{$selectbox->{options}}) {
		if ( !$multiple && defined $option->attr('selected') ) {
			delete($option->{'selected'});
		}
		
		if ($self->is_correct_element($option, $item)) {
			$option->attr('selected', " ");
			$self->writelog("FOUND OPTION $item FOR SELECT BOX $name\n");
			if ($multiple) {
				last;
			}
		}
	}
	return 1;
		
}												


sub do_unselect_option {
	my($self) = shift;
	my($name) = shift;
	my($value) = shift;
}


sub do_set_checkbox 
{
	my ($self, $name) = @_;
	
	my($checkbox) = $self->get_element('checkbox', $name);
	if (not defined $checkbox) {
		warn("WARNING: Unable to find checkbox with name $name\n");
		return 0;
	}

	$checkbox->attr('checked', '');
	return 1;

}


sub do_unset_checkbox 
{
	my ($self, $name) = @_;
	
	my($checkbox) = $self->get_element('checkbox', $name);
	if (not defined $checkbox) {
		warn("ERROR: Unable to find checkbox with name $name\n");
		return 0;
	}
	if (defined $checkbox->{'checked'}) {
		delete($checkbox->{checked});
	}
	return 1;
}


sub do_set_radio_button 
{
	my ($self, $name, $val) = @_;

    my @radio_buttons = $self->get_element('radio', $name);

    foreach my $radio_button (@radio_buttons) {
        my $radio_button_val = $radio_button->attr('value');
        if (($radio_button_val eq $val) ||
            ($radio_button_val == $val)) {
            $radio_button->attr('checked', 1);
        } else {
            $radio_button->attr('checked', undef);
        }
    }

    return 1;
}


sub print_element 
{
	my ($self, $element) = @_;

    if (defined $element->{ 'before_text' }) {
		print("BEFORE TEXT: " . $element->{ 'before_text' } . "\n");
	}

	print("ELEMENT TAG: " . $element->tag());
	if (defined $element->attr('name')) {
		print(" NAME: " . $element->attr('name'));
	}

	if (defined $element->attr('type')) {
		print(" TYPE: " . $element->attr('type'));
	}

	if (defined $element->attr('value')) {
		print(" VALUE: " . $element->attr('value'));
	}

	if (defined $element->attr('src')) {
        print " SRC: " . $element->attr('src');
    }

	if (defined $element->attr('href')) {
		print(" HREF: " . $element->attr('href'));
		if (defined $element->{ 'associated_text' }) {
			print(" ASSOCIATED TEXT: " . $element->{ 'associated_text' });
		}
	}
	print("\n");

	if (defined $element->{text_after}) {
		print("TEXT AFTER: " . $element->{text_after} . "\n");
	}
}


sub print_type 
{
	my ($self, $elements) = @_;

	foreach my $element (@{$elements}) {
		$self->print_element($element);
	}
}


sub dump_page 
{
	my ($self) = @_;

	foreach my $form_name (keys %{ $self->{ 'forms' }}) {
        my $form = $self->{ 'forms' }{ $form_name };

        print("FORM: NAME = $form_name ACTION = ", $form->attr('action'), 
              " METHOD = ", $form->attr('method'), "\n");

		foreach my $type (keys %Input_Types) {
            print "type = $type\n";
			next if ($type eq 'password');
			$self->print_type($form->{ $Input_Types{ $type }->{ "category" }});
		}
        
		foreach my $type (keys %Tag_Types) {
			$self->print_type($form->{ $Tag_Types{ $type }->{ "category" }});
		}
	}
    
	$self->print_type($self->{ "hrefs" });
}


sub make_pair 
{
	my($self) = shift;
	my($key) = uri_escape(shift);
	my($value) = uri_escape(shift);
	my($pair) = $key;
	if (defined $value && $value ne '') {
		$pair .= "\=$value";
	}
	return $pair;
}


sub extract_pairs 
{
	my ($self, $form, $button) = @_;

	my($query_string) = undef;
	if (defined $button->attr('name')) {
		my($button_name) = $button->attr('name');
		$button_name =~ $self->clean_string($button_name);
		if (length($button_name)) {
			$query_string = $self->make_pair($button->attr('name'), $button->attr('value')); #'
		}
	}

	foreach my $type (keys %Input_Types) {
		if (	($type eq 'password') ||
				($type eq 'submit') 	) {
			next;
		}

		my($elements) = $form->{ $Input_Types{ $type }->{ "category" }};
		if (not defined $elements) {
			next;
		}

		foreach my $elem (@{$elements}) {
			if (my $selected_attr = $Input_Types{ $type }->{ "selected_attr" }) {
				if (not defined $elem->attr($selected_attr)) {
					next;
				}
			}

			my($key) = $elem->attr('name');
			my($value) = $elem->attr('value');
			if (defined $key) {
				$self->writelog("name: $key, value: $value\n");			
				if (defined $query_string) {
						$query_string .= "&";
				}
				$query_string .= $self->make_pair($key, $value);
			}
		}
	}

	foreach my $type (keys %Tag_Types) {
		foreach my $elem (@{$form->{ $Tag_Types{ $type }->{ "category" }}}) {
			if (defined $elem->{options}) {
				foreach my $option (@{$elem->{options}}) {
					if (not defined $option->attr('selected')) {
						next;
					}
					my($key) = $elem->attr('name');
					my($value) = $option->attr('value');
					if (defined $key && defined $value) {
						$self->writelog("name: $key, value: $value\n");
						if (defined $query_string) {
							$query_string .= "&";
						}
						$query_string .= $self->make_pair($key, $value);
					}
				}
			} elsif ($elem->tag() eq 'textarea') {
				$self->writelog("found a textarea element with name " . $elem->attr('name') . "\n");
				my($key) = $elem->attr('name');
				my($value) = $elem->{associated_text};
				if (defined $key && defined $value) {
					$self->writelog("name: $key, value: $value\n");
					if (defined $query_string) {
						$query_string .= "&";
					}
					$query_string .= $self->make_pair($key, $value);
				}
			}
		}
	}

	$self->writelog("here is the query string: $query_string\n");
	return $query_string;
}		
	
	
sub do_press 
{
	my ($self, %params) = @_;

    my $form_name = $params{ "-form"  };
    my $value     = $params{ "-value" };
    my $name      = $params{ "-name"  };
    my $src       = $params{ "-src"   };

    if (!$value && !$name && !$src) {
        croak "Must specify one of -value, -name, or -src\n";
    }

    # Build a list of form names that we'll use to find the matching button

    my @form_names;
    if (defined($form_name)) {
        if (!exists($self->{ 'forms' }{ $form_name })) {
            croak "There is no form named '$form_name' in this document\n";
        }
        @form_names = ( $form_name );
    } else {
        @form_names = ( keys %{ $self->{ 'forms' }});
    }

    # Search list of forms for matching button

	foreach my $form_name (@form_names) {

        my $form = $self->{ 'forms' }{ $form_name };

		my $action = $form->attr('action');
		
		foreach my $button (@{ $form->{ 'buttons' }}) {

			my $this_value = $button->attr('value'); 			
            my $this_src   = $button->attr('src');
            my $this_name  = $button->attr('name');

            $this_value =~ s/^\s+//; $this_value =~ s/\s+$//;

			if ($this_value eq $value ||
                $this_name eq $name ||
                $this_src eq $src) {

                my $action = $form->attr('action') || $self->{ 'current_url' }->abs();
                my $method = uc($form->attr('method') || 'GET');

#                print "Preparing to execute form action $action, with method '$method'\n";

				my $query_string = $self->extract_pairs($form, $button);

#                print "Going to ", $self->{ current_url }->abs(), " request $action method $method query = ", $query_string, "\n";

				my $response = $self->request($method, $action, 
                                              $self->{ 'current_url' }->abs(), $query_string);

				if (defined $response) {
					if ($response->is_error()) {
						print "ERROR: Unable to process response due to HTTP error code " . $response->code() . "\n";
						$response = undef;
					} else {
						$self->{ 'current_url' } = $response->request()->url();
#						print "SETTING Current URL = $self->{current_url}\n";
						$self->parse($response);
					}
				}
				return $response;
			}
		}
	}

	return undef;
}			

			
sub fillin 
{
	my ($self, $name, $value) = @_;
	
	my $textbox = $self->get_element('text', $name) || $self->get_element('textfield', $name) ||
        croak "Cannot find text element '$name' in page\n";
    
    $self->writelog("SETTING TEXT BOX ELEMENT WITH VALUE $value\n");
    $textbox->attr('value', $value);
}


sub get_checkboxes 
{
	my ($self, $name) = @_;

	my(@checkboxes);
	foreach my $form_name (keys %{$self->{ 'forms' }}) {
        my $form = $self->{ 'forms' }{ $form_name };
		if (defined $form->{checkboxes}) {
			if (defined $name) {
				foreach my $checkbox (@{$form->{checkboxes}}) {
					my($curname) = $checkbox->attr('name');
					if (defined $curname && lc($curname) eq ($name)) {
						push(@checkboxes, $checkbox);
					}
				}
			} else {
				return $form->{checkboxes};
			}
		}
	}
	return @checkboxes;
}


sub is_correct_element 
{
	my ($self, $element, $name) = @_;
	
	my($checked_element) = undef;
	$name = lc($name);
	my($checkname) = $element->attr('name');
	if (defined $checkname && lc($checkname) eq $name) {
		$checked_element = $element;
	} elsif (defined $element->{before_text} && lc($element->{before_text}) eq $name) {
		$checked_element = $element;
	} elsif (defined $element->{associated_text} && lc($element->{associated_text}) eq $name) {
		$checked_element = $element;
	}
	return $checked_element;
}


sub get_element 
{
	my ($self, $type, $name) = @_;

	my $category = $Input_Types{ $type }->{ "category" };
	if (not defined $category) {
		$category = $Tag_Types{ $type }->{ "category" };
		if (not defined $category) {
            die "Warning: Unknown element type $type unable to continue!\n";
		}
	}

    my @matching_elems;
	foreach my $form_name ( keys %{ $self->{ 'forms' }}) {
        my $form = $self->{ 'forms' }{ $form_name };
		next if (!defined $form->{ $category });
        
        foreach my $elem (@{$form->{ $category }}) {
            if ($self->is_correct_element($elem, $name)) {
                if (wantarray) {
                    push @matching_elems, $elem;
                } else {
                    return $elem;
                }
            }
        }
	}

    if (@matching_elems) {
        return @matching_elems;
    } else {
        die "Unable to find element of type $type and name $name\n";
    }
}


sub tree
{
    my ($self) = @_;
    return $self->{ "tb" };
}


sub look_down
{
    my $self = shift;
    return $self->tree->look_down(@_);
}


sub writelog
{
    my ($self, @args) = @_;

    my $log_fh = $self->{ "log_fh" };
    if ($log_fh) {
        print $log_fh @args;
    }
}


sub AUTOLOAD 
{
    my $method = $Browser::AUTOLOAD;
    $method =~ s/Browser:://;
    my ($self, %params) = @_;

    my %dispatch = ( "navigate"            => \&do_navigate,
                     "navigate_from_cache" => \&do_navigate_from_cache,
                     "press"               => \&do_press,
                     "click"               => \&do_click,
                     "select_option"       => \&do_select_option,
                     "unselect_option"     => \&do_unselect_option,
                     "set_checkbox"        => \&do_set_checkbox,
                     "unset_checkbox"      => \&do_unset_checkbox,
                     "set_radio_button"    => \&do_set_radio_button );

    my $handler = $dispatch{ $method };

    if (!$handler) {
        croak "Can't locate object method '$method'\n";
    } else {

        my $num_attempts = $params{ "-attempts" } || $Browser::Def_Num_Attempts;
        my $retry_delay  = $params{ "-delay"    } || $Browser::Def_Retry_Delay;

        my $attempt_num=0;
        while ($attempt_num < $num_attempts) {
            $attempt_num++;

            my $retval = $self->$handler(%params);
            if ($retval) {
                # method ran successfully - we're done
                return $retval;
            }

            sleep($retry_delay);
        }

        croak "ERROR: Could not run method '$method'\n";
    }
}

1; # return true
