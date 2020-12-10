#!/bin/sh
# boundary cases for show and remove
legit.pl init
echo hello >a
legit.pl add a
legit.pl commit -m "first commit"
legit.pl show :
legit.pl show 0:
legit.pl show :a
legit.pl show 1:a
legit.pl show 0:a
legit.pl show 0:b
legit.pl show 100:
legit.pl rm a
legit.pl rm a

