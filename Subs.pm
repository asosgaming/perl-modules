package ASoS::Subs;

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

use ASoS::Log;
use ASoS::Common qw(:COLORS :SUB);

our @ISA = qw(Exporter);
our @EXPORT = qw(mergeOptions);

sub mergeOptions {
    shift if defined $_[0] && $_[0] eq __PACKAGE__;

    #TODO: rewrite to return a parsed hash instead of logging through here
    #TODO: move to common.pm
    my $in = shift;
    my %hash = %$in;
    my %opt = mergeHash(\%hash, @_);

    # remove non persistant args
    my $dump = delete $opt{-dump} // 1;

    # temporarily remove args that we dont want to show
    my $module = delete $opt{-module} // 0;
    my $cmd = delete $opt{-cmd} // undef;
    my $success = delete $opt{-success} // undef;
    my $failed = delete $opt{-failed} // undef;
    my @vars = delete $opt{-vars} // ();

    # combine args
    my $mainargs = delete $opt{-mainargs} // '';
    $opt{-args} = ((defined $opt{-args})
        ? (($mainargs) ? $mainargs.' ' : '').$opt{-args}
        : $mainargs
    );

    #TODO: move logging to each sub that needs
    # log options if dump is requested
    $log{MOD_DEBUG}->(
        -options => [\%opt],
        -indent => 0
    ) if ($dump == '1');

    # restore removed args
    $opt{-module} = $module;
    $opt{-cmd} = $cmd;
    $opt{-success} = $success;
    $opt{-failed} = $failed;
    @{$opt{-vars}} = @vars;

    return %opt;
}


1;