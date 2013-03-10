use strict;
use warnings;
use DBD;

my @years = qw(1980	1981 1982 1983 1984 1985 1986 1987 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007);

my $dbd = DBD->new;
$dbd->Connect_DB;
#$dbd->Init_DB;
foreach(@years){
	$dbd->add_year_DB($_);
}

my $y = $dbd->get_year_DB(27);
print "id 27 = $y\n";


