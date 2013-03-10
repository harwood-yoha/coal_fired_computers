#!/usr/bin/perl
#use warnings;
use lib "/home/cfc/Desktop/CFC/screen/";
use Time::HiRes qw(usleep);
use DateTime;
use DateTime::Duration;
use IO::Socket::INET; 
use lib 'DBMS';
use DBMS::DBD;
use strict;


require Term::Screen;

######## constants
use constant RELAY_ON			=> 'a';
use constant RELAY_OFF			=> 'b';
use constant RELAY_ONC			=> 'c';
use constant RELAY_OFFD			=> 'd';
use constant COL_PRODUCTION		=> 16;
use constant ROW_PRODUCTION		=> 4;
use constant COL_PRODUCTION_DATA		=> 40;
use constant COL_MINER			=> 16;
use constant ROW_MINER			=> 4;
use constant COL_MINER_DATA		=> 34;
use constant COL_BREATH			=> 16;
use constant ROW_BREATH			=> 4;

use constant SLEEP_BF_CONS_PRODS 	=> 2500000;
use constant SLEEP_AFT_CONS_PRODS 	=> 2500000;
use constant SLEEP_WHILE_MINER 		=> 20000000;

use constant STRING_LENGTH		=> 40;
use constant DISP_CONS_PRODS 		=> 10000000;
use constant DUST_PER_SHORT_TON 	=> 3.0;
use constant SHORT_TON 			=> 907.18; #0.907 metric ton or 907.18 kilograms
use constant BREATH 			=> 2500000;
use constant BREATH_INTERVAL		=> 100000;
use constant BREATH_HOLD		=> 3000000;
use constant DELAY_START		=> 21275000;
use constant SHUTDOWN_HR		=> 21;
use constant SHUTDOWN_MIN		=> 0;
# durations
# msgs
use constant WELCOME_MSG		=> "COAL FIRED COMPUTERS";
use constant COPD			=> "Chronic obstructive pulmonary disease (COPD) chronic bronchitis and emphysema, a pair of two commonly co-existing diseases of the lungs in which the airways become narrowed.";
use constant HELP_MSG			=> "press any key to stop script";
use constant TIME_ZONE			=> "Europe/London";

######## gblobals
my @miner_id;
my $miner_index = 0;
my $cons_prods_index = 0;
my $time_offset = DateTime::Duration->new(days => 1);
my $last_call_time_dialled;
my $has_modem = 1;
my $curr_row = 0;
my $curr_col = 0;
my $clcnt = 0;
my @texts;
my @claims_ids;
my %claims;
my %miner;
my @text;
my $port;
#reset_arduino('/dev/ttyUSB0');
######## init screen
my $scr = new Term::Screen;
unless ($scr) { die " Something's wrong w/screen \n"; }


####### setup
my $start_date = DateTime->now(time_zone=>TIME_ZONE)->subtract_duration($time_offset);
#my $call_row = get_next_call($start_date);
# screen message
$scr->clrscr();
$scr->at(0, ($scr->cols()/2) - (length(WELCOME_MSG)/2))->puts(WELCOME_MSG);
my $msg_border = '+---------------------------------------------------------------------------+';
$scr->at(0, ($scr->cols()/2) - (length($msg_border)/2))->puts($msg_border);
usleep(DELAY_START);
$curr_row = 0;

####### main loop
my $cnt=0;
get_dbms_text();
#get_dbms_claims();
get_miner_ids();


