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
use Term::ReadKey qw(GetTerminalSize);
use IO::Handle;

use ASoS::Constants qw(:COLORS);

our @ISA = qw(Exporter);
our @EXPORT = qw();
our @EXPORT_OK = qw();
our %EXPORT_TAGS = (
    ALL => \@EXPORT_OK
);

my ($cols, $rows, $xpix, $ypix) = GetTerminalSize();
my $WIDTH = $cols - 12;

$| = 1;

sub msg {
    shift if $_[0] eq __PACKAGE__;

    foreach my $line (@_) {
        my $str = $line;
        chomp $str;
        my $pad = $WIDTH - length($str);
        $str = substr($str,0,$WIDTH-3).WHITE.'...'.DEFAULT if length($str) > $WIDTH;
        print "\r".WHITE.'[      ] '.DEFAULT.$str.(' ' x $pad).DEFAULT;
    }
}

sub ok {
    shift if $_[0] eq __PACKAGE__;

    foreach my $line (@_) {
        my $str = $line;
        chomp $str;
        my $pad = $WIDTH - length($str);
        $str = substr($str,0,$WIDTH-3).WHITE.'...'.DEFAULT if length($str) > $WIDTH;
        print "\r".WHITE."[".GREEN."  OK  ".WHITE."] ".DEFAULT.$str.(' ' x $pad).DEFAULT."\n";
    }
}

sub info {
    shift if $_[0] eq __PACKAGE__;

    foreach my $line (@_) {
        my $str = $line;
        chomp $str;
        my $pad = $WIDTH - length($str);
        $str = substr($str,0,$WIDTH-3).WHITE.'...'.DEFAULT if length($str) > $WIDTH;
        print "\r".WHITE."[".LIGHTBLUE." INFO ".WHITE."] ".DEFAULT.$str.(' ' x $pad).DEFAULT."\n";
    }
}

sub warn {
    shift if $_[0] eq __PACKAGE__;

    foreach my $line (@_) {
        my $str = $line;
        chomp $str;
        my $pad = $WIDTH - length($str);
        $str = substr($str,0,$WIDTH-3).WHITE.'...'.DEFAULT if length($str) > $WIDTH;
        print "\r".WHITE."[".YELLOW." WARN ".WHITE."] ".DEFAULT.$str.(' ' x $pad).DEFAULT."\n";
    }
}

sub failed {
    shift if $_[0] eq __PACKAGE__;

    foreach my $line (@_) {
        my $str = $line;
        chomp $str;
        my $pad = $WIDTH - length($str);
        $str = substr($str,0,$WIDTH-3).WHITE.'...'.DEFAULT if length($str) > $WIDTH;
        print "\r".WHITE."[".RED."FAILED".WHITE."] ".DEFAULT.$str.(' ' x $pad).DEFAULT."\n";
    }
}

1;