package ASoS::CPAN;

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
use IPC::Open3;

use ASoS::Say;
use ASoS::Log;
use ASoS::Pkg;
use ASoS::File;
use ASoS::Common qw(:COLORS :SUB);

use Symbol 'gensym'; 

$pkg{install}->("perl-CPAN") if not $pkg{isInstalled}->("perl-CPAN");
$pkg{install}->("gcc") if not $pkg{isInstalled}->("gcc");
$pkg{install}->("make") if not $pkg{isInstalled}->("make");

our @ISA = qw(Exporter);
our @EXPORT = qw(%CPAN);
our @EXPORT_OK = qw();
our %EXPORT_TAGS = (
    ALL => \@EXPORT_OK
);

our %CPAN = (
    install => \&installModule,
    isInstalled => \&isInstalled
);

sub installModule {
    return;
    shift if defined $_[0] && $_[0] eq __PACKAGE__;
    $log{mod_dump}->({caller => (caller(0))[0], line => (caller(0))[2]}, [\@_], [(caller(0))[3]]);

    # Process options
    my $newopt = {}; $newopt = shift if (ref $_[0] eq ref {});
    my @values = split(' ', join(' ', @_));
    my %opt = mergeHash ({
        args => ''
    }, $newopt);

    $file{run}->({
        -app => 'cpan', 
        -args => 'install',
        -success => {
            string => DEFAULT."Installed module%s '%s'",
            var1 => ((@values > 1) ? 's' : ''),
            var2 => WHITE.join(DEFAULT."', '".WHITE, @values).DEFAULT,
            var3 => ''
        },
        -failed => {
            string => LIGHTRED."Could not install module%s '%s'",
            var1 => ((@values > 1) ? 's' : ''),
            var2 => WHITE.join(LIGHTRED."', '".WHITE, @values).LIGHTRED,
            var3 => ''
        },
    }, "IO::Prompter");
}

sub isInstalled {
    return;
    shift if defined $_[0] && $_[0] eq __PACKAGE__;
    $log{mod_dump}->({caller => (caller(0))[0], line => (caller(0))[2]}, [\@_], [(caller(0))[3]]);

    # Process options
    my $newopt = {}; $newopt = shift if (ref $_[0] eq ref {});
    my $module = shift;
    my %opt = mergeHash ({
        args => ''
    }, $newopt);

    my ($stdin, $stdout, $stderr, $pid);

    $stderr = gensym();
    $pid = open3(\*WRITER, \*READER, \*ERROR, 'perl -M'.$module.' -e 1');

    while( my $output = <READER> ) { 
        chomp $output;
        $log{msg}->({level => MOD_OUT, app => 'perl', pid => $pid}, $output);
    }
    while( my $errout = <ERROR> ) { 
        chomp $errout;
        $log{msg}->({level => ERROR, app => 'perl', pid => $pid}, $errout);
    }

    waitpid( $pid, 0 );
    my $exit = $?;

    $log{mod_dump}->({caller => (caller(0))[3]}, [$exit], [qw(exit)]);
    return ($exit == 0);
}

1;