while(not $scr->key_pressed()){
		$scr->clrscr();
	usleep(SLEEP_BF_CONS_PRODS);
	disp_cons_prod();
	$scr->at(-1,-1); 
	usleep(DISP_CONS_PRODS);
	$scr->clrscr();
	usleep(SLEEP_AFT_CONS_PRODS);
	my $lines = 0;
    	#my $ln = disp_claims();

	my $ln = disp_miner();
	$scr->at(-1,-1); 

	$scr->normal();
	#######breath in
        contact_server("MINER","ON");	
	######hold
	my $str = '=';
	my $cnt = 0;
	for(my $breath = 0;$breath < BREATH; $breath += BREATH_INTERVAL){	
		my $b_str = make_breath_str($cnt);	
		disp_breath($b_str,$ln);
		$scr->at(-1,-1); 
		usleep(BREATH_INTERVAL);
		$cnt++;
		
	}
#	usleep(BREATH_HOLD);
	########breath out		
	
	for(my $breath = 0;$breath <= BREATH; $breath += BREATH_INTERVAL){	
		my $b_str = make_breath_str($cnt);	
		disp_breath($b_str,$ln);
		$scr->at(-1,-1); 
		usleep(BREATH_INTERVAL);
		$cnt--;
	}
	usleep(SLEEP_WHILE_MINER);

    	#print "start '$str'\n";
	#sleep int(rand(15));
	

	#check_result($str);

}
contact_server("quit","quit");		
exit;


sub border {
	my $str = '';
	my $l = (STRING_LENGTH + COL_MINER_DATA)- COL_MINER;
	foreach(0..$l){$str .= '_'};
	return $str;
}

sub title_space {
	my $title = shift;          
	my $maxwidth = (STRING_LENGTH + COL_MINER_DATA)- COL_MINER;
        $maxwidth = length($title) if length($title) > $maxwidth;
        my $spc = '';  
        foreach( 0..($maxwidth - length($title))/2){
		$spc .= ' ';
	}

            #$title = " " * (($maxwidth - length($title))/2) . $title;
          return $spc.$title;
          
}


sub make_breath_str {
	my $num = shift;
	my $str;
	for($cnt = 0; $cnt < $num;$cnt++){
		$str .= '=';
	}
	return $str.'>';
}


sub disp_cons_prod {
	if($cons_prods_index == $#text){
		$cons_prods_index = 0;
	}else{
		$cons_prods_index++;
	}
	my @a = @{$text[$cons_prods_index]};
	
	my $msg_border = title_space('COAL CONSUMPTION & PRODUCTION');
	$scr->at(ROW_PRODUCTION+1, COL_MINER)->clreol()->bold()->puts(border());

	$scr->at(ROW_PRODUCTION+3, COL_PRODUCTION)->clreol()->puts($msg_border);
	$scr->at(ROW_PRODUCTION+4, COL_MINER)->clreol()->bold()->puts(border());

	$scr->at(ROW_PRODUCTION+6, COL_PRODUCTION)->clreol()->puts("Year: ".$a[1]);
	$scr->at(ROW_PRODUCTION+7, COL_PRODUCTION)->clreol()->puts("Country: ".$a[0]);
	$scr->at(ROW_PRODUCTION+8, COL_PRODUCTION)->clreol()->puts("Coal Produced: ".$a[2]." (Million Short Tons)");
	my $dust = int((($a[2]* 1000000) * DUST_PER_SHORT_TON)/SHORT_TON);
	$scr->at(ROW_PRODUCTION+9, COL_PRODUCTION)->clreol()->puts("Coal Dust Created: $dust (Short Tons)");

	$scr->at(ROW_PRODUCTION+10, COL_PRODUCTION)->clreol()->puts("Coal Consumed: ".$a[3]." (Million Short Tons)");
	
	my $displaced;
	if($a[3] > $a[2]){
		$displaced = $a[3] - $a[2];
	}else{$displaced = 0;}
	$scr->at(ROW_PRODUCTION+11, COL_PRODUCTION)->clreol()->puts("Displaced Production: $displaced (Million Short Tons)");
	my $msg_border1 = border();
	$scr->at(ROW_PRODUCTION+12, COL_PRODUCTION)->clreol()->puts($msg_border1);
	$scr->at(ROW_PRODUCTION+14, COL_PRODUCTION)->clreol()->puts($msg_border1);

}

