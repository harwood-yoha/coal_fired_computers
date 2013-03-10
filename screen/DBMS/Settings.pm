# we are going to create a myql table

# we need some special instructions to help us correct our programe  
#use strict;

package DBMS::Settings;
require Exporter;
@ISA     = qw(Exporter);

@EXPORT =
  qw (
    %MYSQL_TABLES 
   	MYSQL_PASS MYSQL_DB MYSQL_USER
 	MYSQL_PRINT_ERROR MYSQL_RAISE_ERROR
);

# USED for 'search' 'admin' on web interface:

use constant MYUSER   => 'xxxxx';
use constant MYDATABASE => 'COAL';
use constant MYPASS => 'xxxxxxx'; 

use constant {

    MYSQL_PASS        => MYPASS,
    MYSQL_DB          => 'dbi:mysql:'.MYDATABASE.';mysql_read_default_file=/etc/mysql/my.cnf',
    MYSQL_USER        => MYUSER,
    MYSQL_PRINT_ERROR => 1,
    MYSQL_RAISE_ERROR => 1,

};

# Now we will define our table
# varible types char integer

%MYSQL_TABLES = (
    country => 'create table country  (
			country_id smallint  not null AUTO_INCREMENT, 
			country_name char(150) not null,
			UNIQUE (country_name),
			index (country_id)
		) DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci',
	
	year => 'create table year  (
			year_id smallint  not null AUTO_INCREMENT, 
			year_year smallint not null,
			UNIQUE (year_year),
			index (year_id)
		) DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci',

	consumption => 'create table consumption  (
			consumption_id smallint  not null AUTO_INCREMENT, 
			consumption_value FLOAT(7,4),
			consumption_year_id smallint not NULL,
			consumption_country_id smallint not NULL,
			index (consumption_id)
		) DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci',

	production => 'create table production  (
			production_id smallint  not null AUTO_INCREMENT, 
			production_value FLOAT(7,4),
			production_year_id smallint not NULL,
			production_country_id smallint not NULL,
			index (production_id)
		) DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci',

	miner => 'create table miner  (
			miner_id smallint  not null AUTO_INCREMENT, 
			miner_name char(150) not null,
			miner_age smallint not null,
   			miner_date char(150) not null,
			miner_year smallint not null,
			miner_occupation char(150),
			miner_colliery char(150),
			miner_owner char(150),
			miner_town char(150),
			miner_county char(150),
			miner_notes	blob,
			index (miner_id)
		) DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci',

   accident => 'create table accident  (
			accident_id smallint  not null AUTO_INCREMENT, 
			accident_name char(150) not null,
			UNIQUE (accident_name),
			index (accident_id)
		) DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci',
	claims => 'create table claims  (
			claims_id smallint  not null AUTO_INCREMENT, 
			claims_constituency char(150) not null,
			claims_live smallint not null,
			claims_dead smallint not null, 
			claims_total smallint not null, 
			awaiting_initial_offer smallint not null, 
			offer_made_await_response smallint not null, 
			offer_made_subsequently_challenged smallint not null, 
			settled_claims_dead smallint not null, 
			settled_claims_alive smallint not null, 
			total_settled_claims smallint not null,  
			damages_paid char(150) not null, 
			UNIQUE (claims_constituency),
			index (claims_id)
		) DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci',


);
