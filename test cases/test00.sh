#!/bin/sh
# Test for boundary/edge cases for add and init
legit.pl init 250
legit.pl init
echo hello >%a
echo world >*b
legit.pl add %a *b
echo hello >a
legit.pl add a
legit.pl add b
legit.pl commit -m "first commit"
