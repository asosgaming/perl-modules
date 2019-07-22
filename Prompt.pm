package ASoS::Prompt;

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

use ASoS::CPAN;
use ASoS::Say;
use ASoS::Log;
use ASoS::Pkg;
use ASoS::Constants qw(:OS :LEVELS :COLORS);

$CPAN{install}->("IO::Prompter") if not $CPAN{isInstalled}->("IO::Prompter"); 

use local::lib;
use IO::Prompter;

our @ISA = qw(Exporter);
our @EXPORT = qw(%prompt);
our @EXPORT_OK = qw();
our %EXPORT_TAGS = (
    ALL => \@EXPORT_OK
);

our %prompt = (
    name => \&name,
    number => \&number,
    string => \&string,
    word => \&word,
    domain => \&domain,
    phone => \&phone,
    path => \&path,
    file => \&file,
    pause => \&pause
);

sub testing { print "hello";}

sub number {}
sub string {
    my ($value, $name) = (shift, shift);
    $say{prompt}->("Enter ".$name." [".${$value}."] ");
    ${$value} = prompt(-default => ${$value}, -stdio, @_);
    print "\e[1A";
    $say{ok}->(DEFAULT.ucfirst($name)." set to '".WHITE.${$value}.DEFAULT."'");
}
sub word {}
sub domain {}
sub phone {}
sub path {}
sub file {
    my ($value, $name) = (shift, shift);
    $say{prompt}->("Enter ".$name." [".${$value}."] ");
    ${$value} = prompt(-default => ${$value}, -stdio, -filenames, @_);
    print "\e[1A";
    $say{ok}->(DEFAULT.ucfirst($name)." set to '".WHITE.${$value}.DEFAULT."'");
}
sub pause {}

1;