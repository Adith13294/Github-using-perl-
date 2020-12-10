#!/bin/sh
# making errors in child branch and merging it in parent
legit.pl init 
echo hello >a
legit.pl add a
legit.pl commit -m "First commit"
legit.pl branch b1
legit.pl checkout b1
echo world >>a
echo world >b
legit.pl add a b
legit.pl commit -m "second commit"
legit.pl checkout master
legit.pl show :a
legit.pl merge b1 -m "third commit"
cat a
legit.pl show :a
legit.pl show 0:b
legit.pl show 1:a
legit.pl show 0:a
legit.pl merge b1 -m "fourth commit"
legit.pl rm a b
legit.pl merge b1 -m "fourth commit"
legit.pl log


