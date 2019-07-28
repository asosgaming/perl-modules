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
use ASoS::Common qw(:COLORS :SUB);

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

use constant LOGLEVELS => qw(OFF FTL ERR WRN INF CMD OUT DBG CMD_ OUT_ DBG_);

our @ISA = qw(Exporter);
our @EXPORT = qw(%log OFF FATAL ERROR WARN INFO CMD OUT DEBUG MOD_CMD MOD_OUT MOD_DEBUG);
our @EXPORT_OK = qw();
our %EXPORT_TAGS = (
    ALL => \@EXPORT_OK
);

our %log = (
    LOGFILE => \&LOGFILE,
    LOGLEVEL => \&LOGLEVEL,
    msg => \&msg,
    FATAL => \&fatal,
    ERROR => \&error,
    WARN => \&warn,
    INFO => \&info,
    CMD => \&cmd,
    OUT => \&output,
    DEBUG => \&debug,
    MOD_CMD => \&mod_cmd,
    MOD_OUT => \&mod_output,
    MOD_DEBUG => \&mod_debug
);

my $LFH;
my $LOGFILE_OPEN = 0;
my $LOGFILE = $ENV{'HOME'} . '/' . basename($0) . '.alog';
my $LOGLEVEL = MOD_DEBUG;

sub LOGFILE { return $LOGFILE; }

sub LOGLEVEL {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    my $level = shift;
    
    if ($level =~ /^\d+$/) { $LOGLEVEL = $level; }

    return $LOGLEVEL;
}

sub msg {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    my %opt = mergeHash ({
        -from => '',
        -caller => whoami,
        -app => undef,
        -pid => undef,
        -level => INFO,
        -wrap => 1
    }, toHash(@_));

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $date = sprintf("%02d/%02d/%04d %02d:%02d:%02d", $mon, $mday, 1900 + $year, $hour, $min, $sec);
    my $name = 
        (($opt{-from}) 
            ? $opt{-from} 
            : ''
        ).(($opt{-app}) 
            ? '->'.$opt{-app}.
                ((defined $opt{-pid}) 
                    ? '['.$opt{-pid}.']' 
                    : ''
                )
            : ''
        ).((defined $opt{-extra}) 
            ? '->'.$opt{-extra}.':' 
            : ':'
        );
    my $level = (defined $opt{-level}) ? (LOGLEVELS)[$opt{-level}] : ' - ';

    if ($LOGFILE_OPEN and $opt{-level} <= $LOGLEVEL) {
        my $output = '';
        foreach my $val (@{$opt{-values}}) {
            chomp $val;
            if ($opt{-wrap} eq 1) {
                print $LFH sprintf("%s %-4s %s %s\n", $date, $level, $name, $val);
            } else { $output .= $val.' '; }
        }

        print $LFH sprintf("%s %-4s %s %s\n", $date, $level, $name, $output) if ($output);
        return 1;
    }
    return 0;
}

sub fatal {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    my %opt = mergeHash ({
        -caller => (((caller(1))[3]) ? (caller(1))[3] : (caller(0))[0]),
        -line => (caller(0))[2],
        -level => FATAL
    }, toHash(@_));

    return msg (%opt, @{$opt{-values}});
}

sub error {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    my %opt = mergeHash ({
        -caller => (((caller(1))[3]) ? (caller(1))[3] : (caller(0))[0]),
        -line => (caller(0))[2],
        -level => ERROR
    }, toHash(@_));

    return msg (%opt, @{$opt{-values}});
}

sub warn {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    my %opt = mergeHash ({
        -caller => (((caller(1))[3]) ? (caller(1))[3] : (caller(0))[0]),
        -line => (caller(0))[2],
        -level => WARN
    }, toHash(@_));

    return msg (%opt, @{$opt{-values}});
}

sub info {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    my %opt = mergeHash ({
        -caller => (((caller(1))[3]) ? (caller(1))[3] : (caller(0))[0]),
        -line => (caller(0))[2],
        -level => INFO
    }, toHash(@_));

    return msg (%opt, @{$opt{-values}});
}

