use Device::SerialPort;


reset_arduino();

sub reset_arduino {
	$port = init_serial();
	die " NO port " unless $port;
        	print (STDERR "Resetting DTR on " . $1 . "\n");
        	$port->pulse_dtr_on(100);
		sleep 1;
    	
system( "/usr/bin/avrdude /etc/avrdude.conf -p m328p -cstk500v1 -P/dev/ttyUSB0 -b57600 -D -Uflash:w:/home/cfc/Desktop/CFC/arduino-0018/relay/applet/relay.cpp.hex");
sleep 5;

}

sub init_serial {
    my @devs = qw(/dev/ttyUSB0 /dev/ttyUSB1);
 
    my $port = undef;
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
$port->debug(1); 
    return $port;
}
