#!/bin/sh
# multiple branches with removal and and status check
legit.pl init 
echo hello >a
legit.pl add a
legit.pl commit -m "First commit"
legit.pl branch master
legit.pl branch b1
legit.pl checkout b1
touch b c
legit.pl add b 
legit.pl commit -m "second commit"
legit.pl branch b2
legit.pl checkout b2
legit.pl add c
touch d e
legit.pl d
legit.pl commit -m "third commit"
legit.pl checkout b1
legit.pl rm --cached b
legit.pl checkout b2
legit.pl status
legit.pl log
legit.pl checkout master
legit.pl merge -m "fourth commit" b2
legit.pl rm a
legit.pl status
legit.pl log