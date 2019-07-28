package ASoS::File;

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
use ASoS::Common qw(:COLORS :SUB :UTILS);
use ASoS::Subs;

use Symbol 'gensym';

our @ISA = qw(Exporter);
our @EXPORT = qw(%file);
our @EXPORT_OK = qw();
our %EXPORT_TAGS = (
    ALL => \@EXPORT_OK,
    CMD => [qw(run mkDir rmDir copy move del touch backup create exists append)],
    IS => [qw(isReadable isWriteable isExecutable isEmpty isFile isDir isLink)]
);

our %file = (
    run => \&run,
    mkdir => \&mkDir,
    rmdir => \&rmDir,
    copy => \&copy,
    move => \&move,
    del => \&del,
    touch => \&touch,
    backup => \&backup,
    create => \&create,
    exists => \&exists,
    append => \&append,
    Readable => \&isReadable,
    Writeable => \&isWriteable,
    Executable => \&isExecutable,
    Empty => \&isEmpty,
    File => \&isFile,
    Dir => \&isDir,
    Folder => \&isDir,
    Link => \&isLink
);

sub prep {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    my $orig = $_[0];
    my $path = dirname($orig);
    my $file = basename($orig);

    if ($path eq '.') { $path = $ENV{'PWD'}; }
    if ($path eq '/') { $path = ""; }

    $log{mod_dump}->({caller => (caller(0))[3]}, [$orig, $path, $file], [qw(orig path file)]);
    return ($path, $file);
}

#FIXME: remove after restructure (use absolutePath sub)
sub prepFile {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    my $orig = $_[0];
    my $path = dirname($orig);
    my $file = basename($orig);

    if ($path eq '.') { $path = $ENV{'PWD'}; }
    if ($path eq '/') { $path = ""; }

    $log{mod_dump}->({caller => (caller(0))[3]}, [$orig, $path, $file], [qw(orig path file)]);
    return $path.'/'.$file;
}

sub run {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    # Process options
    my %opt = mergeOptions ({
        -args => undef,
        -app => undef,
        -module => 0,
        -output => 1
    }, toHash(@_), -dump => 1);

    my %ret = (stdout => [], stderr => [], exit => -1, pid => -1);
    my $dbg = ($opt{-module} eq 1) ? 'MOD_DEBUG' : 'DEBUG';
    my $cmd = ($opt{-module} eq 1) ? 'MOD_CMD' : 'CMD';
    my $out = ($opt{-module} eq 1) ? 'MOD_OUT' : 'OUT';

    # create command
    makeCMD(\%opt, @{$opt{-values}}) or return 0;

    # Log command
    $log{$cmd}->(-from => whowasi(-1), -extra => 'command', $opt{-cmd});

    # Run command
    $ret{pid} = open3(\*WRITER, \*READER, \*ERROR, $opt{-cmd});

    # Log pid
    $log{$dbg}->(
        -from => whowasi(-1),
        -app => $opt{-app},
        -extra => 'pid',
        $ret{pid}
    );

    while( my $stdout = <READER> ) { 
        chomp $stdout;
        push @{$ret{stdout}}, $stdout;

        # Log stdout
        $log{$out}->(
            -from => whowasi(-1),
            -app => $opt{-app},
            $stdout
        );

        $say{MSG}->($stdout) if ($opt{-output} eq 1); 
    }

    while( my $stderr = <ERROR> ) { 
        chomp $stderr;
        push @{$ret{stderr}}, $stderr;

        # Log stderr
        $log{ERROR}->(
            -from => whowasi(-1),
            -app => $opt{-app},
            $stderr
        );

        $say{MSG}->(RED.$stderr.DEFAULT) if ($opt{-output} eq 1); 
    }

    waitpid( $ret{pid}, 0 );
    $ret{exit} = $?;

    # Log exit code
    $log{$dbg}->(
        -from => whowasi(-1),
        -app => $opt{-app},
        -extra => 'exit',
        $ret{exit}
    );

    if ($opt{-output} eq 1) {
        if ($ret{exit} == 0) { 
            if (defined $opt{-success}) { 
                #TODO: check if -vars defined
                $say{OK}->(formatString($opt{-success}, @{$opt{-vars}})); 
            } else { 
                $say{OK}->($opt{-cmd}); 
            }
        } else { 
            if (defined $opt{-failed}) { 
                #TODO: check if -vars defined
                $say{FAILED}->(formatString($opt{-failed}, @{$opt{-vars}})); 
            } else { 
                $say{FAILED}->($opt{-cmd}); 
            }
        }
    }

    return %ret;
}

