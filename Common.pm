package ASoS::Common;

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
use Exporter;
use Config;
use IPC::Open3;
use Term::ReadKey qw(GetTerminalSize);

use Symbol 'gensym'; 

our @ISA = qw(Exporter);
our @EXPORT = qw();
our @EXPORT_OK = qw(
    %OS %PERL %TERM %BIN %RESULT
    ltrim rtrim trim removeQuotes
    absolutePath formatString
    toHash mergeHash whoami whowasi makeCMD mergeOptions
    DEFAULT BLACK RED GREEN YELLOW BLUE MAGENTA CYAN LIGHTGRAY DARKGRAY LIGHTRED LIGHTGREEN LIGHTYELLOW LIGHTBLUE LIGHTMAGENTA LIGHTCYAN WHITE
);
our %EXPORT_TAGS = (
    ALL => \@EXPORT_OK,
    TRIM => [qw(ltrim rtrim trim removeQuotes)],
    UTILS => [qw(absolutePath formatString)],
    MODULE => [qw(toHash mergeHash whoami whowasi makeCMD mergeOptions)],
    COLORS => [qw(DEFAULT BLACK RED GREEN YELLOW BLUE MAGENTA CYAN LIGHTGRAY DARKGRAY LIGHTRED LIGHTGREEN LIGHTYELLOW LIGHTBLUE LIGHTMAGENTA LIGHTCYAN WHITE)]
);

#! color constants
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

#! key list for OS hash
our @OS_KEYS = (
    'NAME', 'VERSION', 'ID', 'ID_LIKE', 'PRETTY_NAME', 'VERSION_ID', 'HOME_URL', 'BUG_REPORT_URL',
    'ICON_NAME', 'CHASSIS', 'MACHINE_ID', 'BOOT_ID', 'VIRTUALIZATION', 'KERNEL', 'ARCHITECTURE',
    'ARCH_NAME', 'ARCH', 'BY', 'EMAIL', 'TIME', 'TYPE'
);

#! key list for PERL hash
our @PERL_KEYS = (
    'API_REVISION', 'API_SUBVERSION', 'API_VERSION', 'PATCHLEVEL', 'REVISION', 'SUBVERSION', 'VERSION', 
    'PACKAGE', 'PATH_SEP', 'VERSION_STRING', 'ADMIN'
);

#! paths to executables
our %BIN = ();

#! perl information
our %PERL = map { $_ => '' } @PERL_KEYS;

#! os functions
our %OS = (
    HOSTNAME => \&os_hostname,
    DOMAIN => \&os_domain,
    IS_VM => \&os_isVM
); 

#! terminal functions
our %TERM = (
    WIDTH => (GetTerminalSize())[0],
    HEIGHT => (GetTerminalSize())[1],
    POS => &term_pos,
    UP => &term_up,
    DOWN => &term_down,
    RIGHT => &term_right,
    LEFT => &term_left,
    CLEAR => &term_clear,
    ERASE => &term_erase,
    SAVE => &term_save,
    RESTORE => &term_restore,
    HIDE => &term_hide,
    SHOW => &term_show
);

#! result codes
our %RESULT = (
    FATAL => -1,
    ERROR => 0,
    SUCCESS => 1
);

#! list of distros and releases supported
our @RELEASES = (
    centos => [qw(centos6 centos7)],
    ubuntu => [qw(lucid precise trusty xenial bionic)],
    debian => [qw(squeeze wheezy jessie stretch buster bullseye)]
);

#! list of distros that use yum
our @YUM = [qw(centos)];

#! list of distros that use apt
our @APT = [qw(ubuntu debian)];

#! list of options to exclude from options dump
our $OPT_EXCLUDE = [qw(-module -cmd -success -failed -vars -var -names -name)];

################################################################################
#* Terminal subs
################################################################################

