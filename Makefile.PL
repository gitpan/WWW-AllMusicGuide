# This -*- perl -*- script makes the Makefile

require 5.003;
use ExtUtils::MakeMaker;
require "FindBin.pm";

WriteMakefile(NAME     	   => "WWW::AllMusicGuide",
              VERSION_FROM => "lib/WWW/AllMusicGuide.pm",
              dist    	=> {COMPRESS => 'gzip -9f', SUFFIX   => 'gz', DIST_DEFAULT => 'all tardist'},
              clean     => {FILES => "pod2html-*"},
              );
