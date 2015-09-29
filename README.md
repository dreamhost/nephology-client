# Nephology
noun \[nɪˈfɒlədʒɪ\]

1. The branch of meteorology that deals with clouds.
2. A system for building and deploying clouds.

Nephology is a flexible bare-metal provisioning system. It is designed to take newly racked hardware from an unknown state all the way through hardware configuration and finally booting an operating system with an (optional) configuration management client installed.  The idea is to take new hardware provisioning time down from hours to minutes.

Unlike other systems, Nepholoy does not dictate which OS or configuration management tools you need to install.  You can even use Nephology to perform initial hardware configuration tasks, verify physical requirements, and then pass off to a third-party netboot installer (like XenServer or WDS).

## Requirements

The Nephology client needs to run on a host capable of running a Perl script. The following Perl modules are required:
* LWP
* Getopt::Long (ubuntu package:libmojo-perl)
* JSON (ubuntu package: libjson-perl)
* Try::Tiny
* File::Temp
* Data::Dumper

## Status

This project is under active development, and currently in use at DreamHost for deployment of our systems.  We will be releasing the project with a BSD license in the near future.  If you would like to help, please contact me.  There is a wiki page which will help you get started with hacking on the code.
=======