sub disp_miner {

	if($miner_index == $#miner_id){
		$miner_index = 0;
	}else{
		$miner_index++;
	}
	
	my $id = $miner_id[$miner_index];
	my $dbd = DBMS::DBD->new;
	$dbd->Connect_DB;
	
	%miner = undef;
	$miner{id} = $id;
	die "no miner id '$miner_index' ".$miner_id[$miner_index] unless $miner{id};
	$dbd->get_miner_DB(\%miner);	
	foreach(keys %miner){$miner{$_} = trim($miner{$_})}
	if($miner{miner_age} == 0){$miner{miner_age} = 'UNKOWN'}
	my $cnt =1;
	my $msg_border = border();
	$scr->at(ROW_MINER+$cnt, COL_MINER)->clreol()->bold()->puts($msg_border);
	$cnt+=2;
	my $msg_name =  title_space('UK ACCIDENTS & DEATHS');
	$scr->at(ROW_MINER+$cnt, COL_MINER)->clreol()->bold()->puts($msg_name);
	$cnt++;
	$scr->at(ROW_MINER+$cnt, COL_MINER)->clreol()->bold()->puts($msg_border);
	$cnt+=2;
	$scr->at(ROW_MINER+$cnt, COL_MINER)->clreol()->bold()->puts("NAME:"); 
	$scr->at(ROW_MINER+$cnt, COL_MINER_DATA)->clreol()->normal()->puts($miner{miner_name});
	$cnt++;
	$scr->at(ROW_MINER+$cnt, COL_MINER)->clreol()->bold()->puts("Age:");
	$scr->at(ROW_MINER+$cnt, COL_MINER_DATA)->clreol()->normal()->puts($miner{miner_age});
	$cnt++;
	$scr->at(ROW_MINER+$cnt, COL_MINER)->clreol()->bold()->puts("ACCIDENT DATE:");
	$scr->at(ROW_MINER+$cnt, COL_MINER_DATA)->clreol()->normal()->puts($miner{miner_date});
	$cnt++;
	$scr->at(ROW_MINER+$cnt, COL_MINER)->clreol()->bold()->puts("OCCUPATION:");
	$scr->at(ROW_MINER+$cnt, COL_MINER_DATA)->clreol()->normal()->puts($miner{miner_occupation});
	$cnt++;
	$scr->at(ROW_MINER+$cnt, COL_MINER)->clreol()->bold()->puts("COLLIERY:");
	$scr->at(ROW_MINER+$cnt, COL_MINER_DATA)->clreol()->normal()->puts($miner{miner_colliery});
	$cnt++;
	$scr->at(ROW_MINER+$cnt, COL_MINER)->clreol()->bold()->puts("OWNER:");
	$scr->at(ROW_MINER+$cnt, COL_MINER_DATA)->clreol()->normal()->puts($miner{miner_owner});
	$cnt++;
	$scr->at(ROW_MINER+$cnt, COL_MINER)->clreol()->bold()->puts("NOTES:");
	my @strngs = string_format($miner{miner_notes});
	foreach(@strngs){
		$scr->at(ROW_MINER+$cnt, COL_MINER_DATA)->clreol()->normal()->puts($_);
		$cnt++;
	}
	$cnt++;
	my $msg_border1 = border();
	$scr->at(ROW_MINER+$cnt, COL_MINER)->clreol()->bold()->puts($msg_border1);
	return $cnt;

}


sub string_format {
	my $str = shift;
	my @words = split(/\s/,$str);
	my @string;
	my $cnt = 0;
	foreach my $w (@words){
		$string[$cnt] .= "$w ";
		if( length ($string[$cnt]) > STRING_LENGTH){$cnt++}
	}
	#foreach (@string){print "$_\n"}

	return (@string);

}

# Perl trim function to remove whitespace from the start and end of the string
sub trim()
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}



