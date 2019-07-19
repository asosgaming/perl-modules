package ASoS::Utils;

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

our @ISA = qw(Exporter);
our @EXPORT = qw(ltrim rtrim trim removeQuotes mergeHash);

sub ltrim { my $s = shift; return if not $s; $s =~ s/^\s+//;       return $s };

sub rtrim { my $s = shift; return if not $s; $s =~ s/\s+$//;       return $s };

sub  trim { my $s = shift; return if not $s; $s =~ s/^\s+|\s+$//g; return $s };

sub removeQuotes { my $s = shift; return if not $s; $s =~ s/"//g; return $s };

sub mergeHash {
    my $hash1 = $_[0];
    my $hash2 = $_[1];
    my %newhash = ();

    foreach my $key (keys %{$hash2})
    {
        if (exists $hash1->{$key}) {
            ${hash1}->{$key} = ${hash2}->{$key} if (defined ${hash2}->{$key});
        } else {
            ${hash1}->{$key} = ${hash2}->{$key};
        }
    }

    foreach my $key (keys %{$hash1}) {
        ${hash1}->{$key} = '' if not defined ${hash1}->{$key};
        $newhash{$key} = ${hash1}->{$key};
    }

    return %newhash;
}
1;