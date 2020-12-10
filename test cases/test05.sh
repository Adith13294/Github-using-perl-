#!/bin/sh
#Boundary cases for if legit exists or not and also if commit exists before proceeding. Basic case but important check
legit.pl add
legit.pl commit
legit.pl show
legit.pl log
legit.pl rm a
legit.pl status
legit.pl branch
legit.pl checkout b1
legit.pl merge b1 -m hello-mergelegit.pl init
legit.pl init
legit.pl show
legit.pl log
legit.pl rm a
legit.pl status
legit.pl branch
legit.pl checkout b1
legit.pl merge b1 -m hello-merge

