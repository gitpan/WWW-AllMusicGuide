################################################################################
#
# $Id: Tools.pm,v 1.1 2002/11/10 09:37:55 yohamed Exp $
# $Name:  $
#
# Author(s) : Mohamed Hendawi (moe@pobox.com)
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# NOTE:  This Perl code has been written on a 132 column display.  It will be
# easier to read/modify this code if you can view at this width.  
# 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
################################################################################

=head1 NAME

Test::Tools - Routines to help in writing test scripts

=head1 SYNOPSIS

 use Test::Tools;
 use Test::Tools qw ( :tests ); # Same as above
 use Test::Tools qw ( :tests :utils ); # Also import utility functions
 use Test::Tools qw ( :all ); # import everything

 init_test_script; 

=head1 DESCRIPTION

The Test::Tools module provides routines to help write test scripts.
It is meant to be used by test scripts as described in Test::Harness.
To use the Test::Tools module to help write your test scripts, while 
not requiring the module be installed in people's perl site_lib
directory you could something like the following:

=over 2

=item *

Create a directory "testlib/" in your "t/" subdirectory with your
test scripts.

=item * 

Create the directory "testlib/Test", and then copy Test.pm (this 
file) into that directory.

=item *

Add the line C< use lib "testlib", "t/testlib" > to your .t test
script.

=item *

Add the "t/testlib/Test/Tools.pm" file to your MANIFEST file

=back

This will ensure that Test::Tools is available when test scripts are
run for your module, without requiring it to be installed in the system
perl library.

=head1 TEST FUNCTIONS

You can import all of these functions at once with the tag ":tests".
Some really simple functions:

=head2 init_test_script

 init_test_script %params
 init_test_script

Initializes the test script.  This should be the first command run by the test
script.  It performs the following functions:

=over 4

=item * chdir() to the test script directory

By default, init_test_script() will perform a chdir to the directory
in which the test script is located.  This ensures that the test
script can refer to test data files with a relative pathname,
regardless of where the test script is run from.  For example: if the
test script is located in the directory "t/foo.t" and uses a test data
file "t/masters/test.dat", the script can refer to the file as
"masters/test.dat".  This applies if the test script is run directly
from the "t/" directory or via a "make test" (Test::Harness)
invocation in the parent directory.

To disable this feature, specify -nocd => 1.
 
=back

=head2 ok

 ok $number
 ok

Prints the string "ok $number\n" to stdout or just "ok\n" if $number
is omitted.  See Test::Harness.

=head2 notok

 notok

Prints the string "notok\n" to stdout.  See Test::Harness.

The following functions (except for ok(), and notok()) all begin with
the prefix "test_".  Each returns a 1 for success, and 0 for failure.
If the package global $Harness_Output is set, then each one of these
functions prints "ok\n" on success and "not ok\n" on failure.  See
Test::Harness for more info.  

The purpose of these functions is usually to check a return value of
some sort against a known value to make sure that they match.  Most of
these "test_" functions accept a matching string and in the event that
things don't match up, a helpful message will be displayed showing
what was expected vs. what was actually encountered.

=head2 test_ok

 test_ok $expr, $notok_mesg
 test_ok $expr

Evaluates $expr and prints "ok" or "not ok".  A non-zero value of
$expr is interpreted as "ok".  If $notok_mesg is specified, then
it is printed along with "not ok" if $expr evaluates to 0.

=head2 test_cmdout

 test_cmdout $command, $expected;

Runs the command specified in $command and compares the output on
stdout with $expected.  Returns true if they are equal.  Make sure
to include any newlines that may be output in the $expected string.
As a special case, if $expected is a simple string with no newlines
and the output of $command is the same except with a SINGLE trailing
newline, the function will return true.  This is to enable the 
something like the following to work:

    test_cmdout "/usr/bin/uname", "SunOS";

instead of having to use (remember) the more correct:

    test_cmdout "/usr/bin/uname", "SunOS\n";

=head2 test_methods

 test_methods $object, $method_tests

The test_methods function is used to run a number of tests on object
methods.  It is useful in test scripts after object construction or 
initialization to make sure a number of methods are returning the 
correct values.  The function accepts two arguments,
$object and $method_tests.  The $object is the
blessed object reference you want to check.  $method_tests defines
the tests to be performed. 

