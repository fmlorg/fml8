#!/bin/sh

sudo rm -f /usr/local/libexec/fml/fmlwrapper ; 
sudo sh INSTALL.sh ; 
cat example |\
perl -w /usr/local/libexec/fml/fml.pl /var/spool/ml/elena

exit 0

