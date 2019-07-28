
package ASoS::Pkg;

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
use File::Basename;
use IPC::Open3;

use ASoS::Say;
use ASoS::Log;
use ASoS::Common qw(:COLORS :TRIM :SUB :UTILS);
use ASoS::File;
use ASoS::Subs;

use Symbol 'gensym'; 

our @ISA = qw(Exporter);
our @EXPORT = qw(%pkg);
our @EXPORT_OK = qw(info install installed isInstalled remove search);
our %EXPORT_TAGS = (
    ALL => \@EXPORT_OK
);

our %pkg = (
    info => \&info,
    install => \&install,
    installed => \&installed,
    isInstalled => \&isInstalled,
    remove => \&remove,
    search => \&search
);

my @FIND = ("Arch", "Version", "Release", "Size", "Repo", "From repo", "Summary", "URL", "License");

#TODO: Adjust based on distro
sub info {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    my %opt = mergeOptions ({
        -args => 'info',
        -app => 'yum'
    }, toHash(@_));
    
    my ($stdin, $stdout, $stderr, $pid);
    my @packages = ();
    my $index = -1;

    $stderr = gensym();
    $pid = open3(\*WRITER, \*READER, \*ERROR, $opt{cmd});

    while( my $output = <READER> ) { 
        chomp $output;
        if ($output =~ m/ : /) {
            my @val = split ' : ', $output;
            my ($key, $value) = (trim($val[0]), trim($val[1]));
            if ($key eq "Name") { 
                push @packages, {
                    Name => trim($val[1]),
                };
                $index++;
            } elsif ($key ~~ @FIND) {
                $packages[$index]{$key} = $value;
            }
        }
    }
    while( my $errout = <ERROR> ) { 
        chomp $errout;
        $log{msg}->({level => ERROR, app => $opt{app}, pid => $opt{pid}}, $errout);
    }

    waitpid( $pid, 0 );
    my $exit = $?;

    $log{mod_dump}->({caller => (caller(0))[3]}, [$exit, \@packages], [qw(exit *return)]);
    return @packages;
}

sub installed {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

     my %opt = mergeOptions ({
        -args => 'info installed',
        -app => 'yum'
    }, toHash(@_));

    my ($stdin, $stdout, $stderr, $pid);
    my @packages = ();
    my $index = -1;

    $stderr = gensym();
    $pid = open3(\*WRITER, \*READER, \*ERROR, $opt{cmd});

    while( my $output = <READER> ) { 
        chomp $output;
        if ($output =~ m/ : /) {
            my @val = split ' : ', $output;
            my ($key, $value) = (trim($val[0]), trim($val[1]));
            if ($key eq "Name") { 
                push @packages, {
                    Name => trim($val[1]),
                };
                $index++;
            } elsif ($key ~~ @FIND) {
                $packages[$index]{$key} = $value;
            }
        }
    }
    while( my $errout = <ERROR> ) { 
        chomp $errout;
        $log{msg}->({level => ERROR, app => $opt{app}, pid => $opt{pid}}, $errout);
    }

    waitpid( $pid, 0 );
    my $exit = $?;

    $log{mod_dump}->({caller => (caller(0))[3]}, [$exit, \@packages], [qw(exit *return)]);
    return @packages;
}

sub search {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

     my %opt = mergeOptions ({
        -args => 'search',
        -app => 'yum'
    }, toHash(@_));

    my ($stdin, $stdout, $stderr, $pid);
    my @packages = ();

    $stderr = gensym();
    $pid = open3(\*WRITER, \*READER, \*ERROR, $opt{cmd});

    while( my $output = <READER> ) { 
        chomp $output;
        if ($output =~ m/ : /) {
            my @val = split ' : ', $output;
            my @tmp = split(/\.([^\.]+)$/, $val[0]);
            push @packages, {
                Name => $tmp[0],
                Arch => $tmp[1],
                Summary => $val[1],
            };
        }
    }
    while( my $errout = <ERROR> ) { 
        chomp $errout;
        $log{msg}->({level => ERROR, app => $opt{app}, pid => $opt{pid}}, $errout);
    }

    waitpid( $pid, 0 );
    my $exit = $?;

    $log{mod_dump}->({caller => (caller(0))[3]}, [$exit, \@packages], [qw(exit *return)]);
    return @packages;
}

#TODO: Add support for multiple os
sub install {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    # read options and init hash with arrays
    my %newopts = toHash(@_, -installed => [], -notinstalled => []);

    # check if packages are installed and push to new arrays
    foreach my $pkg (@{$newopts{-values}}) {
        isInstalled($pkg) 
            and push (@{$newopts{-installed}}, $pkg) 
            or push (@{$newopts{-notinstalled}}, $pkg);
    }

    # merge newopts into options
    my %opt = mergeOptions ({
        -app => 'yum',
        -mainargs => 'install -y',
        -args => undef,
        -output => 1
    }, %newopts, -dump => 0);

    # exit if nothing to install
    if (!@{$opt{-notinstalled}}) {
        $say{INFO}->(
            formatString("Package%1 %3 %2 already installed", [
                ((@{$opt{-installed}} > 1) ? 's' : ''),
                ((@{$opt{-installed}} > 1) ? 'are' : 'is'),
                DEFAULT."'".WHITE.join(DEFAULT."', '".WHITE, @{$opt{-installed}}).DEFAULT."'"
            ])
        );
        return 1;
    }
    
    # create command
    makeCMD(\%opt, @{$opt{-notinstalled}}) or return 0;

    # run command
    my %output = $file{run}->(%opt, 
        -module => 1,
        -output => 1,
        -success => DEFAULT."Installed package%1 %2",
        -failed => LIGHTRED."Unable to install package%1 %3",
        -vars => [
                ((@{$opt{-notinstalled}} > 1) ? 's' : ''),
                DEFAULT."'".WHITE.join(DEFAULT."', '".WHITE, @{$opt{-notinstalled}}).DEFAULT."'",
                LIGHTRED."'".WHITE.join(LIGHTRED."', '".WHITE, @{$opt{-notinstalled}}).LIGHTRED."'"
            ],
        @{$opt{-values}}
    );

    return ($output{exit} == 0);
}

