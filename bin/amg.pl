#!/usr/bin/env perl

sub usage()
{
    print STDERR <<END;

$0 [options] [arg]

Options:

  --album  <s> : Name of album to lookup or filename containing album page.
  --artist <s> : Name of artist to lookup or filename containing artist page.
  --id     <s> : Lookup by AMG object ID

  --covers     : Save album covers
  --manual     : Don't automatically select likely matches
  --quiet      : Don't show progress info
  --url        : Use url (default "http://www.allmusic.com")

  --help       : Show this message

END
    exit(1);
}

use strict;
use FindBin qw( $RealBin );
use lib "$RealBin/../lib";
use File::Spec::Functions;
use File::Basename;
use WWW::AllMusicGuide;
use Data::Dumper;
use Getopt::Long;

$|=1;

# PARSE COMMAND LINE ARGUMENTS

my ($opt_album, $opt_artist, $opt_covers, $opt_dump, $opt_help, $opt_id);
my ($opt_manual, $opt_nocache, $opt_quiet, $opt_url);

GetOptions("album=s"       => \$opt_album,
           "artist=s"      => \$opt_artist,
           "covers"        => \$opt_covers,
           "dump:s"        => \$opt_dump,
           "help"          => \$opt_help,
           "id=s"          => \$opt_id,
           "manual"        => \$opt_manual,
           "nocache"       => \$opt_nocache,
           "quiet"         => \$opt_quiet,
           "url=s"         => \$opt_url
          );

# If none of --artist, --album, or -id were specified and arguments were
# given, assume all of the arguments combine to form a single artist name.

if (!$opt_artist && !$opt_album && !$opt_id) {
    $opt_artist = join(" ", @ARGV);
}

# Add a "http://" prefix to --url argument if necessary

if ($opt_url && $opt_url !~ m|^http://|) {
    $opt_url = "http://$opt_url";
}

# If --dump has an argument, the argument specifies a comma separated list
# of flags.  If it doesn't have an argument, it will be defined but empty,
# and we should default to turning all flags on.

if (defined($opt_dump) && !$opt_dump) {
    $opt_dump = "artists,albums";
}

# Show usage if necessary

usage() if ($opt_help || (!$opt_artist && !$opt_album && !$opt_id));


# Figure out cache dir

my $cache_dir = determine_cache_dir() unless ($opt_nocache);

# Now create WWW::AllMusicGuide object with options specified and call
# appropriate methods.

my $amg = new WWW::AllMusicGuide(-progress    => $opt_quiet ? undef : \*STDOUT,
                                 -cache_dir   => $opt_nocache ? undef : $cache_dir,
                                 -url         => $opt_url,
                                 -dump        => $opt_dump,
                                 -save_covers => $opt_covers
                                 );

my $result;
if ($opt_id) {

    $result = $amg->lookup_object($opt_id);

} elsif ($opt_artist && !$opt_album) {

    if (-e $opt_artist) {
        my $file_contents = readfile($opt_artist);
        $result = $amg->parse_artist_page(-html => $file_contents);
    } else {
        $result = $amg->search_artist(-name => $opt_artist,
                                      -auto => $opt_manual ? 0 : 1);
    }

} elsif ($opt_album && !$opt_artist) {

    if (-e $opt_album) {
        my $file_contents = readfile($opt_album);
        $result = $amg->parse_album_page(-html => $file_contents);
    } else {
        $result = $amg->search_album(-name => $opt_album);
    }


}

if (ref($result) eq "ARRAY") {
    print "Multiple search results found:\n";
}

$Data::Dumper::Indent = 1;
print Dumper($result);


sub readfile
{
    my ($fn) = @_;
    open(FILE, $fn) || die "Cannot open file $fn: $!\n";
    my $str = join("", <FILE>);
    close(FILE);
    return $str;
}


sub determine_cache_dir
{
    my $tmpdir = File::Spec->tmpdir();

    if ($tmpdir && !$opt_nocache) {
        my $cache_dir = catdir($tmpdir, "AllMusicGuideCache");
        print STDOUT "Using cache dir $cache_dir\n";
        return $cache_dir;
    } else {
        print STDOUT "Cache is disabled\n";
        return $cache_dir;
    }
}




