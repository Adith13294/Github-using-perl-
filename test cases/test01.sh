#!/bin/sh
# boundary cases for commit and log
legit.pl init
echo hello >a
legit.pl add a
legit.pl commit
legit.pl commit -m
legit.pl commit -a -m
legit.pl commit commit-1
legit.pl commit -m commit-1
legit.pl log 8
legit.pl log
echo world >>a
echo world >b
legit.pl commit commit-2
legit.pl add b
legit.pl commit commit-2
legit.pl log
legit.pl