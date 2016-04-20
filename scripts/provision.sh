#!/bin/bash

## fixing vagrant / ansible bug , more info here:
## https://github.com/geerlingguy/drupal-vm/issues/372
## https://github.com/mitchellh/vagrant/issues/6793
##

# add all necessary packages
pkg_install() {
  echo 'Installing package dependencies'
  if [ ! -f /etc/yum.repos.d/epel.repo ]; then
    rpm -Uvh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-6.noarch.rpm
  fi
  yum -y install python-pip python-devel && sudo pip install ansible==1.9.2
  yum clean all
  yum makecache
}

# check bootstrap status
if [ ! -f /etc/bootstrap_done ]; then
  echo 'Running bootstrap'
  pkg_install
  touch /etc/bootstrap_done
else
  echo 'Skipping bootstrap steps -- already done ...'
fi