The $method_tests argument is a list reference where each element
describes a test invocation of a single method call.  Each element is
list reference of the following form:

  [ method_name, params, context, comparison, retvals, ... ]
 
where:

   method_name - The name of the method to check.  This calls
                 $object->method_name(@params)
 
   params      - A list reference that is dereferenced and 
                 passed to the method.  e.g. 
                 $object->method_name(@{$params})
 
   context     - The context to execute the function in.  Either
                 "scalar" or "list".
 
   comparison  - Either "eq" or "ne" right now.  
 
   retvals     - a list of return values to compare as per
                 comparison

For example, the following $method_tests would specify
that $object->foo() should return "foobar", $object->bar("bozo")
should return "the clown", and $object->baz() should return 
("foo", "bar", "and", "grill"):

   $method_tests = 
     [[ "foo", "", "scalar", "eq", "foobar" ],
      [ "bar", [ "bozo" ], "scalar", "eq", "the clown" ],
      [ "baz", "", "list", "eq", "foo", "bar", "and", "grill" ]];
 
   test_methods($object, $method_tests) || warn "Failed!\n";

The test_methods function returns 1 if all checks were successful,
and 0 if there were any errors.    

=head2 test_hash

 test_hash $hashref, $hash_tests

The test_hash() function is similar to the the check_method() except
that it is used to check the values in a hash, and that each check
has the form:

  [ key_name, context, comparison, vals, ... ]

If context is "list", then the value of the key_name in the hash
is dereferenced as an array and the list is compared with the
vals specified.  For example:

 $hash_tests =
   [[ "foo", "scalar", "eq", "foobar" ],
    [ "bar", "scalar", "eq", "the clown" ],
    [ "baz", "list",   "eq", "foo", "bar", "and", "grill" ]]

The following hash reference would satisfy all of these checks,
for example:

 $hash = { "foo" => "foobar",
           "bar" => "the clown",
           "baz" => [ "foo", "bar", "and", "grill" ] }

=head2 test_filec_eq

 test_filec_eq $a, $b, ...
 test_filec_eq [ $a, $a1, $a2, ... ], [ $b, $b1, $b2, ... ]

Compares file contents together and returns true if all are identical.
The first form just compares all specified files together and returns 
true if all files have the same contents.  The second form compares 
files pairwise as specified by each listref.  For example, $a is compared
to $b, $a1 is compared to $b1, and so on.

=head2 test_filec_ne

 test_filec_ne $a, $b, ...
 test_filec_ne [ $a, $a1, $a2, ... ], [ $b, $b1, $b2, ... ]

Exactly the same as test_filec_eq except that it returns true if B<all>
files differ.

=head1 UTILITY FUNCTIONS

The following other functions are available that might be helpful:

=head2 capture

 capture {
     ...
     code
     ...
 };

The capture() function is used to capture output to stdout
and/or stderr from a block of code and save it in a file.
The package variables $Capture_Stdout and $Capture_Stderr specify
where output should be captured to.  If either is empty, then the
corresponding output is not captured.  Captures can be nested.

See L<"EXAMPLES"> for more information.

=head2 read_file

 read_file $filename

Reads the specified file and returns a string containing the
file contents.

=head1 EXAMPLES

The capture() function is intended to be used something like this:

 $Test::Tools::Capture_Stdout = "stdout.out";
 $Test::Tools::Capture_Stderr = "stderr.out";
  
 capture {
    print STDOUT "This line is going to stdout\n";
    print STDERR "This line is going to stderr\n";
 };

Captures can be nested.  The following would do what you
expect, for example:

 $Test::Tools::Capture_Stdout = "stdout.outer";
 $Test::Tools::Capture_Stderr = "stderr.outer";

 capture { 
   print STDOUT "Outer stdout\n";
   print STDERR "Outer stderr\n";
   $Test::Tools::Capture_Stdout = "stdout.inner";
   capture { print "Inner stdout\n"; }; 
 };

To capture to stderr only, you would specify "" for the stdout
destination.

=head1 BUGS

=over 4

=item * 

