#!/bin/sh

find lib/ -type f -print |\
sed 's@//@/@g' |\
egrep -v 'CVS|__templa' |\
grep 'pm$'
