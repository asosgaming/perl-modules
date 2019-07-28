package ASoS::Cfg;
 
use strict;
use Exporter;

use ASoS::Say;
use ASoS::Log;
use ASoS::Common qw(:COLORS);

our @ISA = qw(Exporter);
our @EXPORT = qw(%cfg);
our @EXPORT_OK = qw(read write);
our %EXPORT_TAGS = (
    ALL => \@EXPORT_OK
);

our %cfg = (
    read => \&read,
    write => \&write
);

our $VERSION = '2.24';

BEGIN {
        require 5.008001; # For the utf8 stuff.
        $ASoS::Cfg::errstr  = '';
}
 
# Create an empty object.
sub new { return bless {}, shift }
 
# Create an object from a file.
sub read {
    my($class)           = ref $_[0] ? ref shift : shift;
    my($file, $encoding) = @_;

    return $class -> _error('No file name provided') if (! defined $file || ($file eq '') );

    # Slurp in the file.

    $encoding = $encoding ? "<:$encoding" : '<';
    local $/  = undef;

    open( CFG, $encoding, $file ) or return $class -> _error( "Failed to open file '$file' for reading: $!" );
    my $contents = <CFG>;
    close( CFG );

    return $class -> _error("Reading from '$file' returned undef") if (! defined $contents);

    return $class -> read_string( $contents );
}
 
# Create an object from a string.
sub read_string {
    my($class) = ref $_[0] ? ref shift : shift;
    my($self)  = bless {}, $class;

    return undef unless defined $_[0];

    my $ns      = '_';
    my $counter = 0;
 
    foreach ( split /(?:\015{1,2}\012|\015|\012)/, shift )
    {
        $counter++;

        # Skip comments and empty lines.
        next if /^\s*(?:\#|\;|$)/;

        # Remove inline comments.
        s/\s\;\s.+$//g;

        # Handle section headers.
        if ( /^\s*\[\s*(.+?)\s*\]\s*$/ ) {
            # Create the sub-hash if it doesn't exist.
            # Without this sections without keys will not
            # appear at all in the completed struct.

            $self->{$ns = $1} ||= {};
            next;
        }

        # Handle properties.

        if ( /^\s*([^=]+?)\s*=\s*(.*?)\s*$/ )
        {
            $self->{$ns}->{$1} = $2;
            next;
        }

        return $self -> _error( "Syntax error at line $counter: '$_'" );
    }
 
    return $self;
}
 
# Save an object to a file.
sub write {
    my($self)            = shift;
    my($file, $encoding) = @_;

    return $self -> _error('No file name provided') if (! defined $file or ($file eq '') );

    $encoding = $encoding ? ">:$encoding" : '>';

    # Write it to the file.
    my($string) = $self->write_string;

    return undef unless defined $string;

    open( CFG, $encoding, $file ) or return $self->_error("Failed to open file '$file' for writing: $!");
    print CFG $string;
    close CFG;

    return 1;
}
 
# Save an object to a string.
sub write_string {
    my($self)     = shift;
    my($contents) = '';

    for my $section ( sort { (($b eq '_') <=> ($a eq '_')) || ($a cmp $b) } keys %$self )
    {
        # Check for several known-bad situations with the section
        # 1. Leading whitespace
        # 2. Trailing whitespace
        # 3. Newlines in section name.

        return $self->_error("Illegal whitespace in section name '$section'") if $section =~ /(?:^\s|\n|\s$)/s;

        my $block = $self->{$section};
        $contents .= "\n" if length $contents;
        $contents .= "[$section]\n" unless $section eq '_';

        for my $property ( sort keys %$block )
        {
            return $self->_error("Illegal newlines in property '$section.$property'") if $block->{$property} =~ /(?:\012|\015)/s;

            $contents .= "$property=$block->{$property}\n";
        }
    }

    return $contents;
}
 
# Error handling.
sub errstr { $ASoS::Cfg::errstr }
sub _error { $ASoS::Cfg::errstr = $_[1]; undef }
 
1;
 
__END__