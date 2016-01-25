use strictures 2;

package Moove;

# ABSTRACT: functions and methods with parameter lists and type constraints

use Type::Registry ();
use Type::Utils qw(class_type);
use Function::Parameters ();
use Import::Into ();
use Carp qw(croak);

# VERSION

sub import {
    my $caller = scalar caller;
    my $class = shift;
    my %opts = @_;

    my $registry = Type::Registry->for_class($caller);
    if (my $types = delete $opts{types}) {
        if (ref $types eq 'ARRAY') {
            $registry->add_types(@$types);
        } else {
            $registry->add_types($types);
        }
    }
    if (my $classes = delete $opts{classes}) {
        foreach my $class (@$classes) {
            $registry->add_type(class_type($class) => $class);
        }
    }

    Type::Registry->for_class($caller)->add_types(-Standard);

    Function::Parameters->import::into($caller, {
        method => {
            defaults => 'method',
            runtime => 0,
            strict => 1,
            reify_type => \&_reify_type,
        },
        func => {
            defaults => 'function',
            runtime => 0,
            strict => 1,
            reify_type => \&_reify_type,
        }
    });
}

sub _reify_type {
    my ($typedef, $package) = @_;
    require Type::Registry;
    my $registry = Type::Registry->for_class($package);
    $registry->lookup($typedef) // die "unknown type definition: $typedef";
}

1;

=head1 DESCRIPTION

This module inherits L<Function::Parameters> with some default and the binding against L<Type::Tiny>.

Some reasons to use Moove:

=over 4

=item * No L<Moose> dependency

=item * No L<Devel::Declare> dependency

=item * A nearly replacement for L<Method::Signatures>

=back

This is also a very early release.

=head1 SYNOPSIS

    use Moove;

    func foo (Int $number, Str $text) {
        ...
    }

    use Moove classes => [qw[ Some::Class ]];

    method bar (Some::Class $obj) {
        ...
    }

=head1 IMPORT OPTIONS

The I<import> method supports these keywords:

=over 4

=item * types

As an ArrayRef, calls C<<< Types::Registry->for_class($caller)->add_types(@$types) >>>

As a scalar, calls C<<< Types::Registry->for_class($caller)->add_types($types) >>>

=item * classes

For each class in this ArrayRef, calls C<<< Types::Registry->for_class($caller)->add_types(Type::Utils::class_type($class)) >>>

=back


