#!/bin/sh

perl -i.bak -nple 's/\s*$//' ` find lib/ -type f | egrep '\.pm$' `