The capture() function is actually supposed to be able to be used
something like this:

 capture {
    ...
 } to "stdout.out", "stderr.out";

However... for some reason the to() function gets confused when
C<my> variables are passed in.  

=item * 

When C<use>ing this module, the current working directory is
automatically set to the directory that the script is located in.  You
should probably have the option to disable this feature via some
directive in the import list.

=back

=head1 SEE ALSO

Test::Harness

=head1 AUTHOR

Mohamed Hendawi E<lt>moe@pobox.com>

=head1 COPYRIGHT

Copyright (c) 1997 Mohamed Hendawi. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  package Test::Tools;

require Exporter;
require 5.003;

@ISA         = qw( Exporter );

%EXPORT_TAGS = (
                utils  => [ qw( capture to compare_files ) ],
                tests  => [ qw( init_test_script ok notok test_ok 
                                test_cmdout test_methods test_method test_hash 
                                test_filec_eq test_filec_ne test_eq test_ne) ]
                );

$EXPORT_TAGS{ all } = [ map { @{$EXPORT_TAGS{$_}} } keys %EXPORT_TAGS ];

Exporter::export_tags("tests");
Exporter::export_ok_tags("utils");

$VERSION = "0.01";

use strict 'vars';
use Carp;
use FindBin qw ( $Bin );
use File::Path;
use vars qw ( $VERSION 
              $Harness_Output $Tests_Dir $Error_Message $Capture_Stdout $Capture_Stderr );

sub ok;
sub notok;
sub capture (&@);
sub to (@);
sub run_test_script;
sub parse_test_script;

# Package-wide globals, user-settable 

$Tests_Dir      = "/tmp/tests";   # Default directory to create test environments
$Harness_Output = 1;              # Output "ok" or "not ok" for functions
$Error_Message  = "";             # Holds an error message for package functions
$Capture_Stdout = "";
$Capture_Stderr = "";

# Private stuff

@Test::Tools::saved_stdout   = ();  # Stack of saved STDOUT filehandles
@Test::Tools::saved_stderr   = ();  # Stack of saved STDERR filehandles


sub ok { 
    if ($_[0]) { 
        print "ok $_[0]\n"; 
    } else { 
        print "ok\n"; 
    } 
    1;
}


sub notok { 
    print "notok\n"; 
}


sub init_test_script
{
    my %params = get_named_parameters(@_);
    unless ($params{ "nocd" }) {
        chdir($Bin) || croak "Cannot chdir to $Bin: $!\n";
    }
}


sub test_ok
{
    my $expr   = shift @_;
    my %params = get_named_parameters(@_, "notok_mesg" );

    my $notok_mesg = $params{ "notok_mesg" };

    if ($expr) {
        ok() if ($Harness_Output);
    } else {
        notok() if ($Harness_Output);
        print $notok_mesg, "\n" if $notok_mesg;
    }
    return $expr;
}


sub test_okz
{
    my $expr = shift @_;
    test_ok !$expr, @_;
}


sub test_eq
{
    my ($expr1, $expr2) = @_;
    if ($expr1 eq $expr2) {
        ok() if ($Harness_Output);
        return 1;
    } else {
        notok() if ($Harness_Output);
        print qq|"$expr1" supposed to be eq to "$expr2"\n|;
        return 0;
    }
}


sub test_ne
{
    my ($expr1, $expr2) = @_;
    if ($expr1 ne $expr2) {
        ok() if ($Harness_Output);
        return 1;
    } else {
        notok() if ($Harness_Output);
        print qq|"$expr1" supposed to be ne to "$expr2"\n|;
        return 0;
    }
}


sub test_cmdout
{
    my ($command, $expr) = @_;

    my $output = `$command`;
    
    if (($output eq $expr) || 
        ($output eq "$expr\n")) {
        ok() if ($Harness_Output);
        return 1;
    } else {
        notok() if ($Harness_Output);
        if (($expr =~ tr/\n/\n/) == 1) {
            $expr =~ s|\n|\\n|;
        }
        if (($output =~ tr/\n/\n/) == 1) {
            $output =~ s|\n|\\n|;
        }
        print qq|\tExpected : "$expr"\n|;
        print qq|\tGot      : "$output"\n|;
    }
}


