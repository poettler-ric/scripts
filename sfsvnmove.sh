#!/bin/bash

# converts a sf cvs repository to a svn repository and uploads it

PROJECT=iris-reasoner
MODULE=iris
LOGIN=poettler_ric

CVSDIR=cvsbackup
DUMP_PRE=svndump
DUMP=$DUMP_PRE-$MODULE

rsync -avz rsync://$PROJECT.cvs.sourceforge.net/cvsroot/$PROJECT/* $CVSDIR
cvs2svn --branches=$MODULE/branches \
	--tags=$MODULE/tags \
	--trunk=$MODULE/trunk \
	--dumpfile=$DUMP \
	$CVSDIR/$MODULE
gzip $DUMP
scp $DUMP.gz $LOGIN@shell.sourceforge.net:/home/groups/${PROJECT:0:1}/${PROJECT:0:2}/$PROJECT/$DUMP.gz
