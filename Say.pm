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

use 5.008;
 
no warnings; # in case they've been turned on
 
#$VERSION = '1.0401';
 
use strict;
 
#open(REALSTDOUT, ">&STDOUT");
 
# do this late to avoid bogus warning about only using REALSTDOUT once
use warnings;
 
use Exporter;
use IO::Handle;

use ASoS::Constants qw(:COLORS :SIZE);

our @ISA = qw(Exporter);
our @EXPORT = qw(%say);
our @EXPORT_OK = qw(msg);
our %EXPORT_TAGS = (
    ALL => \@EXPORT_OK
);

$| = 1;

our %say = (
    failed => \&failed,
    info => \&info,
    msg => \&msg,
    print => \&msg,
    ok => \&ok,
    warn => \&warn,
    prompt => \&prompt
);

# - Position the Cursor:
#   \033[<L>;<C>H
#      Or
#   \033[<L>;<C>f
#   puts the cursor at line L and column C.
# - Move the cursor up N lines:
#   \033[<N>A
# - Move the cursor down N lines:
#   \033[<N>B
# - Move the cursor forward N columns:
#   \033[<N>C
# - Move the cursor backward N columns:
#   \033[<N>D

# - Clear the screen, move to (0,0):
#   \033[2J
# - Erase to end of line:
#   \033[K

# - Save cursor position:
#   \033[s
# - Restore cursor position:
#   \033[u


#sub import {
#    my $class = shift;
#    my %params = @_;
#    tie *STDOUT, $class, %params;
#}
 
# sub TIEHANDLE {
#     my($class, %params) = @_;
#     my $self = {
#         print => $params{print} || sub { print @_; },
#         syswrite => $params{syswrite} || sub {
#             my($buf, $len, $offset) = @_;
#             syswrite(STDOUT, $buf, $len, defined($offset) ? $offset : 0);
#         }
#     };
#     $self->{printf} = $params{printf} || sub {
#         $self->{print}->(sprintf($_[0], @_[1 .. $#_]))
#     };
#     bless($self, $class);
# }
 
# sub _with_real_STDOUT {
#     open(local *STDOUT, ">&REALSTDOUT");
#     $_[0]->(@_[1 .. $#_]);
# }
 
# sub PRINT  { _with_real_STDOUT(shift()->{print},  "test1", @_); }
# sub PRINTF { _with_real_STDOUT(shift()->{printf}, @_); }
# sub WRITE  { _with_real_STDOUT(shift()->{syswrite}, @_); }

sub msg {
    shift if $_[0] eq __PACKAGE__;
    my $width = TERM_WIDTH();

    foreach my $line (@_) {
        my $str = $line;
        chomp $str;
        my $pad = $width - length($str);
        $str = substr($str,0,$width-3).WHITE.'...'.DEFAULT if length($str) > $width;
        print "\r".(' ' x $width)."\r".WHITE.'[      ] '.DEFAULT.$str.DEFAULT;
    }
}

sub ok {
    shift if $_[0] eq __PACKAGE__;
    my $width = TERM_WIDTH();

    foreach my $line (@_) {
        my $str = $line;
        chomp $str;
        $str = substr($str,0,$width-3).WHITE.'...'.DEFAULT if length($str) > $width;
        print "\r".(' ' x $width)."\r".WHITE."[".GREEN."  OK  ".WHITE."] ".DEFAULT.$str."\n";
    }
}

sub info {
    shift if $_[0] eq __PACKAGE__;
    my $width = TERM_WIDTH();

    foreach my $line (@_) {
        my $str = $line;
        chomp $str;
        $str = substr($str,0,$width-3).WHITE.'...'.DEFAULT if length($str) > $width;
        print "\r".(' ' x $width)."\r".WHITE."[".LIGHTBLUE." INFO ".WHITE."] ".DEFAULT.$str."\n";
    }
}

sub warn {
    shift if $_[0] eq __PACKAGE__;
    my $width = TERM_WIDTH();

    foreach my $line (@_) {
        my $str = $line;
        chomp $str;
        $str = substr($str,0,$width-3).WHITE.'...'.DEFAULT if length($str) > $width;
        print "\r".(' ' x $width)."\r".WHITE."[".YELLOW." WARN ".WHITE."] ".DEFAULT.$str."\n";
    }
}

sub failed {
    shift if $_[0] eq __PACKAGE__;
    my $width = TERM_WIDTH();

    foreach my $line (@_) {
        my $str = $line;
        chomp $str;
        $str = substr($str,0,$width-3).WHITE.'...'.DEFAULT if length($str) > $width;
        print "\r".(' ' x $width)."\r".WHITE."[".RED."FAILED".WHITE."] ".DEFAULT.$str."\n";
    }
}

sub prompt {
    shift if $_[0] eq __PACKAGE__;
    my $width = TERM_WIDTH();

    foreach my $line (@_) {
        my $str = $line;
        chomp $str;
        $str = substr($str,0,$width-3).WHITE.'...'.DEFAULT if length($str) > $width;
        print "\r".(' ' x $width)."\r".WHITE."[".MAGENTA."PROMPT".WHITE."] ".DEFAULT.$str;
    }
}


1;