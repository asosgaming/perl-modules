package ASoS::Log;

################################################################################
#* Copyright Ⓒ 2019 ASoS Gaming
################################################################################
#* Permission is hereby granted, free of charge, to any person obtaining a copy
#* of this software and associated documentation files (the "Software"), to deal
#* in the Software without restriction, including without limitation the rights
#* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#* copies of the Software, and to permit persons to whom the Software is
#* furnished to do so, subject to the following conditions:
#*
#* The above copyright notice and this permission notice shall be included in all
#* copies or substantial portions of the Software.
#*
#* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#* SOFTWARE.
################################################################################

use v5.10;
use strict;
use warnings;
use IO::Handle;
use Exporter;
use File::Basename;

use ASoS::Say;
use ASoS::Depend::Dumper qw(Dumper);
use ASoS::Common qw(%RESULT @OPT_EXCLUDE :COLORS :MODULE);

our @ISA = qw(Exporter);
our @EXPORT = qw(%log OFF FATAL ERROR WARN INFO CMD OUT DEBUG MOD_CMD MOD_OUT MOD_DEBUG LOGFILE LOGLEVEL);

#! log levels
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
    MOD_DEBUG => 10
};

#! level names for output
use constant LOGLEVELS => qw(OFF FATAL ERROR WARN INFO CMD OUTPUT DEBUG MODCMD MODOUT MODDBG);

#! log functions
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
    MOD_DEBUG => \&mod_debug,
    OPTIONS => \&mod_options
);

my $LFH;
my $LOGFILE_OPEN = 0;
my $LOGFILE = $ENV{'HOME'} . '/' . basename($0) . '.alog';
my $LOGLEVEL = MOD_DEBUG;

sub LOGFILE { return $LOGFILE; }

sub LOGLEVEL {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    my $level = shift;

    #^ set log level if level was passed to sub and is number
    if (defined $level && $level =~ /^\d+$/) { 
        $LOGLEVEL = $level; 

        $say{INFO}->(DEFAULT."Log level set to '".WHITE.(LOGLEVELS)[$LOGLEVEL].DEFAULT."'");
    }

    return $LOGLEVEL;
}

#? main log routine
sub msg {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    #^ process options
    my %opt = mergeHash ({
        -from => whowasi,
        -app => undef,
        -pid => undef,
        -level => INFO,
        -wrap => 1
    }, toHash(@_));

    #^ assign current date and time
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $date = sprintf("%02d/%02d/%04d %02d:%02d:%02d", $mon, $mday, 1900 + $year, $hour, $min, $sec);

    #^ set name
    my $name = 
        #. add caller stack
        (($opt{-from}) 
            ? $opt{-from} 
            : ''
        #. add app and pid if set
        ).(($opt{-app}) 
            ? '->'.$opt{-app}.
                ((defined $opt{-pid}) 
                    ? '['.$opt{-pid}.']' 
                    : ''
                )
            : ''
        #. add extra to name if set
        ).((defined $opt{-extra}) 
            ? '->'.$opt{-extra}.':' 
            : ':'
        );

    #^ set shortened log level
    my $level = (defined $opt{-level}) ? (LOGLEVELS)[$opt{-level}] : ' - ';

    #^ log data if logfile is open and level is less than loglevel
    if ($LOGFILE_OPEN and $opt{-level} <= $LOGLEVEL) {
        #. init output to empty string
        my $output = '';

        #. loop through values
        foreach my $val (@{$opt{-values}}) {
            chomp $val;

            #. if wrap is set print each on new line
            if ($opt{-wrap} eq 1) {
                print $LFH sprintf("%s %-6s %s %s\n", $date, $level, $name, $val);
            }

            #. otherwise add to output string
            else { $output .= $val.' '; }
        }

        #. print output string if wrap was not set
        print $LFH sprintf("%s %-4s %s %s\n", $date, $level, $name, $output) if ($output);

        return $RESULT{SUCCESS};
    }

    return $RESULT{ERROR};
}

#? log fatal messages
sub fatal {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    #^ process options
    my %opt = mergeHash ({
        -from => whowasi,
        -level => FATAL
    }, toHash(@_));

    #^ log data
    return msg (%opt, @{$opt{-values}});
}

#? log errors
sub error {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    #^ process options
    my %opt = mergeHash ({
        -from => whowasi,
        -level => ERROR
    }, toHash(@_));

    #^ log data
    return msg (%opt, @{$opt{-values}});
}

#? log warnings
sub warn {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    #^ process options
    my %opt = mergeHash ({
        -from => whowasi,
        -level => WARN
    }, toHash(@_));

    #^ log data
    return msg (%opt, @{$opt{-values}});
}

#? log information
sub info {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    #^ process options
    my %opt = mergeHash ({
        -from => whowasi,
        -level => INFO
    }, toHash(@_));

    #^ log data
    return msg (%opt, @{$opt{-values}});
}

#? log commands
sub cmd {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    #^ process options
    my %opt = mergeHash ({
        -from => whowasi,
        -level => CMD
    }, toHash(@_));

    #^ log data
    return msg (%opt, @{$opt{-values}});
}

#? log command output
sub output {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    #^ process options
    my %opt = mergeHash ({
        -from => whowasi,
        -level => OUT
    }, toHash(@_));

    #^ log data
    return msg (%opt, @{$opt{-values}});
}