sub test_hash
{
    croak 'usage: test_hash $hashref $hash_tests [%params]\n' if (@_ < 2);

    my $hashref = shift @_;
    my $checks  = shift @_;
    my %params = get_named_parameters(@_);

    my $fh = $params{ "fh" } || \*STDOUT;
    (ref($checks) eq "ARRAY") || croak "Hash checks is not a listref\n";
    (ref($hashref) eq "HASH") || croak "Must pass in a hash reference\n";
    
    my $num_failed=0;
    foreach (@{$checks}) {
        my ($key, $context, $cmp, @vals) = @{$_};
        checkval($hashref, $key, "", $context, $cmp, @vals) || $num_failed++;
    }

    test_ok ($num_failed == 0);
}


# -----------------------------------------------------------------------------
#
# test_methods
#
# Run a number of checks on an object's methods 
#
# -----------------------------------------------------------------------------

sub test_methods
{
    croak 'usage: test_methods $object $method_tests [%params]\n' if (@_ < 2);
    
    my $object = shift @_;
    my $checks = shift @_;
    my %params = get_named_parameters(@_);

    my $fh = $params{ "fh" } || \*STDOUT;
    
    (ref($checks) eq "ARRAY") || croak "Method checks is not a listref\n";
    (ref($object)) || croak "You must specify an object reference\n";
    
    my $num_failed=0;
    foreach (@{$checks}) {
        my ($method, $params, $context, $cmp, @vals) = @{$_};
        checkval($object, $method, $params, $context, $cmp, @vals) || $num_failed++;
    }
    
    test_ok ($num_failed == 0);
}


sub test_method
{
    my ($object, $method, $params, $context, $cmp, @vals) = @_;
    test_ok checkval($object, $method, $params, $context, $cmp, @vals);
}


sub test_filec_eq
{
    my (@a, @b);
    if (ref($_[0]) eq "ARRAY") {
        if (ref($_[1]) ne "ARRAY") {
            croak "Second argument must be listref if first arg is listref\n";
        } else {
            @a = @{ shift @_ };
            @b = @{ shift @_ };
            croak "Lists do not have same number of elements!" if (@a != @b);
        }
    } else {
        my $a = shift @_;
        @b = @_;
        @a = map { $a } @b;
    }
    
    my ($errors, $a, $b) = (0, "", "");
    while (@a) {
        $a = shift @a;
        $b = shift @b;
        if (!-e $a) {
            print qq/File "$a" is missing\n/;
            $errors++;
        } elsif (!-e $b) {
            print qq/File "$b" is missing\n/;
            $errors++;
        } elsif (compare($a, $b) != 0) {
            print qq/File "$a" differs from "$b"\n/;
            $errors++;
        }
    }
    
    test_ok ($errors == 0);
}


sub test_filec_ne
{
    my (@a, @b);
    if (ref($_[0]) eq "ARRAY") {
        if (ref($_[1]) ne "ARRAY") {
            croak "Second argument must be listref if first arg is listref\n";
        } else {
            @a = @{ shift @_ };
            @b = @{ shift @_ };
            croak "Lists do not have same number of elements!" if (@a != @b);
        }
    } else {
        my $a = shift @_;
        @b = @_;
        @a = map { $a } @b;
    }
    
    my ($errors, $a, $b) = (0, "", "");
    while (@a) {
        $a = shift @a;
        $b = shift @b;
        if (compare($a, $b) == 0) {
            print qq/File "$a" identical to "$b", but should differ\n/;
            $errors++;
        }
    }
    
    test_ok ($errors == 0);
}


sub to (@) { 
    $Capture_Stdout = $_[0];
    $Capture_Stderr = $_[1];
    @_;
}


