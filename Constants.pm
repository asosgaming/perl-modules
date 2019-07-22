package ASoS::Constants;

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
use Config;
use IPC::Open3;
use Term::ReadKey qw(GetTerminalSize);

use ASoS::Utils;

use Symbol 'gensym'; 

use constant LOGLEVELS => qw(OFF FTL ERR WRN INF CMD OUT DBG CMD OUT DBG);
use constant {
    OFF => 0,
    FATAL => 1,
    ERROR => 2,
    WARN => 3,
    INFO => 4,
    CMD => 5,
    OUT => 6,
    DEBUG => 7,
    MOD_CMD => 8,
    MOD_OUT => 9,
    MOD_DEBUG => 10,
};

use constant {
    DEFAULT => "\e[0m",
    BLACK => "\e[38;5;0m",
    RED => "\e[38;5;1m",
    GREEN => "\e[38;5;2m",
    YELLOW => "\e[38;5;3m",
    BLUE => "\e[38;5;4m",
    MAGENTA => "\e[38;5;5m",
    CYAN => "\e[38;5;6m",
    LIGHTGRAY => "\e[38;5;7m",
    DARKGRAY => "\e[38;5;8m",
    LIGHTRED => "\e[38;5;9m",
    LIGHTGREEN => "\e[38;5;10m",
    LIGHTYELLOW => "\e[38;5;11m",
    LIGHTBLUE => "\e[38;5;12m",
    LIGHTMAGENTA => "\e[38;5;13m",
    LIGHTCYAN => "\e[38;5;14m",
    WHITE => "\e[38;5;15m",
};

use constant {
    FALSE => 0,
    TRUE => 1
};

our @ISA = qw(Exporter);
our @EXPORT = qw();
our @EXPORT_OK = qw(
    HOSTNAME DOMAIN
    ARCH KERNEL KERNEL_VER VIRTUAL DISTRO OS_NAME IS_VM
    PERL_VERSION PERL_REVISION PERL_SUBVERSION PERL_VERSION_FULL
    LOGLEVELS OFF FATAL ERROR WARN INFO CMD OUT DEBUG MOD_CMD MOD_OUT MOD_DEBUG
    TERM_WIDTH TERM_HEIGHT
    TRUE FALSE
    DEFAULT BLACK RED GREEN YELLOW BLUE MAGENTA CYAN LIGHTGRAY DARKGRAY LIGHTRED LIGHTGREEN LIGHTYELLOW LIGHTBLUE LIGHTMAGENTA LIGHTCYAN WHITE
);
our %EXPORT_TAGS = (
    ALL => \@EXPORT_OK,
    HOST => [qw(HOSTNAME DOMAIN)],
    OS => [qw(ARCH KERNEL KERNEL_VER VIRTUAL DISTRO OS_NAME IS_VM)],
    PERL => [qw(PERL_VERSION PERL_REVISION PERL_SUBVERSION PERL_VERSION_FULL)],
    LEVELS => [qw(LOGLEVELS OFF FATAL ERROR WARN INFO CMD OUT DEBUG MOD_CMD MOD_OUT MOD_DEBUG)],
    SIZE => [qw(TERM_WIDTH TERM_HEIGHT)],
    BOOL => [qw(TRUE FALSE)],
    COLORS => [qw(DEFAULT BLACK RED GREEN YELLOW BLUE MAGENTA CYAN LIGHTGRAY DARKGRAY LIGHTRED LIGHTGREEN LIGHTYELLOW LIGHTBLUE LIGHTMAGENTA LIGHTCYAN WHITE)]
);

my %VALUES;
my ($stdin, $stdout, $stderr, $pid, $width);

sub TERM_WIDTH { my ($cols, $rows, $xpix, $ypix) = GetTerminalSize(); return $cols; }
sub TERM_HEIGHT { my ($cols, $rows, $xpix, $ypix) = GetTerminalSize(); return $rows; }
sub HOSTNAME { return $VALUES{'HOSTNAME'}; }
sub DOMAIN { return $VALUES{'DOMAIN'}; }
sub ARCH { return $VALUES{'Architecture'}; }
sub KERNEL { return substr($VALUES{'Kernel'}, 0, index($VALUES{'Kernel'}, ' ')); }
sub KERNEL_VER { return return substr($VALUES{'Kernel'}, index($VALUES{'Kernel'}, ' ')+1); }
sub VIRTUAL { return $VALUES{'Virtualization'}; }
sub DISTRO { return substr($VALUES{'Operating System'}, 0, index($VALUES{'Operating System'}, ' ')); }
sub PERL_VERSION { return $Config{'PERL_VERSION'}; }
sub PERL_REVISION { return $Config{'PERL_REVISION'}; }
sub PERL_SUBVERSION { return $Config{'PERL_SUBVERSION'}; }
sub PERL_VERSION_FULL { return $Config{'PERL_REVISION'}.'.'.$Config{'PERL_VERSION'}.'.'.$Config{'PERL_SUBVERSION'}; }
sub OS_NAME { return $Config{'osname'}; }

sub IS_VM { return ($VALUES{'Chassis'} eq "vm") ? 1 : 0; }

#TODO: change hostname to get/set
$VALUES{'HOSTNAME'} = qx(hostname -s); chomp $VALUES{'HOSTNAME'};
$VALUES{'DOMAIN'} = qx(hostname -f); chomp $VALUES{'DOMAIN'}; $VALUES{'DOMAIN'} =~ s/^[^\.]*\.//;

$stderr = gensym();
$pid = open3(\*WRITER, \*READER, \*ERROR, 'hostnamectl');

while( my $output = <READER> ) { 
    chomp $output;
    if ($output =~ m/: /) {
        my @val = split ': ', $output;
        my ($key, $value) = (trim($val[0]), trim($val[1]));
        $VALUES{$key} = $value if $key;
    }
}

waitpid( $pid, 0 );

1;