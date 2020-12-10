#!/bin/sh
# boundary cases for remove
legit.pl init
echo 123 >a
echo 123 >b
legit.pl add a b
legit.pl commit -m "first commit" 
legit.pl rm --for --cac f
legit.pl rm --force -f
legit.pl rm a --force --cache
legit.pl rm a --force --force a
legit.pl rm b --cached --force
legit.pl rm a
legit.pl rm b 
echo 456 >a
echo 456 >b
echo 789 >c
echo 910 >d
echo 100 >e 
legit.pl add a b c d 
legit.pl rm e
echo 5472 >>a
legit.pl rm a
legit.pl rm b
legit.pl rm c
legit.pl rm d
legit.pl show :a
legit.pl show :b