sub capture (&@)
{
    my ($coderef, $capture_stdout, $capture_stderr) = @_;

    my $subname        = (caller(1))[3] || "__main__";
    my $fh_stdout      = "$subname" . "_stdout";
    my $fh_stderr      = "$subname" . "_stderr";

    $capture_stdout ||= $Capture_Stdout;
    $capture_stderr ||= $Capture_Stderr;

    if ($capture_stdout) {
        open($fh_stdout, ">&STDOUT")     || croak "capture: can't save current STDOUT ($!)\n";

#	print STDOUT "STDOUT now being captured in $capture_stdout\n" if (@Test::Tools::saved_stdout);

        open(STDOUT, ">$capture_stdout") || croak "capture: can't redirect STDOUT to $capture_stdout ($!)\n";
        push(@Test::Tools::saved_stdout, $fh_stdout);
    }

    if ($capture_stderr) {
        open($fh_stderr, ">&STDERR")     || croak "capture: can't save current STDERR ($!)\n";
#	print STDERR "STDERR now being captured in $capture_stderr\n" if (@Test::Tools::saved_stderr);
        
        open(STDERR, ">$capture_stderr") || croak "capture: can't redirect STDERR to $capture_stderr ($!)\n";
        push(@Test::Tools::saved_stderr, $fh_stderr);
    }
	
    my $result = eval { &$coderef };
    
    # Set things back to the way they were

    if ($capture_stdout) {
        my $old_fh_stdout = pop(@Test::Tools::saved_stdout);
        my $str = ">&" . "$fh_stdout";
        open(STDOUT, $str) || croak "capture: can't restore STDOUT ($!)\n";
    }

    if ($capture_stderr) {
        my $old_fh_stderr = pop(@Test::Tools::saved_stderr);
        my $str = ">&" . "$fh_stderr";
        open(STDERR, $str) || croak "capture: can't restore STDERR ($!)\n";
    }

    return $result;
}


sub read_file
{
    my ($fn) = @_;
    open(FILE, $fn) || croak "Cannot read from file '$fn': $!\n";
    my $file = join("", <FILE>);
    close(FILE);
    return $file;
}


# ------------------------------------------------------------------------------
#
# INTERNAL (PRIVATE) STUFF
#
# ------------------------------------------------------------------------------

sub get_named_parameters (\@;$)
{
    my ($params, $singleton) = @_;

    my @params = @{$params} if ($params);
    
    if (@params == 1) {
        if ($singleton) {
            my $singleton_val = shift @params;
            $singleton =~ s/^\-//; # get rid of Initial - if present
            @params = ($singleton, $singleton_val);
        } else {
            croak "No singleton specified and hash only has one element!\n";
        }
    } else {
        if (@params % 2) { croak "Odd number of hash elements!\n"; }

        my $i;
        for ($i=0;$i<@params;$i+=2) {
            $params[$i]=~s/^\-//;     # get rid of Initial - if present
            $params[$i]=~tr/A-Z/a-z/; # parameters are lower case
        }
    }

    return @params;
}


sub checkval
{
    my ($object, $function, $params, $context, $cmp, @vals) = @_;

    my $ob_type = ref($object) || croak "You must specify a hashref or an object!\n";
    my @params  = (ref($params) eq "ARRAY") ? @{$params} : $params ? ($params) : ();
    
    $context ||= "scalar";

    # Call function or 

    if ($context eq "scalar") {
        my $got      = ($ob_type eq "HASH") ? $object->{ $function } : $object->$function(@params);
        my $expected = $vals[0];

        $cmp ||= "eq";
        my $fail_scalar = 0;
        if (@vals == 0) {
            $fail_scalar = !$got;
        } elsif ((defined($got) && defined($expected) && (!eval("\$got $cmp \$expected"))) ||
                 (defined($got) && !defined($expected)) ||
                 (!defined($got) && defined($expected))) {
            $fail_scalar = 1;
        }

        if ($fail_scalar) {
            if ($ob_type eq "HASH") {
                print qq/ERROR $cmp: Hash key "$function" has wrong value\n/;
            } else {
                my $params = render_list(@params);
                print qq/ERROR $cmp: $ob_type\::$function$params returned wrong value\n/;
            }
            my $expected_str = (@vals == 0) ? "<non-zero>" : (defined($expected)) ? $expected : "<undef>";
            print "\tExpected : $expected_str\n";
            print "\t     Got : ", (defined($got) ? $got : "<undef>"), "\n";
            return 0;
        }

    } elsif ($context eq "list") {
        my @got      = ($ob_type eq "HASH") ? @{$object->{ $function }} : $object->$function(@params);
        my @expected = (ref($vals[0]) eq "ARRAY") ? @{$vals[0]} : @vals;

        my $fail_list = 0;
        if (@got == @expected) {
            my $i;
            $cmp ||= "eq";
            for ($i=0;$i<@expected;$i++) {
                my $got = $got[$i];
                my $expected = $expected[$i];
                if ((defined($got) && defined($expected) && !eval("\$got $cmp \$expected")) ||
                    (defined($got) && !defined($expected)) ||
                    (!defined($got) && defined($expected))) {
                    $fail_list = 1;
                }
            }
        } else {
            $fail_list = 1;
        }	

        if ($fail_list) {
            if ($ob_type eq "HASH") {
                print qq/ERROR $cmp: Hash key "$function" has wrong list value\n/;
            } else {
                my $params = render_list(@params);
                print qq/ERROR $cmp: $ob_type\::$function$params returned wrong list value\n/;
            }
            
            print "\tExpected: " . render_list(@expected) . "\n";
            print "\t     Got: " . render_list(@got) . "\n";
            return 0;
        }
    }
    
    # aok
    return 1;
}