sub mkDir {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;
    $log{mod_dump}->({caller => (caller(0))[0], line => (caller(0))[2]}, [\@_], [(caller(0))[3]]);

    # Process options
    my $newopt = {}; $newopt = shift if (ref $_[0] eq ref {});
    my @values = split(' ', join(' ', @_));
    my %opt = mergeHash ({
        args => ''
    }, $newopt);

    $opt{files} = [];
    foreach my $folder (@values) { push @{ $opt{files} }, prepFile($folder); }

    return run ({
        args => $opt{args},
        app => 'mkdir',
        cmd => 'mkdir -v',
        success => {
            string => DEFAULT."Created dir%s '%s'",
            var1 => ((@{$opt{files}} > 1) ? 's' : ''),
            var2 => WHITE.join(DEFAULT."', '".WHITE, @{$opt{files}}).DEFAULT,
            var3 => ''
        },
        failed => {
            string => LIGHTRED."Could not create dir%s '%s'",
            var1 => ((@{$opt{files}} > 1) ? 's' : ''),
            var2 => WHITE.join(LIGHTRED."', '".WHITE, @{$opt{files}}).LIGHTRED,
            var3 => ''
        },
    }, join(' ', @{$opt{files}}));
}

sub rmDir {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;
    $log{mod_dump}->({caller => (caller(0))[0], line => (caller(0))[2]}, [\@_], [(caller(0))[3]]);

    # Process options
    my $newopt = {}; $newopt = shift if (ref $_[0] eq ref {});
    my @values = split(' ', join(' ', @_));
    my %opt = mergeHash ({
        args => ''
    }, $newopt);

    $opt{files} = [];
    foreach my $folder (@values) { push @{ $opt{files} }, prepFile($folder); }

    return run ({
        args => $opt{args},
        app => 'rmdir',
        cmd => 'rmdir -v',
        success => {
            string => DEFAULT."Removed dir%s '%s'",
            var1 => ((@{$opt{files}} > 1) ? 's' : ''),
            var2 => WHITE.join(DEFAULT."', '".WHITE, @{$opt{files}}).DEFAULT,
            var3 => ''
        },
        failed => {
            string => LIGHTRED."Could not remove dir%s '%s'",
            var1 => ((@{$opt{files}} > 1) ? 's' : ''),
            var2 => WHITE.join(LIGHTRED."', '".WHITE, @{$opt{files}}).LIGHTRED,
            var3 => ''
        },
    }, join(' ', @{$opt{files}}));
}

sub copy {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;
    $log{mod_dump}->({caller => (caller(0))[0], line => (caller(0))[2]}, [\@_], [(caller(0))[3]]);

    # Process options
    my $newopt = {}; $newopt = shift if (ref $_[0] eq ref {});
    my @values = split(' ', join(' ', @_));
    my %opt = mergeHash ({
        args => ''
    }, $newopt);

    $opt{files} = [];
    foreach my $folder (@values) { push @{ $opt{files} }, prepFile($folder); }
    my $target = pop @{ $opt{files} };

    return run ({
        args => $opt{args},
        app => 'cp',
        cmd => 'cp -v',
        success => {
            string => DEFAULT."Copied '%s' to '%s'",
            var1 => WHITE.join(DEFAULT."', '".WHITE, @{$opt{files}}).DEFAULT,
            var2 => WHITE.$target.DEFAULT,
            var3 => ''
        },
        failed => {
            string => LIGHTRED."Could not copy '%s' to '%s'",
            var1 => WHITE.join(LIGHTRED."', '".WHITE, @{$opt{files}}).LIGHTRED,
            var2 => WHITE.$target.LIGHTRED,
            var3 => ''
        },
    }, join(' ', @{$opt{files}}), $target);
}

sub move {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;
    $log{mod_dump}->({caller => (caller(0))[0], line => (caller(0))[2]}, [\@_], [(caller(0))[3]]);

    # Process options
    my $newopt = {}; $newopt = shift if (ref $_[0] eq ref {});
    my @values = split(' ', join(' ', @_));
    my %opt = mergeHash ({
        args => ''
    }, $newopt);

    $opt{files} = [];
    foreach my $folder (@values) { push @{ $opt{files} }, prepFile($folder); }
    my $target = pop @{ $opt{files} };

    return run ({
        args => $opt{args},
        app => 'mv',
        cmd => 'mv -v',
        success => {
            string => DEFAULT."Moved '%s' to '%s'",
            var1 => WHITE.join(DEFAULT."', '".WHITE, @{$opt{files}}).DEFAULT,
            var2 => WHITE.$target.DEFAULT,
            var3 => ''
        },
        failed => {
            string => LIGHTRED."Could not move '%s' to '%s'",
            var1 => WHITE.join(LIGHTRED."', '".WHITE, @{$opt{files}}).LIGHTRED,
            var2 => WHITE.$target.LIGHTRED,
            var3 => ''
        },
    }, join(' ', @{$opt{files}}), $target);
}

