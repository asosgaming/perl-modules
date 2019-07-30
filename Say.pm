package ASoS::Say;

################################################################################
#* Copyright Ⓒ 2019 ASoS Gaming
################################################################################
#* Permission is hereby granted, free of charge, to any person obtaining a copy
#* of this software and associated documentation files (the "Software"), to deal
#* in the Software without restriction, including without limitation the rights
#* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#* copies of the Software, and to permit persons to whom the Software is
#* furnished to do so, subject to the following conditions:
#*
#* The above copyright notice and this permission notice shall be included in all
#* copies or substantial portions of the Software.
#*
#* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#* SOFTWARE.
################################################################################

use v5.10;
use strict;
use warnings;
use Exporter;
use IO::Handle;

use ASoS::Common qw(%TERM %RESULT :COLORS);

our @ISA = qw(Exporter);
our @EXPORT = qw(%say);

#! say functions
our %say = (
    MSG => \&msg,
    OK => \&ok,
    WARN => \&warn,
    INFO => \&info,
    FAILED => \&failed,
    READ => \&read,
    PROMPT => \&prompt
);

#! force a flush after every write or print
$| = 1;

#? main output
my $header = sub {
    my ($status, $color, $newline) = (uc(shift), shift, shift);

    #^ return error if nothing passed to sub
    return $RESULT{ERROR} if (!@_);

    #^ process and split newlines into a new array
    my @output = ();
    foreach my $line (@_) { push(@output, split("\n", $line)); }

    #^ loop through all output
    foreach my $line (@output) {
        my $str = $line;
        chomp $str;

        #. hide cursor
        print $TERM{HIDE};
        #. print line header
        print "\r".WHITE."[".$color.$status.WHITE."] ".DEFAULT;
        #. erase to end of line and print rest of line
        print $TERM{ERASE}.$str.DEFAULT;
        #. show cursor
        print $TERM{SHOW};
        #. print newline if set
        print "\n" if ($newline);
    }

    return $RESULT{SUCCESS};
};

#? print message without newline
sub msg     { shift if defined $_[0] && $_[0] eq __PACKAGE__; return $header->("      ", WHITE, 0, @_); }

#? print OK message
sub ok      { shift if defined $_[0] && $_[0] eq __PACKAGE__; return $header->("  OK  ", GREEN, 1, @_); }

#? print INFO message
sub info    { shift if defined $_[0] && $_[0] eq __PACKAGE__; return $header->(" INFO ", LIGHTBLUE, 1, @_); }

#? print WARN message
sub warn    { shift if defined $_[0] && $_[0] eq __PACKAGE__; return $header->(" WARN ", YELLOW, 1, @_); }

#? print FAILED message
sub failed  { shift if defined $_[0] && $_[0] eq __PACKAGE__; return $header->("FAILED", RED, 1, @_); }

#? print READ message without newline
sub read    { shift if defined $_[0] && $_[0] eq __PACKAGE__; return $header->(" READ ", CYAN, 0, @_); }

#? print PROMPT message without newline
sub prompt  { shift if defined $_[0] && $_[0] eq __PACKAGE__; return $header->("PROMPT", MAGENTA, 0, @_); }

1;