sub render_list
{
    return "(" . join(",", map { (defined($_)) ? qq{"$_"} : "<undef>" } @_) .  ")";
}

#sub run_test_script
#{
#    my ($tests, %params) = @_;
#    croak "usage: run_test_script $tests, [ -param => val, ...]\n" unless (@_%2);
#    
#    my %params = get_named_parameters(%params);
#
#    my $verbose    = $params{ 'verbose'    } and print "Verbose mode set\n";
#    my $format     = $params{ 'format'     } and $verbose and print "$params{'format'} format selected\n";
#    my $selected   = $params{ 'selected'   };
#    my $tests_dir  = $params{ 'tests_dir'  } || $Test::Tools::Tests_Dir;
#
#    if (ref($tests) ne "HASH") {
#	croak "Invalid -tests specified - not a HASH reference\n";
#    }
#
#    my @selected = (ref($selected) eq "ARRAY") ? @{$selected} : ($selected ? $selected : ());
#    my %selected = map { $_, 1 } @selected;
#    
#    my $num_tests = $tests->{ ".numtests" };
#
#    print "Running ", (@selected) ? (scalar @selected) : $num_tests , "/$num_tests tests\n";
#
#    foreach (@{$tests->{ ".testgroups" }}) {
#
#	my $testgroup = $_;
#
#	foreach (@{$tests->{ $testgroup }{ ".tests" }}) {
#	
#	    my %test     = %{$_};
#	    my $caller   = caller;
#	    my $name     = $test{ 'name' };
#	    my $desc     = $test{ 'desc' };
#	    my $test_dir = "$tests_dir/$name";
#	    my $func     = eval("\\&$caller\::test_$name");
#	    
#	    # Should we run this test?
#	    
#	    if ((@selected == 0) || ($selected{ $name })) {
#		# Yes run it
#		# Create the test directory.  The test function can place temporary
#		# files in here.
#		
#		if ($test_dir && !-e $test_dir) {
#		    mkpath($test_dir, 0, 0775) || croak "Could not create directory '$test_dir' : $!\n";
#		}
#		
#		$Capture_Stdout = "$test_dir/stdout";
#		$Capture_Stderr = "$test_dir/stderr";
#		
#		my ($result) = capture {
#		    my $retcode = eval { &$func(-test_dir => $test_dir) };
#		    if ($@) { print STDERR "$@\n"; return 0; }
#		    return $retcode;
#		};
#
#		if ($format =~ m/^d/) {
#		    # Detail format for showing results
#		    show_detailed_results($result, \%test, $test_dir, "$test_dir/stdout", "$test_dir/stderr");
#		} else {
#		    show_summary_results($result, \%test );
#		}
#	    } else {
#		# No don't run this test
#		print "Skipped test $name\n" if ($verbose);
#	    }
#	}
#    }
#
#    show_detailed_results() if ($format =~ m/^d/);  # trailing =====... separator
#}
#
#
#sub parse_test_script
#{
#    my ($file) = @_;
#
#    my $ini = read_mini_ini($file);
#
#    if (!$ini) {
#	$Test::Tools::Error_Message = "Can't read test script from $file: $!";
#	return 0;
#    }
#
#    # Build test script object
#
#    my $testgroup = "default";
#    my $tests     = { ".testgroups" => [ "default" ] };
#    
#    foreach (@{$ini->{ ".sections" }}) {
#	my $section_name = $_;
#
#	if ($section_name =~ m/^\s*testgroup\s*(.*?)\s*$/) {
#	    $testgroup = $1;
#	    push(@{$tests->{ ".testgroups" }}, $testgroup);
#	    $tests->{ $testgroup } = $ini->{ $section_name };
#	    $tests->{ $testgroup }{ ".tests" } = [];
#	} elsif ($section_name =~ m/^\s*test\s*(.*?)\s*$/) {
#	    my $testname = $1;
#	    my $testdef  = $ini->{ $section_name };
#	    $testdef->{ "name" } = $testname;
#	    push(@{$tests->{ $testgroup }{ ".tests" }}, $testdef);
#	    $tests->{ $testgroup }{ ".testlkp" }{ $testname } = $testdef;
#	    $tests->{ $testgroup }{ ".numtests" }++;
#	    $tests->{ ".numtests" }++;
#	}
#    }
#
#    return $tests;
#}
#
#
#sub show_detailed_results
#{
#    my ($result, $test, $test_dir, $stdout_file, $stderr_file) = @_;
#
#    print "==============================================================================\n";
#    return unless ($test);
#
#    my $name   = $test->{ 'name' };
#    my $desc   = $test->{ 'desc' };
#    my $stdout = read_file($stdout_file);
#    my $stderr = read_file($stderr_file);
#    my $status = $result ? "    ok" : "FAILED";
#
#    my $id = sprintf("%-72.72s", "Test $name - $desc ");
#    print $id, " "x(72 - length($id) - length($status)), $status, "\n\n";
#    
#    if (!$result) {
#	print "Test files are in $test_dir\n\n" if ($test->{ "test_dir" });
#
#	if ($stdout !~ m/^\s*$/) {
#	    print "The following was produced on STDOUT: \n\n";
#	    print $stdout, "\n";
##	    print wrap("  ","  ", $stdout), "\n";
#	}
#
#	if ($stderr !~ m/^\s*$/) {
#	    print "\nThe following was produced on STDERR: \n\n";
#	    print $stderr, "\n";
##	    print wrap("  ", "  ", $stderr), "\n";
#	}
#    }   
#}
#
#
#sub show_summary_results
#{
#    my ($result, $test) = @_;
#    
#    if ($result) {
#	print "  Test ", $test->{ 'name' }, " - ok\n";
#    } else {
#	print "* Test ", $test->{ 'name' }, " - failed\n";
#    }
#}
#
#
#=item I<run_test_script>($tests, %params) - Run a series of tests
#
# The run_test_script() function executes a series of tests
# as defined by the $tests argument.  $tests can be
# constructed manually, or by using I<parse_test_script>.
# The run_test_script driver calls a function of the same
# name as a test, prefixed with a "test_".  For example: the
# test driver will call the function "test_foobar" for the
# test named "foobar".
#
#=item I<parse_test_script>($file) - Parse a test script
#
# Parses a test script definition and creates an object
# suitable for passing to I<run_test_script>.  $file can
# either be a filename containing the test script or a
# filehandle that when read, produces the lines of the test
# script.  The test script format is described later in this
# document.
#
#=back
#sub read_mini_ini
#{
#    my ($file) = @_;
#
#    my $fh;
#    if ((ref($file) eq "GLOB") || (ref($file) eq "FileHandle")) {
#	$fh = $file;  # $file specifies handle to read from
#    } else {
#	# $file specifies filename to read from
#	$fh = gensym;
#	open($fh, $file) || return 0;
#    }
#
#    my ($section, $key, $multiline, $val, $ini);
#
#    while (<$file>) {
#	
#	if (m/^\[\s*(.*?)\s*\]\s*\n$/) 
#	{
#	    # It's a section line [ section ]
#	    $section = $1;
#	    push(@{$ini->{ ".sections" }}, $section);
#	}
#	elsif (!$key && m/^(.*?)\s*=\s*(.*)$/) 
#	{
#	    # key=value line
#	    $key = $1;
#	    $val = $2;
#	    if ($val =~ m/^>>(.*)$/) {
#		$multiline = $1;
#		$val = "";
#	    } else {
#		$ini->{ $section }{ $key } = $val;
#		$key = "";
#	    }
#	}
#	elsif ($multiline && m/^$multiline$/) 
#	{
#	    chomp($ini->{ $section }{ $key });
#	    $multiline = ""; # End of multiline block
#	}
#	elsif ($multiline) 
#	{
#	    $ini->{ $section }{ $key } .= $_;
#	}
#    }
#    
#    close($fh) unless ($fh == $file);
#    
#    return $ini;
#}
#
#=head1 TEST SCRIPT FORMAT
#
#A test script is described in an Ini style file format.  Sections
#specify either tests or test groupings.  Each test defined is
#executed by calling a function of the same name as the test, 
#prefixed with "test_".  Consider the following sample file:
#
#------------------------------------------------
#[testgroup system]
#desc = Tests of system stuff
#
#[test system_rcs]
#desc=Check RCS system software and version
#
#[testgroup rlog]
#desc=Tests of rlog functionality
#
#[test rlog1]
#desc= Rlog test #1
#
#[test rlog2]
#desc= Rlog test2
#-------------------------------------------------
#
#This test script defines two test groups "system", and "rlog".
#Within the "system" group is a single test "system_rcs".  To
#execute this test, the run_test_script() driver will call the
#function "test_system_rcs".   
#
#Tests *must* have unique names, even across test groups. Tests
#that are not specified as part of a particular test group are
#placed into the group "default".


