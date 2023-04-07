package Crypt::Passphrase::Argon2::AES;

use strict;
use warnings;

our $VERSION = '0.001';

use parent 'Crypt::Passphrase::Argon2::Encrypted';
use Crypt::Passphrase 0.010 -encoder;

use Carp 'croak';
use Crypt::Rijndael;

my %mode = (
	'aes-cbc' => Crypt::Rijndael::MODE_CBC,
	'aes-ecb' => Crypt::Rijndael::MODE_ECB,
	'aes-cfb' => Crypt::Rijndael::MODE_CFB,
	'aes-ofb' => Crypt::Rijndael::MODE_OFB,
	'aes-ctr' => Crypt::Rijndael::MODE_CTR,
);

sub new {
	my ($class, %args) = @_;
	my $peppers = $args{peppers} or croak('No peppers given');
	$args{active} //= (sort {; no warnings 'numeric'; $b <=> $a || $b cmp $a } keys %{ $peppers })[0];
	my $mode = $args{mode} // 'cbc';
	my $cipher = "aes-$mode";
	croak("No such cipher $cipher") if not exists $mode{$cipher};
	my $self = $class->SUPER::new(%args, cipher => $cipher);
	$self->{peppers} = $peppers;
	return $self;
}

sub encrypt_hash {
	my ($self, $cipher, $id, $iv, $raw) = @_;
	my $mode = $mode{$cipher} or croak "No such cipher $cipher";
	my $secret = $self->{peppers}{$id} or croak "No such pepper $id";
	return Crypt::Rijndael->new($secret, $mode)->encrypt($raw, $iv);
}

sub decrypt_hash {
	my ($self, $cipher, $id, $iv, $raw) = @_;
	my $mode = $mode{$cipher} or croak "No such cipher $cipher";
	my $secret = $self->{peppers}{$id} or croak "No such pepper $id";
	return Crypt::Rijndael->new($secret, $mode)->decrypt($raw, $iv);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Crypt::Passphrase::Argon2::AES - A peppered AES-encrypted Argon2 encoder for Crypt::Passphrase

=head1 SYNOPSIS

 my $passphrase = Crypt::Passphrase->new(
     encoder => {
         module  => 'Argon2::AES',
         peppers => {
             1 => pack('H*', '0123456789ABCDEF...'),
             2 => pack('H*', 'FEDCBA9876543210...'),
         },
     },
 );

=head1 DESCRIPTION

This class implements peppering by encrypting the hash using AES (unlike L<Crypt::Passphrase::Pepper::Simple|Crypt::Passphrase::Pepper::Simple> which hashes the input instead).

=head1 METHODS

=head2 new

This constructor takes all arguments also taken by L<Crypt::Passphrase::Argon2|Crypt::Passphrase::Argon2>, with the following additions:

=over 4

=item * peppers

This is a map of identifier to pepper value. The identifiers should be (probably small) numbers, the values should be random binary strings that must be either 16, 24 or 32 bytes long.

=item * active

This is the key of the active pepper. By default it will be the key with the highest (numerical) value.

=item * mode

This is the mode that will be used with C<AES>. Values values are C<'ecb'>, C<'cbc'> (the default), C<'cfb'>, C<'ofb'> and C<'ctr'>.

=back

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


