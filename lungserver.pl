#!/usr/bin/perl
package LungServer;
{
    	use Switch;
   	@ISA = qw(Net::Server::Fork );	
    	use strict;
	use Net::Server::Fork;    # any personality will do
	use Device::SerialPort;
 	use Time::HiRes qw(usleep);
	use constant MINER_RELAY_ON => 'a';
	use constant MINER_RELAY_OFF => 'b';
	use constant CLAIMS_RELAY_ON => 'c';
	use constant CLAIMS_RELAY_OFF => 'd';
	use constant BREATH 		=> 2500000;
	my $port = init_serial();
    
	LungServer->run( conf_file => "MServer.conf" );
    	close_port();
	exit;

    ### over-ridden subs below

sub close_port{
	$port->close || die "failed to close";
	$port = undef;


}
sub init_serial {
    my @devs = qw(/dev/ttyUSB0 /dev/ttyUSB1 /dev/ttyUSB2);
 
    $port = undef;
    for my $port_dev (@devs) {
        $port = Device::SerialPort->new($port_dev);
        last if $port;
    }
    if(!$port) {
        die "No known devices found to connect to serial: $!\n";
    }
 
    $port->databits(8);
    $port->baudrate(9600);
    $port->parity("none");
    $port->stopbits(1);
 
    return $port;
}
    # Demonstrate a Net::Server style hook
    sub allow_deny_hook {
        my $self = shift;
        my $prop = $self->{server};
        my $sock = $prop->{client};

        # only local connect
        return 1 if $prop->{peeraddr} =~ /^127\./;
        die "only local connect";
        return 0;
    }

    # Another Net::Server style hook
    sub request_denied_hook {
        print "Go away!\n";
        print STDERR "DEBUG: Client denied!\n";
    }

    sub run_dequeue {
        my $self = shift;

        # server calls this repeatedly
        $self->log( 1, "received request dequeue search" );

        #`find / -iname toot &`;

        #my $self->set_property( key1 => 'val1' );
        return;
    }


    sub process_request {
        my $self = shift;
        eval {

            while (<STDIN>) {

                $self->log( 1, "$_" );
                s/\r?\n$//;
                $_ =~ m/TYPE:(.*)\sSWITCH:(.*)/;
                my $type      = $1;
                my $pin     = $2;

                $self->log( 1,	"TYPE_1:$type SWITCH_1:$pin");
                $self->write_to_log_hook;

  		if($_ =~m/quit/){$self->server_close;}
                switch ($type) {
 		case "MINER" {
			$self->log( 1,	"$type $pin");
			$self->write_to_log_hook;
			if($pin eq 'ON'){
				$port->write(MINER_RELAY_ON);
				my $str; 
				$str = $port->lookfor();
				usleep(BREATH);
                 	#}elsif($pin eq 'OFF'){
				$port->write(MINER_RELAY_OFF);
				my $str; 
				$str = $port->lookfor();

			}
		}
                 case "CLAIMS" {
			$self->log( 1,	"$type $pin");
			$self->write_to_log_hook;
			if($pin eq 'ON'){
				$port->write(CLAIMS_RELAY_ON);
				my $str; 
				$str = $port->lookfor();
				usleep(BREATH);
                 	#}elsif($pin eq 'OFF'){
				$port->write(CLAIMS_RELAY_OFF);
				my $str; 
				$str = $port->lookfor();

			}

                 }
		# Close the server
                 case "quit"        { $self->server_close }
                 else               {
                 print "You said \"$_\"\r\n";
               #         alarm($timeout);
                    }
                }
            }
          #  alarm($previous_alarm);
        };
        warn $@ if $@;
    }
}1;

#--------------- file test.pl ---------------
