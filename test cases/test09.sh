#!/bin/sh
#making different branches,commits and log status
legit.pl init
legit.pl commit -a -m "first commit"
echo hello >a
legit.pl add a 
legit.pl commit -a -m "first commit"
echo world >a
legit.pl branch b1 
legit.pl checkout b1
legit.pl add a
legit.pl commit -a -m "second commit"
touch b 
legit.pl add b
legit.pl commit -a -m "third commit"
legit.pl branch b2 
legit.pl checkout b2
legit.pl log
legit.pl checkout b1
legit.pl log
legit.pl checkout master
legit.pl log
touch c
legit.pl add c
legit.pl commit -a -m "fourth commit"
legit.pl log
legit.pl checkout b1
legit.pl log
legit.pl checkout b2
legit.pl log


