#!/usr/bin/env perl
use Mojolicious::Lite;
my $tbl={}; my $subs={};

my $parent = $$;
my $daemon = open(my $dpkg, '-|');
die "fork(): $!" unless defined $daemon;
logMon() if !$daemon;
$SIG{USR1}='parseRow';

sub logMon {
    $\="\n";$,="\n";
    my $run=1; my $wait=0;
    $SIG{TERM}=sub{$run=0};
    $SIG{USR2}=sub{$wait=0};

    open my $log, '<', '/var/log/dpkg.log' or die $!;
    while($run){
	seek($log, 0, 1);
	my @buf=();
	while(<$log>){
	    chomp;
	    my @r = split/ /;
	    next unless $#r == 5 && $r[2] eq 'status';
	    push @buf, join '|', @r;
	    last if $#buf > 100;
	} if (@buf) {
	    print $#buf+1, @buf;
	    kill 'SIGUSR1', $parent;
	    $wait=1;
	} else { $wait=0 }
	select(undef, undef, undef, 0.05)while($wait);
	select(undef, undef, undef, 0.05);
    }
    close $log;
}

sub parseRow {
    $SIG{USR1}='IGNORE';
    my $i = 0+<$dpkg>;
    while($i--){
	my @r = split/[|\n]/,<$dpkg>;
	$tbl->{$r[4]} = {
	    pkgname=> $r[4],
	    status => $r[3],
	    version=> $r[5],
	    updated=> $r[0].' '.$r[1]
	}
    }
    $subs->{$_}->send('!') for keys %{$subs};
    $SIG{USR1}='parseRow';
    kill 'SIGUSR2', $daemon;
}


#
# --- HTTP STUFF ---
#
get '/data.json' => sub {
    my @list = map  {$tbl->{$_}}
               sort {$tbl->{$b}->{'updated'} cmp $tbl->{$a}->{'updated'}} keys %{$tbl};

    shift->render(json => [ @list[0 .. ($#list>99?99:$#list) ] ]);
};

websocket '/sub' => sub {
    my $self = shift;
    $self->inactivity_timeout(300);
    $subs->{sprintf"%s",$self->tx}=$self->tx;
    $self->tx->send('!');
    $self->on(message => sub { $self->tx->send('~'); });
    $self->on(finish => sub { delete $subs->{sprintf"%s",$self->tx}});
};

get '/' => sub { shift->render(template => 'index') };
app->start('daemon', '-l', 'http://*:3000');

__DATA__
@@ index.html.ep
<html><head>
<title>dpkg monitor</title>
<style>
.installed     {color: green  }
.not-installed {color: red    }
.config-files  {color: orange }
.head { font-weight: bold; }
</style>
<script type="text/javascript" src="http://code.jquery.com/jquery-latest.min.js"></script>
<script type="text/javascript">
function puts(txt,len,atr){
  txt=txt.substring(0,len);
  return '  |  <a '+atr+'>'+txt+'</a>' + " ".repeat(Math.max(len-txt.length,0))}

function fetch(){
  $.ajax('/data.json',{
    success: function(data){
      $("#view").empty();
      $("#view").append(
             puts('STATUS',      15, 'class="head"')+
             puts('PACKAGE NAME',35, 'class="head"')+
             puts('VERSION',     20, 'class="head"')+
             puts('UPDATED',     19, 'class="head"')+"  |\n");

      $.each(data,function(idx,r){
        $("#view").append(
               puts(r.status,  15, 'class="'+r.status+'"')+
               puts(r.pkgname, 35)+
               puts(r.version.replace(/[><]/g,'-'), 20)+
               puts(r.updated, 19)+"  |\n");
      });
    }
  });
}

$(document).ready($(function(){
  var ws = new WebSocket('ws://'+window.location.host+'/sub');
  ws.onerr = function(){ window.location.reload(false) };
  ws.onclose = function(){ window.location.reload(false) };
  ws.onmessage = function(msg){ if(msg.data == "!"){ fetch() }};
  window.setInterval(function(){ws.send('~')}, 1500);
}));
</script></head><body><pre id="view" /></body></html>