#? Position the Cursor:
sub term_pos        { my $row = shift // 0; my $col = shift // 0; return "\e[".$row.';'.$col.'H'; }

#? Move the cursor up N lines:
sub term_up         { my $row = shift // 1; return "\e[".$row.'A'; }

#? Move the cursor down N lines:
sub term_down       { my $row = shift // 1; return "\e[".$row.'B'; }

#? Move the cursor forward N columns:
sub term_right      { my $col = shift // 1; return "\e[".$col.'C'; }

#? Move the cursor backward N columns:
sub term_left       { my $col = shift // 1; return "\e[".$col.'D'; }

#? Clear the screen, move to (0,0):
sub term_clear      { return "\e[2J"; }

#? Erase to end of line:
sub term_erase      { return "\e[K"; }

#? Save cursor position:
sub term_save       { return "\e[s"; }

#? Restore cursor position:
sub term_restore    { return "\e[u"; }

#? Hide cursor
sub term_hide       { return "\e[?25l"; }

#? Show cursor
sub term_show       { return "\e[?25h"; }

################################################################################
#* OS subs
################################################################################

#? return true if is a vm
sub os_isVM { return (lc($OS{'CHASSIS'}) eq "vm") ? 1 : 0; }

#? get/set hostname
sub os_hostname {
    #TODO: add set to function
    #TODO: return only hostname without domain
    #TODO: when setting if string contains domain then also set domain
    my $host = qx(hostname -s); chomp $host; return $host;
}

#? get/set domain name
sub os_domain {
    #TODO: add set to function
    my $domain = qx(hostname -f); chomp $domain; $domain =~ s/^[^\.]*\.//; return $domain;
}

################################################################################
#* Trim subs
################################################################################

#? remove leading whitespace from string
sub ltrim           { my $s = shift; return if not $s; $s =~ s/^\s+//;       return $s };

#? remove trailing whitespace from string
sub rtrim           { my $s = shift; return if not $s; $s =~ s/\s+$//;       return $s };

#? remove leading and trailing whitespace from string
sub  trim           { my $s = shift; return if not $s; $s =~ s/^\s+|\s+$//g; return $s };

#? remove leading and trailing quotes from string
sub removeQuotes    { my $s = shift; return if not $s; $s =~ s/^"(.*)"$/$1/; return $s };

################################################################################
#* Utility subs
################################################################################

#? get absolute path of file or folder
sub absolutePath {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    my $orig = $_[0];
    my $path = dirname($orig);
    my $file = basename($orig);

    if ($path eq '.') { $path = $ENV{'PWD'}; }
    if ($path eq '..') { $path = dirname($ENV{'PWD'}); }
    if ($path eq '/') { $path = ""; }

    return $path.'/'.$file;
}

#? format string from array, using %1,%2,%2...
sub formatString {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    my $string = $_[0];
    my @array = @{$_[1]};
    my $index = 1;

    while (defined(my $arg = shift @array)) {
        my $match = '%'.$index;
        $string =~ s/$match/$arg/g;
        $index++;
    }

    return $string;
}

################################################################################
#* Module subs
################################################################################

#? convert array to hash
sub toHash {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    my %hash = ();
    my @values = ();

    #^ process arguments
    while (defined(my $arg = shift @_)) {
        if ($arg =~ /^-.*/) {
            #. convert argument name to lowercase and assign value
            $hash{lc($arg)} = shift;
        } else {
            #. not an argument
            #. so split the value on newlines and add to values array
            my @list = split("\n", $arg);
            foreach my $item (@list) { push @values, $item;  }
        }
    }

    #. add values array to the hash
    @{$hash{-values}} = @values;

    return %hash;
}

#? merge array into hash
sub mergeHash {
    my $hash1 = shift;
    my %hash2 = @_;
    my %newhash = %$hash1;

    foreach my $key (keys %hash2)
    {
        #. make sure key is lowercase and combine
        $newhash{lc($key)} = $hash2{$key};
    }

    return %newhash;
}

#? reformat package/subroutine name
sub subName {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    my @ret = ();

    #. remove asos:: from subroutine name
    (my $name = lc(shift)) =~ s/^asos:://;

    my $pos = shift // 0;

    #. split name
    my @pkg = split('::', $name);

    #. set first element as package->sub
    push @ret, join('->', @pkg);
    
    #. append rest to return
    push @ret, @pkg;

    return $ret[$pos];
}

#? get subroutine name
sub whoami { 
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    my $pos = (shift // 0) + 1;
    my @caller = caller($pos);

    return '' if not @caller;

    return subName($caller[3]); 
}

#? get subroutine caller stack
sub whowasi {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    my $pos = (shift // 0) + 2;
    my @values = ();
    my @here = caller(0);

    my $level = 0;
    my @last = ();

    #. loop through caller stack
    while (my @caller = caller($level)) {
        #. break out of loop if caller has no line number
        last if ($caller[2] == 0);

        #. only process if it a subroutine
        if ($caller[3] ne '(eval)') {
            #. format subroutine name and push to array
            push @values, $caller[3];
            #. save caller so we can use the last one when loop ends
            @last = @caller;
        }
        $level++;
    }

    #. set return starting with origin
    my $ret = subName($last[0]).'['.$last[2]."]";

    #. add remaining
    my $index = 1;
    for (my $j = @values-1; $j >= $pos; $j--) {
        $ret .= '->'.subName($values[$j]) if ($index == 1);
        $ret .= '->'.subName($values[$j],2) if ($index > 1);
        $index++;
    }

    return $ret;
}

#? create command string from app,args,values
sub makeCMD {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    #TODO: strip path from app/cmd
    my $opt = shift;

    #. if command already exists create app name and return
    if (defined $opt->{-cmd}) {
        ($opt->{-app} = $opt->{-cmd}) =~ s/(\w+).*/$1/ if (not defined $opt->{-app});
        return $RESULT{SUCCESS};
    }

    #. return false if app is not defined
    return 0 if (not defined $opt->{-app});

    #. double check that app name is only a single word
    $opt->{-app} =~ s/(\w+).*/$1/;

    #. create command
    $opt->{-cmd} = $opt->{-app}
        .' '
        .((defined $opt->{-mainargs}) 
            ? $opt->{-mainargs}.' ' 
            : ''
        )
        .((defined $opt->{-args}) 
            ? $opt->{-args}.' ' 
            : ''
        )
        .join(' ', @_);

    return $RESULT{SUCCESS};
}

sub mergeOptions {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    #TODO: rewrite to return a parsed hash instead of logging through here
    my $in = shift;
    my %hash = %$in;
    my %opt = mergeHash(\%hash, @_);

    #^ remove non persistant args
    my $dump = delete $opt{-dump} // 1;


    #IDEA: place blocked args into an array so we can easily add more if needed
    #^ temporarily remove args that we dont want to show
    my $module = delete $opt{-module} // 0;
    my $cmd = delete $opt{-cmd} // undef;
    my $success = delete $opt{-success} // undef;
    my $failed = delete $opt{-failed} // undef;
    my @vars = delete $opt{-vars} // ();
    my @var = delete $opt{-var} // ();
    my @names = delete $opt{-names} // ();
    my @name = delete $opt{-name} // ();

    #^ combine args
    my $mainargs = delete $opt{-mainargs} // '';
    $opt{-args} = ((defined $opt{-args})
        ? (($mainargs) ? $mainargs.' ' : '').$opt{-args}
        : $mainargs
    );

    #TODO: move logging to each sub that needs
    #^ log options if dump is requested
    #-$log{MOD_DEBUG}->(
    #-    -options => [\%opt],
    #-    -indent => 0
    #-) if ($dump == '1');

    #^ restore removed args
    $opt{-module} = $module;
    $opt{-cmd} = $cmd;
    $opt{-success} = $success;
    $opt{-failed} = $failed;
    @{$opt{-vars}} = @vars;
    @{$opt{-var}} = @var;
    @{$opt{-names}} = @names;
    @{$opt{-name}} = @name;

    return %opt;
}

#/ #############################################################################
#/ Private
#/ #############################################################################

sub setupBIN {
    my $ret = 0;

    $ASoS::Common::BIN = ();
    foreach my $path (reverse(split(':', $ENV{PATH}))) { 
        if (opendir(DIR, $path)) {
            while (my $filename = readdir(DIR)) {
                next if ($filename eq '.' || $filename eq '..');
                $BIN{$filename} = $path.'/'.$filename if (-x $path.'/'.$filename);
            }

            $ret = 1;
            closedir(DIR);
        }
    }

    return $ret;
}

sub setupOS {
    $OS{$_} = '' for @OS_KEYS;

    if (open(my $fh, '<:encoding(UTF-8)', '/etc/os-release')) {
        while (my $output = <$fh>) {
            chomp $output;
            if ($output =~ m/=/) {
                my @val = split '=', $output, 2;
                (my $key = uc(trim($val[0]))) =~ s/\s/_/g;
                my $value = removeQuotes(trim($val[1]));
                $OS{$key} = $value if ($key ~~ @OS_KEYS);
            }
        }
        close $fh;
    }

    if (my $pid = open3(\*WRITER, \*READER, \*ERROR, 'hostnamectl')) {
        while( my $output = <READER> ) { 
            chomp $output;
            if ($output =~ m/: /) {
                my @val = split ': ', $output, 2;
                (my $key = uc(trim($val[0]))) =~ s/\s/_/g;
                my $value = removeQuotes(trim($val[1]));
                $OS{$key} = $value if ($key ~~ @OS_KEYS);
            }
        }
        waitpid( $pid, 0 );
    }

    while (my ($key, $value) = each (%Config)) {
        $key = uc($key);

        $OS{'ARCH_NAME'} = $value if ($key eq 'ARCHNAME');
        $OS{'ARCH'} = $value if ($key eq 'MYARCHNAME');
        $OS{'BY'} = $value if ($key eq 'CF_BY');
        $OS{'EMAIL'} = $value if ($key eq 'CF_EMAIL');
        $OS{'TIME'} = $value if ($key eq 'CF_TIME');
        $OS{'TYPE'} = $value if ($key eq 'OSNAME');
    }
}

sub setupPERL {
    while (my ($key, $value) = each (%Config)) {
        $key = uc($key);

        $PERL{$key} = $value if ($key ~~ @PERL_KEYS);
        $PERL{'VERSION_STRING'} = $value if ($key eq 'VERSION_PATCHLEVEL_STRING');
        $PERL{'ADMIN'} = $value if ($key eq 'PERLADMIN');
    }
}

#/ #############################################################################
#/ Init
#/ #############################################################################

setupOS;
setupPERL;
setupBIN;

1;