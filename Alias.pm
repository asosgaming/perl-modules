package ASoS::Alias; # git description: v0.33-3-g0a61221
# ABSTRACT: Use shorter versions of class names.
$ASoS::Alias::VERSION = '0.34';
require Exporter;
@EXPORT = qw(alias prefix);
 
use strict;
use warnings;
 
sub _croak {
    require Carp;
    Carp::croak(@_);
}
 
sub import {
    # Without args, just export @EXPORT
    goto &Exporter::import if @_ <= 1;
 
    my ( $class, $package, $alias, @import ) = @_;
 
    my $callpack = caller(0);
    _load_alias( $package, $callpack, @import );
    _make_alias( $package, $callpack, $alias );
}
 
sub _get_alias {
    my $package = shift;
    $package =~ s/.*(?:::|')//;
    return $package;
}
 
sub _make_alias {
    my ( $package, $callpack, $alias ) = @_;
 
    $alias ||= _get_alias($package);
 
    my $destination = $alias =~ /::/
      ? $alias
      : "$callpack\::$alias";
 
    # need a scalar not referenced elsewhere to make the sub inlinable
    my $pack2 = $package;
 
    no strict 'refs';
    *{ $destination } = sub () { $pack2 };
}
 
sub _load_alias {
    my ( $package, $callpack, @import ) = @_;
 
    # We don't localize $SIG{__DIE__} here because we need to be careful about
    # restoring its value if there is a failure.  Very, very tricky.
    my $sigdie = $SIG{__DIE__};
    {
        my $code =
          @import == 0
          ? "package $callpack; use $package;"
          : "package $callpack; use $package (\@import)";
        eval $code;
        if ( my $error = $@ ) {
            $SIG{__DIE__} = $sigdie;
            _croak($error);
        }
        $sigdie = $SIG{__DIE__}
          if defined $SIG{__DIE__};
    }
 
    # Make sure a global $SIG{__DIE__} makes it out of the localization.
    $SIG{__DIE__} = $sigdie if defined $sigdie;
    return $package;
}
 
sub alias {
    my ( $package, @import ) = @_;
 
    my $callpack = scalar caller(0);
    return _load_alias( $package, $callpack, @import );
}
 
sub prefix {
    my ($class) = @_;
    return sub {
        my ($name) = @_;
        my $callpack = caller(0);
        if ( not @_ ) {
            return _load_alias( $class, $callpack );
        }
        elsif ( @_ == 1 && defined $name ) {
            return _load_alias( "${class}::$name", $callpack );
        }
        else {
            _croak("Too many arguments to prefix('$class')");
        }
    };
}
 
1;
 
__END__