sub disp_claims {

	my $id = $claims_ids[$clcnt];
	if($clcnt == $#claims_ids){
		$clcnt = 0;
	}else{
		$clcnt++;
	}
	
	my $msg_border = '_______________UK _______________';
	

	#foreach(keys %{$claims{$id}}){$claims{$id}{$_}= trim($claims{$id}{$_})}
#	if($miner{miner_age} == 0){$miner{miner_age} = 'UNKOWN'}
	my $cnt =1;
	my $msg_border = border();
	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION)->clreol()->bold()->puts($msg_border);
	$cnt+=2;
	my $msg_name =  title_space('UK CLAIMS: MINERS LUNG DISEASE');
	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION)->clreol()->bold()->puts($msg_name);
	$cnt++;
	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION)->clreol()->bold()->puts($msg_border);
	$cnt+=2;
	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION)->clreol()->bold()->puts("CONSTITUENCY:"); 
	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION_DATA)->clreol()->normal()->puts($claims{$id}{claims_constituency});
	$cnt++;
	$scr->at(ROW_PRODUCTION+$cnt, COL_MINER)->clreol()->bold()->puts("CLAIMS LIVING:");
	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION_DATA)->clreol()->normal()->puts($claims{$id}{claims_live});
	$cnt++;
	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION)->clreol()->bold()->puts("CLAIMS DEAD:");
	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION_DATA)->clreol()->normal()->puts($claims{$id}{claims_dead});
	$cnt++;
	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION)->clreol()->bold()->puts("TOTAL CLAIMS:");
	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION_DATA)->clreol()->normal()->puts($claims{$id}{claims_total});
	$cnt++;
	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION)->clreol()->bold()->puts("AWAITING OFFER:");
	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION_DATA)->clreol()->normal()->puts($claims{$id}{awaiting_initial_offer});
	$cnt++;
	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION)->clreol()->bold()->puts("OFFER MADE:");
	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION_DATA)->clreol()->normal()->puts($claims{$id}{offer_made_await_response});
	$cnt++;
	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION)->clreol()->bold()->puts("OFFER CHALLENGED:");
	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION_DATA)->clreol()->normal()->puts($claims{$id}{offer_made_subsequently_challenged});
	$cnt++;
	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION)->clreol()->bold()->puts("SETTLED CLAIMS DEAD:");
	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION_DATA)->clreol()->normal()->puts($claims{$id}{settled_claims_dead});
	$cnt++;
	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION)->clreol()->bold()->puts("SETTLED CLAIMS ALIVE:");
	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION_DATA)->clreol()->normal()->puts($claims{$id}{settled_claims_alive});
	$cnt++;
	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION)->clreol()->bold()->puts("SETTLED CLAIMS:");
	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION_DATA)->clreol()->normal()->puts($claims{$id}{total_settled_claims});
	$cnt++;

	my $d = $claims{$id}{damages_paid}; 
	$d	=~ s/\,//g;


	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION)->clreol()->bold()->puts("TOTAL DAMAGES PAID:");
	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION_DATA)->clreol()->normal()->puts('£'.$claims{$id}{damages_paid});
	$cnt++;

	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION)->clreol()->bold()->puts("AVEREDGE PER MINER:");
	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION_DATA)->clreol()->normal()->puts("£".commify(int($d/$claims{$id}{total_settled_claims})));
	$cnt++;


	my $msg_border1 = border();
	$scr->at(ROW_PRODUCTION+$cnt, COL_PRODUCTION)->clreol()->bold()->puts($msg_border1);
	return $cnt;

}