sub del {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;
    $log{mod_dump}->({caller => (caller(0))[0], line => (caller(0))[2]}, [\@_], [(caller(0))[3]]);

    # Process options
    my $newopt = {}; $newopt = shift if (ref $_[0] eq ref {});
    my @values = split(' ', join(' ', @_));
    my %opt = mergeHash ({
        args => ''
    }, $newopt);

    $opt{files} = [];
    foreach my $folder (@values) { push @{ $opt{files} }, prepFile($folder); }

    return run ({
        args => $opt{args},
        app => 'rm',
        cmd => 'rm -v -f',
        success => {
            string => DEFAULT."Deleted '%s'",
            var1 => WHITE.join(DEFAULT."', '".WHITE, @{$opt{files}}).DEFAULT,
            var2 => '',
            var3 => ''
        },
        failed => {
            string => LIGHTRED."Could not delete '%s'",
            var1 => WHITE.join(LIGHTRED."', '".WHITE, @{$opt{files}}).LIGHTRED,
            var2 => '',
            var3 => ''
        },
    }, join(' ', @{$opt{files}}));
}

sub touch {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;
    $log{mod_dump}->({caller => (caller(0))[0], line => (caller(0))[2]}, [\@_], [(caller(0))[3]]);

    # Process options
    my $newopt = {}; $newopt = shift if (ref $_[0] eq ref {});
    my @values = split(' ', join(' ', @_));
    my %opt = mergeHash ({
        args => ''
    }, $newopt);

    $opt{files} = [];
    foreach my $folder (@values) { push @{ $opt{files} }, prepFile($folder); }

    return run ({
        args => $opt{args},
        app => 'touch',
        cmd => 'touch',
        success => {
            string => DEFAULT."Modified '%s'",
            var1 => WHITE.join(DEFAULT."', '".WHITE, @{$opt{files}}).DEFAULT,
            var2 => '',
            var3 => ''
        },
        failed => {
            string => LIGHTRED."Could not modify '%s'",
            var1 => WHITE.join(LIGHTRED."', '".WHITE, @{$opt{files}}).LIGHTRED,
            var2 => '',
            var3 => ''
        },
    }, join(' ', @{$opt{files}}));
}

sub backup {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

#     $log{mod_dump}->([$_], [qw(*backup)]);

#     my $ret = -1;
#     foreach my $val (@_) {
#         my ($dir, $file) = &prep($val);

#         if (-e "$dir/$file") {
#             for (my $i=0; $i <= 9; $i++) {
#                 my $newfile = "$dir/$file.original$i";
#                 if (! -e $newfile) {
#                     if (run("mv -v $dir/$file $newfile")) {
#                         $say{OK}->(DEFAULT."Backed up '".WHITE.$dir.'/'.$file.DEFAULT."' to '".WHITE.$newfile.DEFAULT."'"); 
#                         $ret = 1 if $ret == -1;
#                     } else { 
#                         $say->(LIGHTRED."Could not backup '".WHITE.$dir.'/'.$file.LIGHTRED."' to '".WHITE.$newfile.LIGHTRED."'");
#                         $ret = 0;
#                     }
#                     last;
#                 }
#             }
#         }
#     }
#     if ($ret == -1) { 
#         $say->("Backup unsuccessfull"); 
#         $log{msg}->(ERROR, "Backup unsuccessfull");
#     }
#     return $ret;
}

sub create {
    # shift if defined $_[0] && $_[0] eq __PACKAGE__;

    # $log{mod_dump}->([$_], [qw(*create)]);

    # my $ret = -1;
    # foreach my $val (@_) {
    #     my ($dir, $file) = &prep($val);

    #     if (-e "$dir/$file") { backup("$dir/$file"); }
    #     if (run("touch $dir/$file")) {
    #         $say{OK}->(DEFAULT."Created '".WHITE.$dir.'/'.$file.DEFAULT."'"); 
    #         $ret = 1 if $ret == -1;
    #     } else { 
    #         $say->(LIGHTRED."Could not create '".WHITE.$dir.'/'.$file.LIGHTRED."'");
    #         $ret = 0;
    #     }
    # }
    # if ($ret == -1) { 
    #     $say->("Create unsuccessfull"); 
    #     $log{msg}->(ERROR, "Create unsuccessfull");
    # }
    # return $ret;
}

sub exists {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;
    $log{mod_dump}->({caller => (caller(0))[0], line => (caller(0))[2]}, [\@_], [(caller(0))[3]]);

    my $file = prepFile(shift);

    if (-e $file) { 
        $log{msg}->({
            level => DEBUG, 
            caller => (caller(0))[0], 
            line => (caller(0))[2]
        }, "$file exists");
        return 1; 
    } else { 
        $log{msg}->({
            level => DEBUG, 
            caller => (caller(0))[0], 
            line => (caller(0))[2]
        }, "$file does not exist");
        return 0; 
    }
}

