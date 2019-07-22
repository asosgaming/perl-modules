
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
use ASoS::Constants qw(:COLORS :LEVELS :OS);
use ASoS::Utils;
use ASoS::File;

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
    shift if $_[0] eq __PACKAGE__;
    $log{mod_dump}->({caller => (caller(0))[0], line => (caller(0))[2]}, [\@_], [(caller(0))[3]]);

    # Process options
    my $newopt = {}; $newopt = shift if (ref $_[0] eq ref {});
    my @values = split(' ', join(' ', @_));
    my %opt = mergeHash ({
        args => '',
        app => 'yum',
        pkgs => \@values,
        cmd => 'yum info'
    }, $newopt);
    
    # Set cmd and log
    $opt{cmd} .= ' '.(($opt{args}) ? $opt{args}.' ' : '').join(' ', @{$opt{pkgs}});
    $log{mod_dump}->({caller => (caller(0))[3], line => ''}, [\%opt], [qw(opt)]);
    $log{msg}->({level => MOD_CMD, caller => (caller(0))[0], line => (caller(0))[2]}, $opt{cmd});

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
    shift if $_[0] eq __PACKAGE__;
    $log{mod_dump}->({caller => (caller(0))[0], line => (caller(0))[2]}, [\@_], [(caller(0))[3]]);

    # Process options
    my $newopt = {}; $newopt = shift if (ref $_[0] eq ref {});
    my @values = split(' ', join(' ', @_));
    my %opt = mergeHash ({
        args => '',
        app => 'yum',
        pkgs => \@values,
        cmd => 'yum info'
    }, $newopt);
    
    # Set cmd and log
    $opt{cmd} .= ' '.(($opt{args}) ? $opt{args}.' ' : '').'installed';
    $log{mod_dump}->({caller => (caller(0))[3], line => ''}, [\%opt], [qw(opt)]);
    $log{msg}->({level => MOD_CMD, caller => (caller(0))[0], line => (caller(0))[2]}, $opt{cmd});

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
    shift if $_[0] eq __PACKAGE__;
    $log{mod_dump}->({caller => (caller(0))[0], line => (caller(0))[2]}, [\@_], [(caller(0))[3]]);

    # Process options
    my $newopt = {}; $newopt = shift if (ref $_[0] eq ref {});
    my @values = split(' ', join(' ', @_));
    my %opt = mergeHash ({
        args => '',
        app => 'yum',
        pkgs => \@values,
        cmd => 'yum search'
    }, $newopt);
    
    # Set cmd and log
    $opt{cmd} .= ' '.(($opt{args}) ? $opt{args}.' ' : '').join(' ', @{$opt{pkgs}});
    $log{mod_dump}->({caller => (caller(0))[3], line => ''}, [\%opt], [qw(opt)]);
    $log{msg}->({level => MOD_CMD, caller => (caller(0))[0], line => (caller(0))[2]}, $opt{cmd});

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

sub install {
    shift if $_[0] eq __PACKAGE__;
    $log{mod_dump}->({caller => (caller(0))[0], line => (caller(0))[2]}, [\@_], [(caller(0))[3]]);

    # Process options
    my $newopt = {}; $newopt = shift if (ref $_[0] eq ref {});
    my @values = split(' ', join(' ', @_));
    my %opt = mergeHash ({
        args => '',
        app => 'yum',
        pkgs => \@values,
        cmd => 'yum install -y'
    }, $newopt);
    
    $opt{installed} = [];
    $opt{notinstalled} = [];

    foreach my $pkg (@{$opt{pkgs}}) {
        if (isInstalled($pkg)) {
            push @{ $opt{installed} }, $pkg;
        } else {
            push @{ $opt{notinstalled} }, $pkg;
        }
    }

    # Set cmd and log
    $opt{cmd} .= ' '.(($opt{args}) ? $opt{args}.' ' : '').join(' ', @{$opt{notinstalled}});
    $log{mod_dump}->({caller => (caller(0))[3], line => ''}, [\%opt], [qw(opt)]);
    return 1 if not @{$opt{notinstalled}};
    $log{msg}->({level => CMD, caller => (caller(0))[0], line => (caller(0))[2]}, $opt{cmd});
    $say{msg}->($opt{cmd});

    my ($stdin, $stdout, $stderr, $pid);
    my ($t1, $t2, $t3) = ('', 'is', '');

    if (@{$opt{installed}} > 1) { ($t1, $t2) = ('s', 'are'); }
    if (@{$opt{notinstalled}} > 1) { $t3 = 's'; }

    $say{info}->(DEFAULT."Package$t1 '".WHITE.join(DEFAULT."', '".WHITE, @{$opt{installed}}).DEFAULT."' $t2 already installed.") if @{$opt{installed}};

    if (@{$opt{notinstalled}}) {
        $stderr = gensym();
        $pid = open3(\*WRITER, \*READER, \*ERROR, $opt{cmd});

        while( my $output = <READER> ) { 
            chomp $output;
            $log{msg}->({level => OUT, app => $opt{app}, pid => $pid}, $output);
            $say{msg}->($output); 
        }
        while( my $errout = <ERROR> ) { 
            chomp $errout;
            $log{msg}->({level => ERROR, app => $opt{app}, pid => $opt{pid}}, $errout);
            $say{msg}->(RED.$errout.DEFAULT); 
        }

        waitpid( $pid, 0 );
        my $exit = $?;

        $log{mod_dump}->({caller => (caller(0))[3]}, [$exit], [qw(exit)]);
        if ($exit == 0) { 
            $say{ok}->(DEFAULT."Installed package$t3 '".WHITE.join(DEFAULT."', '".WHITE, @{$opt{notinstalled}}).DEFAULT."'");
        } else { 
            $say{failed}->(DEFAULT."Unable to install package$t3 '".WHITE.join(DEFAULT."', '".WHITE, @{$opt{notinstalled}}).DEFAULT."'");
        }
        return ($exit == 0);
    }

    return 1;
}

