#!/usr/bin/env perl
use Mojolicious::Lite;
my $tbl={};

my $parent = $$;
my $daemon = open(my $dpkg, '-|');
die "fork(): $!" unless defined $daemon;
logMon() if !$daemon;
$SIG{USR1}='parseRow';


get '/' => sub { shift->render(json => $tbl) };

app->start('daemon', '-l', 'http://*:3000');




sub logMon {
    $\="\n";$,="\n";
    my $run=1; my $wait=0;
    $SIG{TERM}=sub{$run=0};
    $SIG{USR2}=sub{$wait=0};

    # LIVE: /var/log/dpkg.log
    open my $log, '<', 'test.log' or die $!;
    while($run){
	seek($log, 0, 1);
	my @buf=();
	while(<$log>){
	    chomp;
	    my @r = split/ /;
	    next unless $#r == 5 && $r[2] eq 'status';
	    push @buf, join '|', @r;
	} if (@buf) {
	    print $#buf+1, @buf;
	    kill 'SIGUSR1', $parent;
	    $wait=1;
	} else { $wait=0 }
	select(undef, undef, undef, 0.25)while($wait);
	select(undef, undef, undef, 0.25);
    }

    close $log
}


sub parseRow {
    $SIG{USR1}='IGNORE';
    my $i = 0+<$dpkg>;
    while($i--){
	my @r = split/[|\n]/,<$dpkg>;
	$tbl->{$r[4]} = {
	    status => $r[3],
	    version=> $r[5],
	    updated=> $r[0].' '.$r[1]
	}
    }
    $SIG{USR1}='parseRow';
    kill 'SIGUSR2', $daemon;
}