sub cmd {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    my %opt = mergeHash ({
        -caller => (((caller(1))[3]) ? (caller(1))[3] : (caller(0))[0]),
        -line => (caller(0))[2],
        -level => CMD
    }, toHash(@_));

    return msg (%opt, @{$opt{-values}});
}

sub output {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    my %opt = mergeHash ({
        -caller => (((caller(1))[3]) ? (caller(1))[3] : (caller(0))[0]),
        -line => undef,
        -level => OUT
    }, toHash(@_));

    return msg (%opt, @{$opt{-values}});
}

sub debug {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    my %opt = mergeHash ({
        -caller => (((caller(1))[3]) ? (caller(1))[3] : (caller(0))[0]),
        -line => (caller(0))[2],
        -level => DEBUG,
        -purity => 1,
        -sort => 1
    }, toHash(@_));

    $ASoS::Depend::Dumper::Purity = $opt{-purity};
    $ASoS::Depend::Dumper::Sortkeys = $opt{-sort};

    if (defined $opt{-vars}) {
        return msg (%opt, ASoS::Depend::Dumper->Dump(\@{$opt{-vars}}, \@{$opt{-names}})) if defined $opt{-names};
    } else { return msg (%opt, @{$opt{-values}}); }
}

sub mod_cmd {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    my %opt = mergeHash ({
        -caller => (((caller(1))[3]) ? (caller(1))[3] : (caller(0))[0]),
        -line => (caller(0))[2],
        -level => MOD_CMD
    }, toHash(@_));

    return msg (%opt, @{$opt{-values}});
}

sub mod_output {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    my %opt = mergeHash ({
        -caller => (((caller(1))[3]) ? (caller(1))[3] : (caller(0))[0]),
        -line => undef,
        -level => MOD_OUT
    }, toHash(@_));

    return msg (%opt, @{$opt{-values}});
}

sub mod_debug {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    my %opt = mergeHash ({
        -caller => undef,
        -from => whowasi,
        -level => MOD_DEBUG,
        -purity => 1,
        -sort => 1,
        -indent => 2
    }, toHash(@_));

    $ASoS::Depend::Dumper::Purity = $opt{-purity};
    $ASoS::Depend::Dumper::Sortkeys = $opt{-sort};
    $ASoS::Depend::Dumper::Indent = $opt{-indent};

    if (defined $opt{-vars} && defined $opt{-names}) {
        return msg (%opt, ASoS::Depend::Dumper->Dump(\@{$opt{-vars}}, \@{$opt{-names}}));
    } elsif (defined $opt{-options}) {
        my $from = $opt{-options}[0]{-from} && delete $opt{-options}[0]{-from};
        my $caller = $opt{-options}[0]{-caller} && delete $opt{-options}[0]{-caller};

        my @dump = split ("\n", ASoS::Depend::Dumper->Dump(\@{$opt{-options}}));
        if (@dump > 2) { shift @dump && pop @dump; }

        foreach my $line (@dump) {
#            $line =~ s/^\s{9}/ /;
#            $line =~ s/\s{2}\'\-/    -/;
#            $line =~ s/\' =\>/ =>/g;
#            $line =~ s/^\s{4}/ /;

            $line =~ s/^\$VAR1 = {/ /;
            $line =~ s/};$/\"/;
            $line =~ s/\' => / => /g;
            $line =~ s/,\'\-/, -/g;
            $line =~ s/^\s\'/\"/;
        }

        return msg (%opt, 
            #-caller => whoami(2),
            -extra => 'options',
            -from => whowasi(1),
            @dump
        );
    } else { return msg (%opt, @{$opt{-values}}); }
}

sub DESTROY {
    close($LFH) if $LOGFILE_OPEN;
}

if (open($LFH, '>>', $LOGFILE)) { 
    $LOGFILE_OPEN = 1; 
    $say{INFO}->(DEFAULT."Using log file '".WHITE.$LOGFILE.DEFAULT."'");
}

1;