sub remove {
    shift if $_[0] eq __PACKAGE__;
    $log{mod_dump}->({caller => (caller(0))[0], line => (caller(0))[2]}, [\@_], [(caller(0))[3]]);

    # Process options
    my $newopt = {}; $newopt = shift if (ref $_[0] eq ref {});
    my @values = split(' ', join(' ', @_));
    my %opt = mergeHash ({
        args => '',
        app => 'yum',
        pkgs => \@values,
        cmd => 'yum remove -y'
    }, $newopt);

    $opt{installed} = [];
    $opt{notinstalled} = [];

    foreach my $pkg (@{$opt{pkgs}}) {
        if (isInstalled($pkg)) {
            push @{ $opt{installed} }, $pkg;
        } else {
            push @{ $opt{notinstalled} }, $pkg;
        }
    }

    # Set cmd and log
    $opt{cmd} .= ' '.(($opt{args}) ? $opt{args}.' ' : '').join(' ', @{$opt{installed}});
    $log{mod_dump}->({caller => (caller(0))[3], line => ''}, [\%opt], [qw(opt)]);
    return 1 if not @{$opt{installed}};
    $log{msg}->({level => CMD, caller => (caller(0))[0], line => (caller(0))[2]}, $opt{cmd});
    $say{msg}->($opt{cmd});

    my ($stdin, $stdout, $stderr, $pid);
    my ($t1, $t2, $t3) = ('', 'is', '');

    if (@{$opt{notinstalled}} > 1) { ($t1, $t2) = ('s', 'are'); }
    if (@{$opt{installed}} > 1) { $t3 = 's'; }

    $say{info}->(DEFAULT."Package$t1 '".WHITE.join(DEFAULT."', '".WHITE, @{$opt{notinstalled}}).DEFAULT."' $t2 not installed.") if @{$opt{notinstalled}};

    if (@{$opt{installed}}) {
        $stderr = gensym();
        $pid = open3(\*WRITER, \*READER, \*ERROR, $opt{cmd});

        while( my $output = <READER> ) { 
            chomp $output;
            $log{msg}->({level => OUT, app => $opt{app}, pid => $pid}, $output);
            $say{msg}->($output); 
        }
        while( my $errout = <ERROR> ) { 
            chomp $errout;
            $log{msg}->({level => ERROR, app => $opt{app}, pid => $opt{pid}}, $errout);
            $say{msg}->(RED.$errout.DEFAULT); 
        }

        waitpid( $pid, 0 );
        my $exit = $?;

        $log{mod_dump}->({caller => (caller(0))[3]}, [$exit], [qw(exit)]);
        if ($exit == 0) { 
            $say{ok}->(DEFAULT."Removed package$t3 '".WHITE.join(DEFAULT."', '".WHITE, @{$opt{installed}}).DEFAULT."'");
        } else { 
            $say{failed}->(DEFAULT."Unable to remove package$t3 '".WHITE.join(DEFAULT."', '".WHITE, @{$opt{installed}}).DEFAULT."'");
        }
        return ($exit == 0);
    }

    return 1;
}

sub isInstalled {
    shift if $_[0] eq __PACKAGE__;
    $log{mod_dump}->({caller => (caller(0))[0], line => (caller(0))[2]}, [\@_], [(caller(0))[3]]);

    # Process options
    my $newopt = {}; $newopt = shift if (ref $_[0] eq ref {});
    my @values = split(' ', join(' ', @_));
    my %opt = mergeHash ({
        args => '',
        app => 'rpm',
        pkgs => \@values,
        cmd => 'rpm -q'
    }, $newopt);
    
    # Set cmd and log
    $opt{cmd} .= ' '.(($opt{args}) ? $opt{args}.' ' : '').join(' ', @{$opt{pkgs}});
    $log{mod_dump}->({caller => (caller(0))[3], line => ''}, [\%opt], [qw(opt)]);
    $log{msg}->({level => MOD_CMD, caller => (caller(0))[0], line => (caller(0))[2]}, $opt{cmd});

    my ($stdin, $stdout, $stderr, $pid);

    $stderr = gensym();
    $opt{pid} = open3(\*WRITER, \*READER, \*ERROR, $opt{cmd});

    while( my $output = <READER> ) { 
        chomp $output;
        $log{msg}->({level => MOD_OUT, app => $opt{app}, pid => $opt{pid}}, $output);
    }
    while( my $errout = <ERROR> ) { 
        chomp $errout;
        $log{msg}->({level => ERROR, app => $opt{app}, pid => $opt{pid}}, $errout);
    }

    waitpid( $opt{pid}, 0 );
    my $exit = $?;

    $log{mod_dump}->({caller => (caller(0))[3]}, [$exit], [qw(exit)]);
    return ($exit == 0);
}

sub version {
    shift if $_[0] eq __PACKAGE__;
}

1;