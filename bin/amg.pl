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
  --verbose    : Show progress info
  --url        : Use url (default http://www.allmusic.com)
  --perl       : Output as perl data structures
  --python     : Output as python data structures
  --php        : Output as serialized php array

  --nocache    : Disable caching of HTML responses
  --nocroak    : Don't die when a parse error is encountered
  --help       : Show this message

END
; # ' help broken emacs perl-mode
    
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

my ( $opt_album, 
     $opt_artist, 
     $opt_covers,
     $opt_dump, 
     $opt_help, 
     $opt_id,
     $opt_manual, 
     $opt_nocache, 
     $opt_nocroak,
     $opt_quiet, 
     $opt_perl,
     $opt_python, 
     $opt_php,
	 $opt_readable,
     $opt_save, 
     $opt_url,
     $opt_verbose );

GetOptions("album=s"       => \$opt_album,
           "artist=s"      => \$opt_artist,
           "covers=s"      => \$opt_covers,
           "dump:s"        => \$opt_dump,
           "help"          => \$opt_help,
           "id=s"          => \$opt_id,
           "manual"        => \$opt_manual,
           "nocache"       => \$opt_nocache,
           "nocroak"       => \$opt_nocroak,
           "perl"          => \$opt_perl,
           "php"           => \$opt_php,
           "python"        => \$opt_python,
           "quiet"         => \$opt_quiet,
		   "readable"      => \$opt_readable,
           "save=s"        => \$opt_save,
           "url=s"         => \$opt_url,
           "verbose"       => \$opt_verbose

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

# --python or --perl imply --quiet

if (($opt_python || $opt_perl || $opt_php) && !$opt_verbose) {
    $opt_quiet = 1;
}

# Show usage if necessary

usage() if ($opt_help || (!$opt_artist && !$opt_album && !$opt_id));


# Figure out cache dir

my $cache_dir = determine_cache_dir() unless ($opt_nocache);

# Now create WWW::AllMusicGuide object with options specified and call
# appropriate methods.

sub shit
{
    print @_;
}

my $amg = new WWW::AllMusicGuide(-progress    => $opt_quiet ? undef : \*STDOUT,
                                 -cache_dir   => $opt_nocache ? undef : $cache_dir,
                                 -url         => $opt_url,
                                 -dump        => $opt_dump,
                                 -save_covers => $opt_covers,
                                 -croak       => $opt_nocroak ? 0 : 1
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

if ((ref($result) eq "ARRAY") && !$opt_quiet) {
    print "Multiple search results found:\n";
}


if ($opt_perl) {
    print dump_perl( $result );
} elsif ($opt_python) {
    print dump_python( $result );
} elsif ($opt_php) {
    print dump_php( $result );
} elsif ($opt_readable) {
	print dump_readable( $result );
} else {
    print dump_perl( $result );
}


sub dump_readable
{
	my $str = "";
	if (exists($result->{ "ALBUM_TITLE" })) {
        
		$str .= <<END;
=====[ ALBUM ]=============================================================

Artist: $result->{ ARTIST }  ($result->{ ARTIST_ID })
Album:  $result->{ ALBUM_TITLE } 

END
		my $num_tracks = scalar @{ $result->{ "TRACKS" } };

		$str .= "$num_tracks tracks: \n\n";

		foreach my $track (@{$result->{ "TRACKS" }}) {
			$str .= sprintf("%2d. %-50s (%s)\n",
							$track->{ NUMBER },
							$track->{ NAME },
							$track->{ LENGTH });
		}

	}

	elsif (exists($result->{ "DISCOGRAPHY" })) {

		$str .= <<END;
=====[ ARTIST ]===========================================================
END
  ;
	}
	$str .= "\n" . "="x75 . "\n";
	  
	return $str;
}


sub dump_perl
{
    my ($result) = @_;

    $Data::Dumper::Indent = 1;
    
    if ($opt_save) {
        open(SAVEFILE, ">$opt_save") || die "Cannot write to save file $opt_save: $!\n";
        print SAVEFILE Dumper($result);
        close(SAVEFILE);
        return "";
    } 

    return Dumper($result);
}


sub dump_python
{
    my ($result) = @_;

    my $str = Dumper($result);

    $str =~ s/ => / : /mg;
    $str =~ s/\$VAR1 = //mg;
    $str =~ s/;\s*$/\n/mg;
    return $str;
}


sub dump_php 
{
 	my ($result) = @_;
 	return php_serialize($result, '', 1);
}

  
sub php_serialize 
{
 	my ($data, $key, $no_key) = @_;
 	my $str;
  
 	$str .= php_serialize_val($key)
 		unless ($no_key);
 	
 	if ( ref($data) =~ /hash/i ) {
 		my $num = keys(%{$data});
 		$str .= "a:$num:{";
 		foreach my $key ( keys(%$data) ) {
 			$str .= php_serialize($$data{$key}, $key);
 		}
 		$str .= '}';
 	} elsif ( ref($data) =~ /array/i ) {
 		my $num = @{$data};
 		$str .= "a:$num:{";
 		for (my $key=0; $key < @$data; $key++) {
 			$str .= php_serialize( $$data[$key], $key )
 		}
 		$str .= '}';
 	} elsif ( ! ref($data) ) {
 		$str .= php_serialize_val($data);
 	} else {
 		die('error, bad datatype!');
 	}
 
 	return $str;
}

 
sub php_serialize_val 
{
 	my ($val) = @_;
 	my $str;
 
 	if ($val =~ /^\d+$/) {
 		$str = "i:$val;";
 	} elsif ($val =~ /^\d+\.\d+$/) {
 		$str = "d:$val;";
 	} elsif (($val eq "\0") || ($val =~ /null/i)) {
 		$str = "N;";
 	} else {
 		my $str_len = length($val);
 		$str = "s:$str_len:\"$val\";";
 	}
 
 	return $str;
}


# sub dump_php
# {
#     my ($result) = @_;

#     $Data::Dumper::Indent = 1;

#     my $str = Dumper($result);

#     $str =~ s/\$VAR1 = //mg;
#     $str =~ s/;\s*$/\n/mg;
#     $str =~ s/\{/array\(/mg;
#     $str =~ s/\}/\)/mg;
#     $str =~ s/\[\n/array\(\n/mg;
#     $str =~ s/\](,?\n)/\)\1/mg;

#     return "$str;";
# }


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
        print STDERR "Using cache dir $cache_dir\n" unless $opt_quiet;
        return $cache_dir;
    } else {
        print STDERR "Cache is disabled\n" unless $opt_quiet;
        return $cache_dir;
    }
}




