# dpkg-watch.pl - A real time view of dpkg statuses

This is a utitly that monitors in realtime packages as thay are added and removed from the system.

![Photo](https://raw.githubusercontent.com/finbar-crago/dpkg-watch/add-img/screen.png)

+ Information is displayed to the user in browser as fixed width text fetched via ajax.
+ A web socket notifies the browser when changes have occurred.
+ JQuery is used for ajax requests and `Mojolicious::Lite` is used server side for http/ws handling.
+ On launch the script forks a process to monitor `/var/log/dpkg.log` .
+ IPC using pipes and signals.

## Usage:
```
$ vagrant up
$ x-www-browser http://localhost:3000/
$ vagrant ssh
vagrant@jessie:~$ sudo apt-get install emacs24-nox
vagrant@jessie:~$ sudo apt-get remove emacs24-nox
vagrant@jessie:~$ sudo apt-get autoremove
```

### A Lazy Alternative...
```perl
use IO::All; $,="\r\n";
$s=io(":3001")->fork->accept;
$_='<html><body><meta http-equiv="refresh" content="5"><pre>'
    .io->pipe('tail -n150 /var/log/dpkg.log|grep " status "|sort -r')->all;
$s->print('HTTP/1.1 200 OK', 'Content-Length:'.length,'',$_);
```