#TODO: Add support for multiple os
sub remove {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    # read options and init hash with arrays
    my %newopts = toHash(@_, -installed => [], -notinstalled => []);

    # check if packages are installed and push to new arrays
    foreach my $pkg (@{$newopts{-values}}) {
        isInstalled($pkg) 
            and push (@{$newopts{-installed}}, $pkg) 
            or push (@{$newopts{-notinstalled}}, $pkg);
    }

    # merge newopts into options
    my %opt = mergeOptions ({
        -app => 'yum',
        -mainargs => 'remove -y',
        -args => undef,
        -output => 1
    }, %newopts, -dump => 0);

    # exit if nothing to remove
    if (!@{$opt{-installed}}) {
        $say{INFO}->(
            formatString("Package%1 %3 %2 not installed", [
                ((@{$opt{-notinstalled}} > 1) ? 's' : ''),
                ((@{$opt{-notinstalled}} > 1) ? 'are' : 'is'),
                DEFAULT."'".WHITE.join(DEFAULT."', '".WHITE, @{$opt{-notinstalled}}).DEFAULT."'"
            ])
        );
        return 1;
    }
    
    # create command
    makeCMD(\%opt, @{$opt{-installed}}) or return 0;

    # run command
    my %output = $file{run}->(%opt, 
        -module => 1,
        -output => 1,
        -success => DEFAULT."Removed package%1 %2",
        -failed => LIGHTRED."Unable to remove package%1 %3",
        -vars => [
                ((@{$opt{-installed}} > 1) ? 's' : ''),
                DEFAULT."'".WHITE.join(DEFAULT."', '".WHITE, @{$opt{-installed}}).DEFAULT."'",
                LIGHTRED."'".WHITE.join(LIGHTRED."', '".WHITE, @{$opt{-installed}}).LIGHTRED."'"
            ],
        @{$opt{-values}}
    );

    return ($output{exit} == 0);






















    #  my %opt = mergeOptions ({
    #     -args => 'remove -y',
    #     -app => 'yum'
    # }, toHash(@_));

    # $opt{installed} = [];
    # $opt{notinstalled} = [];

    # foreach my $pkg (@{$opt{pkgs}}) {
    #     if (isInstalled($pkg)) {
    #         push @{ $opt{installed} }, $pkg;
    #     } else {
    #         push @{ $opt{notinstalled} }, $pkg;
    #     }
    # }

    # # Set cmd and log
    # $opt{cmd} .= ' '.(($opt{args}) ? $opt{args}.' ' : '').join(' ', @{$opt{installed}});
    # $log{mod_dump}->({caller => (caller(0))[3], line => ''}, [\%opt], [qw(opt)]);
    # return 1 if not @{$opt{installed}};
    # $log{msg}->({level => CMD, caller => (caller(0))[0], line => (caller(0))[2]}, $opt{cmd});
    # $say{MSG}->($opt{cmd});

    # my ($stdin, $stdout, $stderr, $pid);
    # my ($t1, $t2, $t3) = ('', 'is', '');

    # if (@{$opt{notinstalled}} > 1) { ($t1, $t2) = ('s', 'are'); }
    # if (@{$opt{installed}} > 1) { $t3 = 's'; }

    # $say{INFO}->(DEFAULT."Package$t1 '".WHITE.join(DEFAULT."', '".WHITE, @{$opt{notinstalled}}).DEFAULT."' $t2 not installed.") if @{$opt{notinstalled}};

    # if (@{$opt{installed}}) {
    #     $stderr = gensym();
    #     $pid = open3(\*WRITER, \*READER, \*ERROR, $opt{cmd});

    #     while( my $output = <READER> ) { 
    #         chomp $output;
    #         $log{msg}->({level => OUT, app => $opt{app}, pid => $pid}, $output);
    #         $say{MSG}->($output); 
    #     }
    #     while( my $errout = <ERROR> ) { 
    #         chomp $errout;
    #         $log{msg}->({level => ERROR, app => $opt{app}, pid => $opt{pid}}, $errout);
    #         $say{MSG}->(RED.$errout.DEFAULT); 
    #     }

    #     waitpid( $pid, 0 );
    #     my $exit = $?;

    #     $log{mod_dump}->({caller => (caller(0))[3]}, [$exit], [qw(exit)]);
    #     if ($exit == 0) { 
    #         $say{OK}->(DEFAULT."Removed package$t3 '".WHITE.join(DEFAULT."', '".WHITE, @{$opt{installed}}).DEFAULT."'");
    #     } else { 
    #         $say{FAILED}->(DEFAULT."Unable to remove package$t3 '".WHITE.join(DEFAULT."', '".WHITE, @{$opt{installed}}).DEFAULT."'");
    #     }
    #     return ($exit == 0);
    # }

    # return 1;
}

sub isInstalled {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    my %opt = mergeOptions ({
        -app => 'rpm',
        -mainargs => '-q',
        -args => undef,
        -output => 0
    }, toHash(@_), -dump => 0);

    my %output = $file{run}->(%opt, 
        -module => 1,
        @{$opt{-values}}
    );

    return ($output{exit} == 0);
}

sub version {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;
}

1;