sub disp_breath {
	
	my ($str,$ln) = @_;

	
	my $msg_border = border();
	#my $msg_name =  title_space('BREATH');
	$ln+=2;
	$scr->at(ROW_BREATH+$ln, COL_BREATH)->clreol()->bold()->puts('BREATH');
	#$scr->at(ROW_BREATH+3, COL_BREATH)->clreol()->bold()->puts($msg_border);
	$scr->at(ROW_BREATH+$ln, COL_BREATH+length('BREATH '))->clreol()->normal()->puts($str);
	$ln++;
	$scr->at(ROW_BREATH+$ln, COL_BREATH)->clreol()->bold()->puts($msg_border);

}

sub commify {
          local $_  = shift;
          1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
          return $_;
          }

sub get_dbms_claims {
 	my $dbd = DBMS::DBD->new;
	$dbd->Connect_DB;
	$dbd->get_claims_ids_DB(\%claims);
	#	die keys %claims;
	foreach (sort(keys %claims)){

		push(@claims_ids,$_);
		$dbd->get_claims_DB(\%claims,$_); 
	}


}

sub get_miner_ids {
	my $dbd = DBMS::DBD->new;
	$dbd->Connect_DB;
	$dbd->get_dbms_miner_ids(\@miner_id);
}
sub get_next_miner {
	my $dbd = DBMS::DBD->new;
	$dbd->Connect_DB;
	$dbd->get_dbms_miner(\%miner);
}
sub get_dbms_text {
 	my $dbd = DBMS::DBD->new;
	$dbd->Connect_DB;
	my %countries; #hash to hold countries and ids
	$dbd->get_countries_DB(\%countries);
	my %years; #hash to hold countries and ids
	$dbd->get_years_DB(\%years);
	my @y = keys %years;
	fisher_yates_shuffle(\@y);
	foreach my $id (@y){
		foreach my $country_id (keys %countries){
			my $production = $dbd->get_country_production_DB( 	
				$countries{$country_id}{name},
				$years{$id}{year}
			);
			my $consumption = $dbd->get_country_consumption_DB( 	
				$countries{$country_id}{name},
				$years{$id}{year}
			);
			my @entry = ($countries{$country_id}{name},$years{$id}{year},$production,$consumption);
			push(@text,[@entry]);

		}
	}

}


sub to_screen{
	my $msg = shift;
	my $type = shift;
	my $debug = shift;

#	if($curr_row > ($scr->rows() - ROW_PADDING)){
#		my $row_diff = $scr->rows() - ROW_PADDING - $curr_row;
#		while($row_diff < 1){
#			$scr->at(ROW_PADDING, 0)->dl();
#			$curr_row --;
#			$row_diff ++;
#		}
#	}
if($type eq 'production'){
	$scr->at(ROW_PRODUCTION, COL_PRODUCTION)->clreol()->puts($msg);
		$scr->normal();


}


#	if($debug){
#		if(DEBUG){
#		$scr->reverse();
#		$scr->at(ROW_PADDING, COL_PADDING)->clreol()->puts($msg);
#		$scr->normal();
#		}
#	}else{
#		$curr_col = length($msg);
#		$scr->at($curr_row, COL_PADDING)->puts($msg)->at($curr_row, $scr->cols());
#		$curr_row += 1;
#	}

}

	


# fisher_yates_shuffle( \@array ) : generate a random permutation
# of @array in place
sub fisher_yates_shuffle {
    my $array = shift;
    my $i;
    for ($i = @$array; --$i; ) {
        my $j = int rand ($i+1);
        next if $i == $j;
        @$array[$i,$j] = @$array[$j,$i];
    }
}

sub contact_server {
	my ($type,$switch) = @_;
	
	my $remote_host = "127.0.0.1";
	my $remote_port = "20204";
	
	my	$socket = IO::Socket::INET->new(PeerAddr => $remote_host,
                                PeerPort => $remote_port,
                                Proto    => "tcp",
                                )#Type     => SOCK_STREAM)
    or die "Couldn't connect to $remote_host:$remote_port : $@\n";

	# ... pack args for socket
	my $args = 	"TYPE:$type SWITCH:$switch";

	print $socket "$args\n";

	close($socket);

}
