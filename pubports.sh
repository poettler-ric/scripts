#!/bin/sh

TMPDIR="/tmp/ports"

SRC="/home/richi/workspace/crux/namenlos-ports"
REMDIR="public_html/ports"
HOST="sti2.at"
REPO="namenlos"
TITLE="$REPO' CRUX ports"
PWD_OLD=$PWD

FULLNAME="Richard Pöttler"
PUBURL="http://www.sti2.at/~richardp/ports"

HEADER=".header"
FOOTER=".footer"

if [ -d $TMPDIR ]
then
	echo "$TMPDIR already exists!"
	exit 1
fi

# cloning the repository
git-clone $SRC $TMPDIR

cd $TMPDIR

# creating the REPO file
httpup-repgen

# creating the ports page
if [ -f $HEADER ]
then
	PORTSPAGE_ARGS="$PORTSPAGE_ARGS --header=$HEADER"
fi

if [ -f $FOOTER ]
then
	PORTSPAGE_ARGS="$PORTSPAGE_ARGS --footer=$FOOTER"
fi

portspage --title="$TITLE" $PORTSPAGE_ARGS . > index.html

# creating the httpup file
cat << eof > $REPO.httpup
#
# /etc/ports/$REPO.httpup: $FULLNAME's port collection
#

ROOT_DIR=/usr/ports/$REPO
URL=$PUBURL

# End of file
eof

# copying the files to the server
rsync -e ssh -avz --delete --delete-excluded \
	--exclude "*.git" --exclude "$HEADER" --exclude "$FOOTER"  \
	. $HOST:$REMDIR

cd $PWD_OLD
rm -rf $TMPDIR
