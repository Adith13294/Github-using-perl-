#!/bin/sh
# making child and grandchild and deleting child
legit.pl init 
echo hello >a
legit.pl add a
legit.pl commit -m "First commit"
legit.pl branch b1
legit.pl checkout b1
touch b 
legit.pl add b
legit.pl commit -m "second commit"
legit.pl branch b2
legit.pl checkout b2
touch c 
legit.pl add c
legit.pl merge b1 -m "third commit"
legit.pl checkout master
legit.pl branch -d b1