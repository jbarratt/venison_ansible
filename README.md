venison_ansible
===============

Venison Plus Apache ported to Ansible.

Supports 

* Ubuntu 14.04
* Centos 6.5

It defaults to Centos, but if you want to use Ubuntu, set the `VENISON_UBUNTU`
environment variable; for example:

`$ declare -x VENISON_UBUNTU=1`

Package builder from
https://gist.github.com/gottaloveit/6409571