sub isReadable {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;
    $log{mod_dump}->({caller => (caller(0))[0], line => (caller(0))[2]}, [\@_], [(caller(0))[3]]);

    my $file = prepFile(shift);

    if (-r $file) { 
        $log{msg}->({
            level => DEBUG, 
            caller => (caller(0))[0], 
            line => (caller(0))[2]
        }, "$file is readable");
        return 1; 
    } else { 
        $log{msg}->({
            level => DEBUG, 
            caller => (caller(0))[0], 
            line => (caller(0))[2]
        }, "$file is not readable");
        return 0; 
    }
}

sub isWriteable {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;
    $log{mod_dump}->({caller => (caller(0))[0], line => (caller(0))[2]}, [\@_], [(caller(0))[3]]);

    my $file = prepFile(shift);

    if (-w $file) { 
        $log{msg}->({
            level => DEBUG, 
            caller => (caller(0))[0], 
            line => (caller(0))[2]
        }, "$file is writeable");
        return 1; 
    } else { 
        $log{msg}->({
            level => DEBUG, 
            caller => (caller(0))[0], 
            line => (caller(0))[2]
        }, "$file is not writeable");
        return 0; 
    }
}

sub isExecutable {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;
    $log{mod_dump}->({caller => (caller(0))[0], line => (caller(0))[2]}, [\@_], [(caller(0))[3]]);

    my $file = prepFile(shift);

    if (-x $file) { 
        $log{msg}->({
            level => DEBUG, 
            caller => (caller(0))[0], 
            line => (caller(0))[2]
        }, "$file is executable");
        return 1; 
    } else { 
        $log{msg}->({
            level => DEBUG, 
            caller => (caller(0))[0], 
            line => (caller(0))[2]
        }, "$file is not executable");
        return 0; 
    }
}

sub isEmpty {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;
    $log{mod_dump}->({caller => (caller(0))[0], line => (caller(0))[2]}, [\@_], [(caller(0))[3]]);

    my $file = prepFile(shift);

    if (-z $file) { 
        $log{msg}->({
            level => DEBUG, 
            caller => (caller(0))[0], 
            line => (caller(0))[2]
        }, "$file is empty");
        return 1; 
    } else { 
        $log{msg}->({
            level => DEBUG, 
            caller => (caller(0))[0], 
            line => (caller(0))[2]
        }, "$file is not empty");
        return 0; 
    }
}

sub isFile {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;
    $log{mod_dump}->({caller => (caller(0))[0], line => (caller(0))[2]}, [\@_], [(caller(0))[3]]);

    my $file = prepFile(shift);

    if (-f $file) { 
        $log{msg}->({
            level => DEBUG, 
            caller => (caller(0))[0], 
            line => (caller(0))[2]
        }, "$file is a file");
        return 1; 
    } else { 
        $log{msg}->({
            level => DEBUG, 
            caller => (caller(0))[0], 
            line => (caller(0))[2]
        }, "$file is not a file");
        return 0; 
    }
}

sub isDir {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;
    $log{mod_dump}->({caller => (caller(0))[0], line => (caller(0))[2]}, [\@_], [(caller(0))[3]]);

    my $file = prepFile(shift);

    if (-d $file) { 
        $log{msg}->({
            level => DEBUG, 
            caller => (caller(0))[0], 
            line => (caller(0))[2]
        }, "$file is a directory");
        return 1; 
    } else { 
        $log{msg}->({
            level => DEBUG, 
            caller => (caller(0))[0], 
            line => (caller(0))[2]
        }, "$file is not a directory");
        return 0; 
    }
}

sub isLink {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;
    $log{mod_dump}->({caller => (caller(0))[0], line => (caller(0))[2]}, [\@_], [(caller(0))[3]]);

    my $file = prepFile(shift);

    if (-l $file) { 
        $log{msg}->({
            level => DEBUG, 
            caller => (caller(0))[0], 
            line => (caller(0))[2]
        }, "$file is a symbolic link");
        return 1; 
    } else { 
        $log{msg}->({
            level => DEBUG, 
            caller => (caller(0))[0], 
            line => (caller(0))[2]
        }, "$file is not a symbolic link");
        return 0; 
    }
}

sub append {
    # shift if defined $_[0] && $_[0] eq __PACKAGE__;

    # my ($dir, $file) = &prep(shift);

    # if (open(my $fh, '>>', "$dir/$file")) {
    #     foreach my $line (@_) {
    #         $log{mod_dump}->([$line], [qw(append)]);
    #         print $fh "$line\n";
    #     }
    #     close $fh;
    # } else {
    #     $log{msg}->(ERROR, "$!");
    #     $say->(LIGHTRED."Could not open file '".WHITE."$dir/$file".LIGHTRED."'");
    #     return 0;
    # }
    # return 1;
}

1;