#? log debug message or dump variables
sub debug {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    #^ process options
    my %opt = mergeHash ({
        -from => whowasi,
        -level => DEBUG,
        -purity => 0,
        -sort => 1,
        -indent => 2,
        -deparse => 0
    }, toHash(@_));

    #^ set dumper options
    $ASoS::Depend::Dumper::Purity = $opt{-purity};
    $ASoS::Depend::Dumper::Sortkeys = $opt{-sort};
    $ASoS::Depend::Dumper::Indent = $opt{-indent};
    $ASoS::Depend::Dumper::Deparse = $opt{-deparse};

    #^ dump variable and name if set
    if (defined $opt{-var} && defined $opt{-name}) 
    { return msg (%opt, ASoS::Depend::Dumper->Dump([$opt{-var}], [$opt{-name}])); }

    #^ or dump variables and names if set
    elsif (defined $opt{-vars} && defined $opt{-names}) 
    { return msg (%opt, ASoS::Depend::Dumper->Dump(\@{$opt{-vars}}, \@{$opt{-names}})); }

    #^ or dump variable using name VAR1 if set
    elsif (defined $opt{-var}) 
    { return msg (%opt, ASoS::Depend::Dumper->Dump([$opt{-var}])); }

    #^ or dump variables using names of VAR{1,2,3...} if set
    elsif (defined $opt{-vars}) 
    { return msg (%opt, ASoS::Depend::Dumper->Dump(\@{$opt{-vars}})); }

    #^ else just log a debug message
    else { return msg (%opt, @{$opt{-values}}); }
}

#? module commands
sub mod_cmd {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    #^ process options
    my %opt = mergeHash ({
        -from => whowasi,
        -level => MOD_CMD
    }, toHash(@_));

    #^ log data
    return msg (%opt, @{$opt{-values}});
}

#? module output
sub mod_output {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    #^ process options
    my %opt = mergeHash ({
        -from => whowasi,
        -level => MOD_OUT
    }, toHash(@_));

    #^ log data
    return msg (%opt, @{$opt{-values}});
}

#? module debuging
sub mod_debug {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    #^ process options
    my %opt = mergeHash ({
        -from => whowasi,
        -level => MOD_DEBUG,
        -purity => 0,
        -sort => 1,
        -indent => 2,
        -deparse => 0
    }, toHash(@_));

    #^ set dumper options
    $ASoS::Depend::Dumper::Purity = $opt{-purity};
    $ASoS::Depend::Dumper::Sortkeys = $opt{-sort};
    $ASoS::Depend::Dumper::Indent = $opt{-indent};
    $ASoS::Depend::Dumper::Deparse = $opt{-deparse};

    #^ dump variable and name if set
    if (defined $opt{-var} && defined $opt{-name}) 
    { return msg (%opt, ASoS::Depend::Dumper->Dump([$opt{-var}], [$opt{-name}])); }

    #^ or dump variables and names if set
    elsif (defined $opt{-vars} && defined $opt{-names}) 
    { return msg (%opt, ASoS::Depend::Dumper->Dump(\@{$opt{-vars}}, \@{$opt{-names}})); }

    #^ or dump variable using name VAR1 if set
    elsif (defined $opt{-var}) 
    { return msg (%opt, ASoS::Depend::Dumper->Dump([$opt{-var}])); }

    #^ or dump variables using names of VAR{1,2,3...} if set
    elsif (defined $opt{-vars}) 
    { return msg (%opt, ASoS::Depend::Dumper->Dump(\@{$opt{-vars}})); }

    #^ else just log a debug message
    else { return msg (%opt, @{$opt{-values}}); }
}

#? module options dump
sub mod_options {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    #^ grab options
    my $options = $_[0];
    #^ set dump option
    my $do_dump = delete $options->{-dump} // 0;
    #^ create new hash from options
    my %opt = %$options;

    #^ remove keys that we do not want to show in dump
    delete $opt{$_} for @OPT_EXCLUDE;

    #^ set dumper options
    $ASoS::Depend::Dumper::Purity = 0;
    $ASoS::Depend::Dumper::Sortkeys = 1;
    $ASoS::Depend::Dumper::Indent = 0;
    $ASoS::Depend::Dumper::Deparse = 0;

    # #^ dump subroutine options if options set
    if ($do_dump) 
    {
        #. split dump into an array
        my @dump = split ("\n", ASoS::Depend::Dumper->Dump([\%opt]));
        #. remove $VAR1= and closing bracket if is multiline
        if (@dump > 2) { shift @dump && pop @dump; }

        #. loop through all the lines and clean up the optput
        foreach my $line (@dump) {
            #. remove var from beginning
            $line =~ s/^\$VAR1 = {/ /;
            #. replace closing bracket with double quote
            $line =~ s/};$/\"/;
            #. remove second quote from key names
            $line =~ s/\' => / => /g;
            #. remove first quote from key names
            $line =~ s/,\'\-/, -/g;
            #. add double quote to beginning of line or log sub will process as options
            $line =~ s/^\s\'/\"/;

            return msg (
                -level => MOD_DEBUG, 
                -extra => 'options',
                -app => undef,
                -from => whowasi(),
                $line
            );
        }
    }
}

sub DESTROY {
    close($LFH) if $LOGFILE_OPEN;
}

#* open log file
if (open($LFH, '>>', $LOGFILE)) { 
    $LOGFILE_OPEN = 1; 
    $say{INFO}->(DEFAULT."Using log file '".WHITE.$LOGFILE.DEFAULT."'");
}

1;