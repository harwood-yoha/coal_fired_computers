use strict;
use warnings;
use DBD;


	my $dbd = DBD->new;
	$dbd->Connect_DB;
#$dbd->Init_DB;
#$dbd->add_student_DB('mick',32,'London');


	my $input;
	my $continue = "yes";	

	while (lc($continue) eq "yes")
	{
		print "Enter name:";
		$input = <>;
		chop $input;
		my $name = $input;

		print "Enter town:";	
		$input = <>;
		chop $input;
		my $town = $input;

		print "Enter age:";
		$input = <>;
		chop $input;
		my $age = $input;		
		$dbd->add_student_DB($name,$age,$town);		
		print "Continue?\n";
		$continue = <>;
		chop $continue;		
	}
