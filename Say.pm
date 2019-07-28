package ASoS::Say;

################################################################################
# Copyright Ⓒ 2019 ASoS Gaming
################################################################################
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
################################################################################

use v5.10;
use strict;
use warnings;
use Exporter;
use IO::Handle;

use ASoS::Common qw(%TERM %RESULT :COLORS);

our @ISA = qw(Exporter);
our @EXPORT = qw(%say);

our %say = (
    MSG => \&msg,
    OK => \&ok,
    WARN => \&warn,
    INFO => \&info,
    FAILED => \&failed,
    READ => \&read,
    PROMPT => \&prompt
);

$| = 1;

my $header = sub {
    my ($status, $color, $newline) = (uc(shift), shift, shift);

    return $RESULT{ERROR} if (!@_);

    foreach my $line (@_) {
        my $str = $line;
        chomp $str;
        print $TERM{HIDE};
        print "\r".WHITE."[".$color.$status.WHITE."] ".DEFAULT;
        print $TERM{ERASE}.$str.DEFAULT;
        print "\n" if ($newline);
        print $TERM{SHOW};
    }

    return $RESULT{SUCCESS};
};

sub msg     { shift if defined $_[0] && $_[0] eq __PACKAGE__; return $header->("      ", WHITE, 0, @_); }
sub ok      { shift if defined $_[0] && $_[0] eq __PACKAGE__; return $header->("  OK  ", GREEN, 1, @_); }
sub info    { shift if defined $_[0] && $_[0] eq __PACKAGE__; return $header->(" INFO ", LIGHTBLUE, 1, @_); }
sub warn    { shift if defined $_[0] && $_[0] eq __PACKAGE__; return $header->(" WARN ", YELLOW, 1, @_); }
sub failed  { shift if defined $_[0] && $_[0] eq __PACKAGE__; return $header->("FAILED", RED, 1, @_); }
sub read    { shift if defined $_[0] && $_[0] eq __PACKAGE__; return $header->(" READ ", CYAN, 0, @_); }
sub prompt  { shift if defined $_[0] && $_[0] eq __PACKAGE__; return $header->("PROMPT", MAGENTA, 0, @_); }

1;