#!/bin/sh
#Deleting a parent branch between grandparent and child rendering child to be branched with grandparent
legit.pl init
echo hello>a
legit.pl add a
legit.pl commit -m "first commit"
legit.pl branch
legit.pl branch bchild
legit.pl checkout
legit.pl checkout bchild
echo world>b
legit.pl add b
legit.pl commit -m "second parent commit"
legit.pl branch bGrandChild
legit.pl checkout bGrandChild
legit.pl checkout master
legit.pl branch -d bParent
legit.pl rm a
legit.pl rm a



