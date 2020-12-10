#!/bin/sh
#User creates a file, commits it deletes it and then changes to different branch and checks the status and deletes the branch, branch should show errors
legit.pl init
echo hello>a
legit.pl add a
legit.pl commit -m "first commit"
legit.pl rm a 
rm a
legit.pl branch newChild
legit.pl commit -m "second removing commit"
legit.pl status
legit.pl checkout master
legit.pl branch -d newChild
legit.pl merge newChild -m "merging"
legit.pl branch -d newChild


