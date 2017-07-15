use strict;
use warnings;
use POE qw(Component::Server::IRC);
my @sslopt = ( '', '' );

my $confpath = $ARGV[0];
sub iniRead
 { 
  my $ini = $_[0];
  my $conf;
  my $section;
  open (INI, "$ini") || die "Can't open $ini: $!\n";
    while (<INI>) {
        chomp;
        if (/^\s*\[\s*(.+?)\s*\]\s*$/) {
            $section = $1;
        }

        if ( /^\s*([^=]+?)\s*=\s*(.*?)\s*$/ ) {
          $conf->{$section}->{$1} = $2;         
        }
    }
  close (INI);
  return $conf;
}
my @motdlines;
sub readconf {
	my $filepath = $_[0];
	my $config;
	$config = iniRead($filepath);
	if ( $config->{ssl} ) {
		@sslopt[0] = $config->{ssl}->{key};
		@sslopt[1] = $config->{ssl}->{cert};
		$config->{server}->{sslify_options} = \@sslopt;
	}
	open (MYMOTD, $config->{server}->{motd}) || return $config;
	@motdlines = ();
	while (<MYMOTD>) {
		chomp;
		push @motdlines, $_;
	}
	$config->{server}->{motd} = \@motdlines;
	close (MYMOTD);
	return %{$config};
}

my %config = readconf($confpath);
my %sconfig = %{%config->{server}};
sub setup_authoper {
        my $ircd = $_[0];
	my ($oper, $pass);
	 while ( ($oper,$pass) = each(%config->{oper}) ) {
		$pass = %config->{oper}->{$oper};
		$ircd->add_operator({username => $oper, password => $pass, ipmask => '*'});
	 }
	my ($host, $spoof);
	 while ( ($host,$spoof) = each(%config->{auth}) ) {
		$spoof = %config->{auth}->{$host};
		if ( $spoof eq '*' ) {
			$ircd->add_auth({mask => $host});
		} else {
			$ircd->add_auth({mask => $host, spoof => $spoof, no_tilde => 1});
		}
	}	
	my $port;
	 while ( ($host, $port) = each(%config->{port}) ) {
		$port = %config->{port}->{$host};
		if ( $port =~ /(.*):(.*)/ ) {
			$host = $1;
			$port = $2;
		}
		$ircd->add_listener(bindaddr => $host, port => $port);
	}
	 while ( ($host, $port) = each(%config->{sslport}) ) {
		$port = %config->{sslport}->{$host};
		if ( $port =~ /(.*):(.*)/ ) {
			$host = $1;
			$port = $2;
		}
		$ircd->add_listener(bindaddr => $host, port => $port, usessl => 1);
	}
	my ($sname, $data);
	while ( ($sname, $data) = each(%config->{peer}) ) {
		$data = %config->{peer}->{$sname};
		if ( $data =~ /(.*):(.*)/ ) {
			$ircd->add_peer(name => $sname, pass => "pass", rpass => "pass", type => "r", raddress => $1, rport => $2, auto => 1);
		}
	}
	$ircd->add_peer(name => "default", pass => "pass", rpass => "pass", type => "c");
}
#my %config = (
#	servername => 'simple.poco.server.irc', 
#	nicklen	=> 15,
#	network	=> 'SimpleNET',
#	motd => \@mymotd
#);


my $pocosi = POE::Component::Server::IRC->spawn( config => \%sconfig, sslify_options => \@sslopt );

POE::Session->create(
	 package_states => [
		 'main' => [qw(_start _default)],
	 ],
	 heap => { ircd => $pocosi },
);

$poe_kernel->run();

sub _start {
	 my ($kernel, $heap) = @_[KERNEL, HEAP];

	 $heap->{ircd}->yield('register', 'all');

	 # Anyone connecting from the loopback gets spoofed hostname
#	 $heap->{ircd}->add_auth(
#		 mask	 => '*@localhost',
#		 spoof	=> 'm33p.com',
#		 no_tilde => 1,
#	 );

	 # We have to add an auth as we have specified one above.
#	 $heap->{ircd}->add_auth(mask => '*@*');

	 # Start a listener on the 'standard' IRC port.
#	 $heap->{ircd}->add_listener(port => 6766);
	 setup_authoper($heap->{ircd});
	 # Add an operator who can connect from localhost
#	 $heap->{ircd}->add_operator(
#		 {
#			 username => 'moo',
#			 password => 'fishdont',
#		 }
#	 );
}

sub _default {
	 my ($kernel, $heap) = @_[KERNEL, HEAP];
	 my ($event, $args) = @_[ARG0 .. $#_];

	 print "$event: ";
	 for my $arg (@$args) {
		 if (ref($arg) eq 'ARRAY') {
			 print "[", join ( ", ", @$arg ), "] ";
		 }
		 elsif (ref($arg) eq 'HASH') {
			 print "{", join ( ", ", %$arg ), "} ";
		 }
		 else {
			 print "'$arg' ";
		 }
	 }

	 print "\n";
	if ( $event eq "ircd_daemon_rehash" ) {
		%config = readconf($confpath);
		setup_authoper($heap->{ircd});
	}
 }
