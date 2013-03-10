
use strict;
use warnings;

package DBMS::DBD;
{
    use DBMS::Settings;
    use DBI;

    use constant FOUND     => 1;
    use constant NOT_FOUND => 0;

    sub new {
        my $class = shift;
        my $This  = {};

        bless $This, $class;
        return $This;
    }

    sub Connect_DB {
        my $This = shift;
        $This->{Dbh} = DBI->connect(
            MYSQL_DB,
            MYSQL_USER,
            MYSQL_PASS,
            {
                PrintError => MYSQL_PRINT_ERROR, #don't report errors via warn
                RaiseError => MYSQL_RAISE_ERROR, #Report errors via die
            }
        );
        return "ERROR: MSQL:\n Did not connect to (MYSQL){DB}: Maybe MYSQL is not setup " unless defined $This->{Dbh};
 
        return;
    }

    sub Init_DB {
        my $This = shift;
        # create the rables of the Monster
        #no strict "refs";
        my @Tables = keys(%MYSQL_TABLES);
        foreach (@Tables) {
            print "\n making table $_ ";
            my $query = $This->{Dbh}->prepare( $MYSQL_TABLES{$_} )
              or return "\n<P>ERROR: MSQL:<P>\n Can't prepare SQL $DBI::errstr\n";
            $query->execute
              or return "\n<P>ERROR: MSQL:<P>\n Can't execute SQL $DBI::errstr\n";
        }
        return;
    }

# special stuff to disconect properly from the database.
#
    sub Disconnect_DB {
        my $This = shift;
        # connect to database (regular DBI)
        $This->{Dbh}->disconnect;
        return;
    }

    sub DESTROY {
        my $This = shift;
        $This->Disconnect_DB unless not defined $This->{Dbh};

    }

	sub last_inserted_id {
        my $This  = shift;
        my $table = shift;

        my $query =
          $This->{Dbh}->prepare("SELECT LAST_INSERT_ID() FROM $table ");
        $query->execute;
        my ($ID) = $query->fetchrow_array;

        $query->finish;

        return $ID;

    }



    sub update_student_DB {
		# update values for an image 
        my $This = shift;
        my $id   = shift;

        if ($id) {
            my %keyPairs = @_;
            my @query = ();
            my @keys  = keys(%keyPairs);
            foreach (@keys) {
                push( @query, "$_ = " . $This->{Dbh}->quote( $keyPairs{$_} ) );
            }
            my $query_str = "update student set ";
            $query_str .= join( ", ", @query ) . " where student_id = $id";
            my $query = $This->{Dbh}->prepare($query_str);
            $query->execute;
            $query->finish;
        }
        else { die "<P> NO student_id for update_student_DB $id" }

    }
##################### COUNTRY #################
	sub get_country_DB {
        	my ( 	
				$This,
				$id,
		  	) = @_;

        	my $query    = $This->{Dbh}->prepare(
            	"SELECT country_name FROM country	WHERE country_id=$id "
     		);
        	$query->execute;
			my $q = -1;
        	($q) = $query->fetchrow_array;
        	$query->finish;
        	die 'out of range' unless $q > -1;
			
			return $q;
	}
	sub get_countries_DB {
        	my ( 	
				$This,
				$countries_ref
		  	) = @_;

        	my $query    = $This->{Dbh}->prepare(
            	"SELECT * FROM country"
     		);
        	$query->execute;
			my $q = -1;
        	while( my($id, $name) = $query->fetchrow_array){
				$countries_ref->{$id}{name}  = $name;
			}
        	$query->finish;
        	#die 'out of range' unless $q > -1;
			
		#	return $q;
	}
 	sub get_country_production_DB{
		my ( 	
				$This,
				$country,
				$year
		  	) = @_;
			
			my $qcountry_name = $This->{Dbh}->quote($country);

        	my $query    = $This->{Dbh}->prepare(
            	"SELECT country_id FROM country	WHERE country_name=$qcountry_name "
     		);
        	$query->execute;
			my $country_id = -1;
        	($country_id) = $query->fetchrow_array;
        	$query->finish;
			die 'no country id' if $country_id == -1;
			my $year_id = $This->add_year_DB($year);	
			
			$query    = $This->{Dbh}->prepare(
            	"SELECT production_value FROM production	
				WHERE 
				production_year_id=$year_id and  
				production_country_id=$country_id
				"
     		);
        	$query->execute;
			
			my $value = -1;
        	($value) = $query->fetchrow_array;
        	$query->finish;
			return $value;
	
	}
	
	sub get_country_consumption_DB{
		my ( 	
				$This,
				$country,
				$year
		  	) = @_;
			my $qcountry_name = $This->{Dbh}->quote($country);

        	my $query    = $This->{Dbh}->prepare(
            	"SELECT country_id FROM country	WHERE country_name=$qcountry_name "
     		);
        	$query->execute;
			my $country_id = -1;
        	($country_id) = $query->fetchrow_array;
        	$query->finish;
			die 'no country id' if $country_id == -1;
			my $year_id = $This->add_year_DB($year);
			
			$query    = $This->{Dbh}->prepare(
            	"SELECT consumption_value FROM consumption	
				WHERE 
				consumption_year_id=$year_id and  
				consumption_country_id=$country_id
				"
     		);
        	$query->execute;
			
			my $value = -1;
        	($value) = $query->fetchrow_array;
        	$query->finish;
			return $value;

	
	}

	
	
	sub add_country_DB {
        	my ( 	
				$This,
				$country,
		  	) = @_;
			my $qcountry_name = $This->{Dbh}->quote($country);

        	my $query    = $This->{Dbh}->prepare(
            	"SELECT country_id FROM country	WHERE country_name=$qcountry_name "
     		);
        	$query->execute;
			my $id = -1;
        	($id) = $query->fetchrow_array;
        	$query->finish;
        	
			if ($id) {
            		return $id;
        	} else {
            	my $query = $This->{Dbh}->prepare(
                "INSERT INTO country
				(
					country_name 
				) 
				values(
					$qcountry_name
				)"
            	);
            	$query->execute;
            	$query->finish;
        }	
        return ( $This->last_inserted_id('country') );
    }

################## YEAR ###################
	sub get_year_DB {
        	my ( 	
				$This,
				$year_id,
		  	) = @_;

        	my $query    = $This->{Dbh}->prepare(
            	"SELECT year_year FROM year	WHERE year_id=$year_id "
     		);
        	$query->execute;
			my $year = -1;
        	($year) = $query->fetchrow_array;
        	$query->finish;
        	die 'year out of range' unless $year > -1;
			
			return $year;
	}
	sub get_years_DB {
        	my ( 	
				$This,
				$years_ref
		  	) = @_;

        	my $query    = $This->{Dbh}->prepare(
            	"SELECT * FROM year"
     		);
        	$query->execute;
        	while( my($id, $value) = $query->fetchrow_array){
				$years_ref->{$id}{year}  = $value;
			}
        	$query->finish;
        	#die 'out of range' unless $q > -1;
			
		#	return $q;
	}
	sub add_year_DB {
        	my ( 	
				$This,
				$year,
		  	) = @_;

        	my $query    = $This->{Dbh}->prepare(
            	"SELECT year_id FROM year	WHERE year_year=$year "
     		);
        	$query->execute;
			my $year_id = -1;
        	($year_id) = $query->fetchrow_array;
        	$query->finish;
        	
			if ($year_id) {
            		return $year_id;
        	} else {
            	my $query = $This->{Dbh}->prepare(
                "INSERT INTO year
				(
					year_year 
				) 
				values(
					$year
				)"
            	);
            	$query->execute;
            	$query->finish;
        }	
        return ( $This->last_inserted_id('year') );
    }
######################## Consumption ##################

	
	sub add_consumption_DB {
        	my ( 	
			$This,
			$value,
			$year,
			$country,
	  	) = @_;

        	my $year_id = $This->add_year_DB($year);
			my $country_id = $This->add_country_DB($country);
		
			my $query    = $This->{Dbh}->prepare(
            	"SELECT consumption_id FROM consumption	
				WHERE 
				consumption_year_id=$year_id and  
				consumption_country_id=$country_id and 
				consumption_value = '$value'
				"
     		);
        	$query->execute;
			
			my $id = -1;
        	($id) = $query->fetchrow_array;
        	$query->finish;
        	if ($id) {
            		return $id;
        	} else {

            my $query = $This->{Dbh}->prepare(
                	"INSERT INTO consumption
			(
				consumption_value, 
				consumption_year_id,
				consumption_country_id
			) 
			values(
				'$value',
				'$year_id',
				'$country_id'
			)"
            	);
            $query->execute;
            $query->finish;
        }
		
        return ( $This->last_inserted_id('consumption') );
    }


############################ production ###########
#
	sub add_production_DB {
        	my ( 	
			$This,
			$value,
			$year,
			$country,
	  	) = @_;

        	my $year_id = $This->add_year_DB($year);
			my $country_id = $This->add_country_DB($country);
		
			my $query    = $This->{Dbh}->prepare(
            	"SELECT production_id FROM production	
				WHERE 
				production_year_id=$year_id and  
				production_country_id=$country_id and 
				production_value = '$value'
				"
     		);
        	$query->execute;
			
			my $id = -1;
        	($id) = $query->fetchrow_array;
        	$query->finish;
        	if ($id) {
            		return $id;
        	} else {

            my $query = $This->{Dbh}->prepare(
                	"INSERT INTO production
			(
				production_value, 
				production_year_id,
				production_country_id
			) 
			values(
				'$value',
				'$year_id',
				'$country_id'
			)"
            	);
            $query->execute;
            $query->finish;
        }
		
        return ( $This->last_inserted_id('production') );
    }
################################## CLAIMS #####################################
#
	sub get_claims_ids_DB {
        	my ( 	
				$This,
				$claims_ref
		  	) = @_;

        	my $query    = $This->{Dbh}->prepare(
            	"SELECT claims_id FROM claims"
     		);
        	$query->execute;
        	while( 
				my (	$cid ) = $query->fetchrow_array){
				$claims_ref->{$cid}{claims_constituency} = 'dummy';

			}
        	$query->finish;
        	#die 'out of range' unless $q > -1;
			
		#	return $q;
	}	

	sub get_claims_DB {
        	my ( 	
				$This,
				$claims_ref,
				$id
		  	) = @_;

        	my $query    = $This->{Dbh}->prepare(
            	"SELECT *FROM claims where claims_id = '$id'"
     		);
        	$query->execute;
        	while( 
				my (@claim) = $query->fetchrow_array){
				$claims_ref->{$id}{claims_constituency} = $claim[1];
				$claims_ref->{$id}{claims_live} = $claim[2];
				$claims_ref->{$id}{claims_dead} = $claim[3];
				$claims_ref->{$id}{claims_total} = $claim[4];
				$claims_ref->{$id}{awaiting_initial_offer} = $claim[5];
				$claims_ref->{$id}{offer_made_await_response} = $claim[6];
				$claims_ref->{$id}{offer_made_subsequently_challenged} = $claim[7];
				$claims_ref->{$id}{settled_claims_dead} = $claim[8];
				$claims_ref->{$id}{settled_claims_alive} = $claim[9];
				$claims_ref->{$id}{total_settled_claims} = $claim[10];
				$claims_ref->{$id}{damages_paid} = $claim[11];

			}
        	$query->finish;
        	
	
			
			}	

sub add_claims_DB {
        	my ( 	
			$This,
			$claims_ref
	  	) = @_;
			
        	foreach (keys %{$claims_ref}){
				$claims_ref->{$_}	= $This->{Dbh}->quote($claims_ref->{$_});
			}
			my $query    = $This->{Dbh}->prepare(
            	"SELECT claims_id FROM claims	
				WHERE 
				claims_constituency like $claims_ref->{claims_constituency}
				"
     		);
        	$query->execute;
			
			my $id = -1;
        	($id) = $query->fetchrow_array;
        	$query->finish;
        	if ($id) {
            		return $id;
        	} else {

            my $query = $This->{Dbh}->prepare(
                	"INSERT INTO claims
			(					 
				claims_constituency,
				claims_live,
				claims_dead, 
				claims_total, 
				awaiting_initial_offer, 
				offer_made_await_response, 
				offer_made_subsequently_challenged, 
				settled_claims_dead, 
				settled_claims_alive, 
				total_settled_claims,  
				damages_paid 
			) 
			values(
				$claims_ref->{claims_constituency},
				$claims_ref->{claims_live},
				$claims_ref->{claims_dead}, 
				$claims_ref->{claims_total}, 
				$claims_ref->{awaiting_initial_offer}, 
				$claims_ref->{offer_made_await_response}, 
				$claims_ref->{offer_made_subsequently_challenged}, 
				$claims_ref->{settled_claims_dead}, 
				$claims_ref->{settled_claims_alive}, 
				$claims_ref->{total_settled_claims},  
				$claims_ref->{damages_paid} 
			)"
            	);
            $query->execute;
            $query->finish;
        }
		
        return ( $This->last_inserted_id('claims') );
    }



####################### MINER ####################


	sub add_miner_DB {
        	my ( 	
			$This,
			$miner_ref,
	  	) = @_;

        	foreach (keys %{$miner_ref}){
		#		print "'$_' = ".$miner_ref->{$_}	 ;
				$miner_ref->{$_}	= $This->{Dbh}->quote($miner_ref->{$_});
			}
		#	die;
        	my $query    = $This->{Dbh}->prepare(
            	"SELECT miner_id 
				FROM miner	
				WHERE miner_name like $miner_ref->{miner_name} 
				and miner_date like $miner_ref->{miner_date}"
     		);
        	$query->execute;
			my $id = -1;
        	($id) = $query->fetchrow_array;
        	$query->finish;
        	if ($id) {
            	return $id;
        	} else {
            	my $query = $This->{Dbh}->prepare(
                "INSERT INTO miner
				(
					miner_name,
					miner_age,
   					miner_date,
					miner_year,
					miner_occupation,
					miner_colliery,
					miner_owner,
					miner_town,
					miner_county,
					miner_notes			
				) 
			values(
				$miner_ref->{miner_name},
				$miner_ref->{miner_age},
   				$miner_ref->{miner_date},
				$miner_ref->{miner_year},
				$miner_ref->{miner_occupation},
				$miner_ref->{miner_colliery},
				$miner_ref->{miner_owner},
				$miner_ref->{miner_town},
				$miner_ref->{miner_county},
				$miner_ref->{miner_notes}		
			)");
            	
            	$query->execute;
            	$query->finish;
        }
		
        return ( $This->last_inserted_id('miner') );
    }

		
	sub get_dbms_miner_ids {

		my ( 	
			$This,
			$miner_id_ref
		  ) = @_;

        	my $query    = $This->{Dbh}->prepare(
            	"SELECT miner_id FROM miner"
     		);
        	$query->execute;
        	while( 
				my ($id ) = $query->fetchrow_array){
				push(@{$miner_id_ref},$id );

			}
        	$query->finish;

	}


	sub get_miner_DB {
        	my ( 	
			$This,
			$miner_ref,
	  	) = @_;

        	foreach (keys %{$miner_ref}){
		#		print "'$_' = ".$miner_ref->{$_}	 ;
				$miner_ref->{$_}	= $This->{Dbh}->quote($miner_ref->{$_});
			}
		#	die;
        	my $query    = $This->{Dbh}->prepare(
            	"SELECT miner_name,
					miner_age,
   					miner_date,
					miner_year,
					miner_occupation,
					miner_colliery,
					miner_owner,
					miner_town,
					miner_county,
					miner_notes	 
				FROM miner	
				WHERE miner_id = $miner_ref->{id}"
     		);
        	$query->execute;
        	my ($tmp_miner_ref) = $query->fetchrow_hashref;
		foreach(keys %{$tmp_miner_ref}){
		$miner_ref->{$_} = $tmp_miner_ref->{$_};
		}
        	$query->finish;
        	
		
    }

#Name: 	SMITH Richard
#Age: 	
#Date: 	27/03/1830
#Year: 	1830
#Occupation: 	
#Colliery: 	
#Owner: 	
#Town: 	Tipton
#County: 	Stafford
#Notes: 	Explosion of sulphorous air.


####################### END MINER ##############################
	sub add_student_DB {
        	my ( 	
			$This,
			$student_name,
			$student_age,
			$student_town,
	  	) = @_;

        	my $qstudent_name = $This->{Dbh}->quote($student_name);
		my $qstudent_town = $This->{Dbh}->quote($student_town);

        	my $query    = $This->{Dbh}->prepare(
            	"SELECT student_id FROM student	WHERE student_name=$qstudent_name "
     		);
        	$query->execute;
		my $student_id = -1;
        	($student_id) = $query->fetchrow_array;
        	$query->finish;
        	if ($student_id) {
            		return $student_id;
        	} else {
            		my $query = $This->{Dbh}->prepare(
                	"INSERT INTO student
			(
				student_name, 
				student_age,
				student_town
			) 
			values(
				$qstudent_name,
				$student_age,
				$qstudent_town
			)"
            	);
            	$query->execute;
            	$query->finish;
        }
		
        return ( $student_id );
    }

		

	}
1;

