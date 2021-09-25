package Mail::MIMEDefang::Unit::Utils;

use strict;
use warnings;
use lib qw(lib);
use base qw(Mail::MIMEDefang::Unit);
use Test::Most;

use Mail::MIMEDefang::Utils;

sub t_percent_encode : Test(1)
{
  my $pe = percent_encode("foo\r\nbar\tbl%t");
  is($pe, "foo%0D%0Abar%09bl%25t");
}

sub t_percent_decode : Test(2)
{
  my $pd = percent_decode("foo%0D%0Abar%09bl%25t");
  is($pd, "foo\r\nbar\tbl%t");
}

__PACKAGE__->runtests();
