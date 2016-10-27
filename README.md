# dpkg-watch.pl - A real time view of dpkg statuses

This is a utitly that monitors in realtime packages as thay are added and removed from the system.

![Photo](https://lh3.googleusercontent.com/sugCwKvGgVJyD1t8ZzUnfjC7SX4T5PrY0gpc5A7BSY32adkA1Qy7qmjSVqJ9CesL-Jo9Rvph5cExSHWoPWJKvfUXMcf6Y9F3xvFRTZELPhg5dW737hfCOfSEST-nkoNrOTs8T3aJzCsZqeDPNyTgOsmVGUwVEjxrRSbidRvKOdYlbTXeLVu66dwRft1qjKr-1aewx4DwZXE0oSE1z448MQXh_pPXuFCESC02MPrO7dM0r_ZKUJuMMFPc2nUzDz1NsCBZlxDJ56Rzsf7eZOKOqaPv6uFzorq9B8aoA4nWohGFc3N70mxRYy_LH_k3Dq-E4D3Tbt_T_gk5jk8HWndBrOVxuvYaApT4j5AVTA2yCoAgmuOxmOXUEtk0ejrqg-2QE_BzRmfunXutevPcDlK2p7601fLakXlnq0KPgStGsc-fe3gQW2ZrgV5NK7t9KVdxdg2B2WZTvrKVK2L-1pAoNifYUXJOHMdGuZv8wVDAasdPJNyxJSBIx8SHouOavX7PQv7GdmUQXNQzKg_Vm1XQ-hoUAqR_3Z0Amq6_40gzKz3MmfQ8DaHdPm-H3ZMsF6pA7MyD8r6tYluIy11RqorpGZqgigQMT7fmSdAkDkoEm67DBTNh=w944-h683-no)

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