#
# compare
#
# lifted from File::Compare in perl5.004 dist
#

sub compare {
    croak("Usage: compare( file1, file2 [, buffersize]) ")
      unless(@_ == 2 || @_ == 3);

    my $Too_Big = 1024 * 1024 * 2;
    my $from = shift;
    my $to = shift;
    my $closefrom=0;
    my $closeto=0;
    my ($size, $fromsize, $status, $fr, $tr, $fbuf, $tbuf);
    local(*FROM, *TO);
    local($\) = '';

    croak("from undefined") unless (defined $from);
    croak("to undefined") unless (defined $to);

    if (ref($from) && (isa($from,'GLOB') || isa($from,'IO::Handle'))) {
        *FROM = *$from;
    } elsif (ref(\$from) eq 'GLOB') {
        *FROM = $from;
    } else {
        open(FROM,"<$from") or goto fail_open1;
        binmode FROM;
        $closefrom = 1;
        $fromsize = -s FROM;
    }

    if (ref($to) && (isa($to,'GLOB') || isa($to,'IO::Handle'))) {
        *TO = *$to;
    } elsif (ref(\$to) eq 'GLOB') {
        *TO = $to;
    } else {
        open(TO,"<$to") or goto fail_open2;
        binmode TO;
        $closeto = 1;
    }

    if ($closefrom && $closeto) {
        # If both are opened files we know they differ if their size differ
        goto fail_inner if $fromsize != -s TO;
    }

    if (@_) {
        $size = shift(@_) + 0;
        croak("Bad buffer size for compare: $size\n") unless ($size > 0);
    } else {
        $size = $fromsize;
        $size = 1024 if ($size < 512);
        $size = $Too_Big if ($size > $Too_Big);
    }

    $fbuf = '';
    $tbuf = '';
    while(defined($fr = read(FROM,$fbuf,$size)) && $fr > 0) {
        unless (defined($tr = read(TO,$tbuf,$fr)) and $tbuf eq $fbuf) {
            goto fail_inner;
        }
    }
    goto fail_inner if (defined($tr = read(TO,$tbuf,$size)) && $tr > 0);

    close(TO) || goto fail_open2 if $closeto;
    close(FROM) || goto fail_open1 if $closefrom;

    return 0;
    
    # All of these contortions try to preserve error messages...
  fail_inner:
    close(TO) || goto fail_open2 if $closeto;
    close(FROM) || goto fail_open1 if $closefrom;

    return 1;

  fail_open2:
    if ($closefrom) {
        $status = $!;
        $! = 0;
        close FROM;
        $! = $status unless $!;
    }
  fail_open1:
    return -1;
}


1;

