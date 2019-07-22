package ASoS::Log;

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
use IO::Handle;
use Exporter;
use File::Basename;

use ASoS::Say;
use ASoS::Depend::Dumper qw(Dumper);
use ASoS::Constants qw(:COLORS :LEVELS);
use ASoS::Utils;

our @ISA = qw(Exporter);
our @EXPORT = qw(%log);
our @EXPORT_OK = qw(LOGFILE LOGLEVEL msg fatal error warn info cmd output debug);
our %EXPORT_TAGS = (
    ALL => \@EXPORT_OK,
    LEVELS => [qw(fatal error warn info cmd output debug)],
    INFO => [qw(LOGFILE LOGLEVEL)]
);

our %log = (
    cmd => \&cmd,
    debug => \&debug,
    dump => \&dump,
    error => \&error,
    fatal => \&fatal,
    info => \&info,
    mod_dump => \&mod_dump,
    msg => \&msg,
    output => \&output,
    warn => \&warn,
    LOGFILE => \&LOGFILE,
    LOGLEVEL => \&LOGLEVEL
);

my $LFH;
my $LOGFILE_OPEN = 0;
my $LOGFILE = $ENV{'HOME'} . '/' . basename($0) . '.alog';
my $LOGLEVEL = MOD_DEBUG;

sub LOGFILE { return $LOGFILE; }
sub LOGLEVEL {
    shift if $_[0] eq __PACKAGE__;

    my $level = shift;
    
    if ($level =~ /^\d+$/) { $LOGLEVEL = $level; }

    return $LOGLEVEL;
}

sub msg {
    shift if $_[0] eq __PACKAGE__;
    my %args = (
        caller => (caller(0))[0],
        line => (caller(0))[2],
        app => undef,
        pid => undef,
        level => INFO
    );
    if (ref $_[0] eq ref {}) { mergeHash (\%args, shift); }

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $date = sprintf("%02d/%02d/%04d %02d:%02d:%02d", $mon, $mday, 1900 + $year, $hour, $min, $sec);
    my @values = ();
    my $name = ($args{app}) 
        ? $args{app}.(($args{pid}) ? '['.$args{pid}.']' : '')
        : $args{caller}.(($args{line}) ? '['.$args{line}.']' : '');
    my $level = ($args{level}) ? (LOGLEVELS)[$args{level}] : ' - ';

    foreach my $val (@_) { push @values, split("\n", $val); }

    if ($LOGFILE_OPEN and $args{level} <= $LOGLEVEL) {
        foreach my $val (@values) {
            chomp $val;
            print $LFH sprintf("%s %s %s: %s\n", $date, $level, $name, $val);
        }
        return 1;
    }
    return 0;
}

sub fatal {
    shift if $_[0] eq __PACKAGE__;
    my %args = mergeHash ({
        caller => (caller(0))[0],
        line => (caller(0))[2],
        level => FATAL
    }, (ref $_[0] eq ref {}) ? shift : {});

    return msg (%args, @_);
}

sub error {
    shift if $_[0] eq __PACKAGE__;
    my %args = mergeHash ({
        caller => (caller(0))[0],
        line => (caller(0))[2],
        level => ERROR
    }, (ref $_[0] eq ref {}) ? shift : {});

    return msg (%args, @_);
}

sub warn {
    shift if $_[0] eq __PACKAGE__;
    my %args = mergeHash ({
        caller => (caller(0))[0],
        line => (caller(0))[2],
        level => WARN
    }, (ref $_[0] eq ref {}) ? shift : {});

    return msg (%args, @_);
}

sub info {
    shift if $_[0] eq __PACKAGE__;
    my %args = mergeHash ({
        caller => (caller(0))[0],
        line => (caller(0))[2],
        level => INFO
    }, (ref $_[0] eq ref {}) ? shift : {});

    return msg (%args, @_);
}

sub cmd {
    shift if $_[0] eq __PACKAGE__;
    my %args = mergeHash ({
        caller => (caller(0))[0],
        line => (caller(0))[2],
        level => CMD
    }, (ref $_[0] eq ref {}) ? shift : {});

    return msg (%args, @_);
}

sub output {
    shift if $_[0] eq __PACKAGE__;
    my %args = mergeHash ({
        caller => (caller(0))[0],
        line => (caller(0))[2],
        level => OUT
    }, (ref $_[0] eq ref {}) ? shift : {});

    return msg (%args, @_);
}

sub debug {
    shift if $_[0] eq __PACKAGE__;
    my %args = mergeHash ({
        caller => (caller(0))[0],
        line => (caller(0))[2],
        level => DEBUG
    }, (ref $_[0] eq ref {}) ? shift : {});

    return msg (%args, @_);
}

sub dump {
    shift if $_[0] eq __PACKAGE__;
    my %args = mergeHash ({
        caller => (caller(0))[0],
        line => (caller(0))[2],
        level => DEBUG
    }, (ref $_[0] eq ref {}) ? shift : {});

    $ASoS::Depend::Dumper::Purity = 1;
    return msg (\%args, ASoS::Depend::Dumper->Dump($_[0], $_[1]));
}

sub mod_dump {
    shift if $_[0] eq __PACKAGE__;
    my %args = mergeHash ({
        caller => (caller(0))[0],
        line => '',
        level => MOD_DEBUG
    }, (ref $_[0] eq ref {}) ? shift : {});

    $ASoS::Depend::Dumper::Purity = 1;
    return msg (\%args, ASoS::Depend::Dumper->Dump($_[0], $_[1]));
}

sub DESTROY {
    close($LFH) if $LOGFILE_OPEN;
}

if (open($LFH, '>>', $LOGFILE)) { 
    $LOGFILE_OPEN = 1; 
    $say{info}->(DEFAULT."Using log file '".WHITE.$LOGFILE.DEFAULT."'");
}

1;