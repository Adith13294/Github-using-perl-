#!/bin/sh
#performing delete operations in a branched file
legit.pl init
echo hello>a
legit.pl add a
legit.pl commit -m "first commit"
legit.pl branch b1
legit.pl checkout b1
touch b c d e f 
add b c d
legit.pl commit -m "second commit"
echo hello >a
rm b
legit.pl rm --force --force --cached c
legit.pl status
legit.pl show :c
legit.pl show :e
legit.pl rm e
legit.pl status
legit.pl checkout master
legit.pl branch -d b1
legit.pl merge b1 -m "first merge" 
legit.pl rm a
legit.pl branch b2
legit.pl merge b2 -m "second merge" 
