#!/bin/sh
#Working cases for Subset 0 and 1, working on a aggressive remove + checking if file deletes from index if no longer present in working directory
#using -a -m 
legit.pl init
echo hello >a
echo world >b
echo old >c
legit.pl add a b
legit.pl commit -m "first-commit"
echo new >d
echo new_file >e
legit.pl rm d
legit.pl rm e
legit add d e
legit.pl status
echo new >>a
legit.pl rm a
legit.pl rm --cached b 
legit.pl rm b
legit.pl status
echo newline >d
legit.pl commit -a -m "second-commit"
legit.pl status
rm d
legit.pl commit -m "third-commit"
legit.pl log
legit.pl status