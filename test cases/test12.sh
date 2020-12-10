#!/bin/sh
# making errors in child branch and merging it in parent
legit.pl init 
echo hello >a
legit.pl add a
legit.pl commit -m "First commit"
legit.pl branch b1
legit.pl checkout b1
touch b c d e f g
legit.pl add b c d
legit.pl commit -m "second commit"
echo new world >>b
legit.pl rm --force a b c d e f g 
legit.pl rm --force a b c d
rm e f g
legit.pl checkout master
legit.pl merge b1 -m "third commit"