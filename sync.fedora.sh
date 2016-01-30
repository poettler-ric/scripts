#!/bin/sh

# define RELEASES, BASEARCH, LOCAL_ROOT and MIRROR_ROOT in ~/.sync.fedora.sh

readonly RC_FILE=~/.sync.fedora.sh

if [ -f "$RC_FILE" ]
then
    . "$RC_FILE"
fi

for RELEASE_VER in $RELEASES
do
    RELEASE_URL="rsync://$MIRROR_ROOT/releases/$RELEASE_VER/Everything/$BASEARCH/os/"
    RELEASE_DIR="${LOCAL_ROOT}/releases/$RELEASE_VER/Everything/$BASEARCH/os/"

    UPDATE_URL="rsync://$MIRROR_ROOT/updates/$RELEASE_VER/$BASEARCH/"
    UPDATE_DIR="${LOCAL_ROOT}/updates/$RELEASE_VER/$BASEARCH/"

    mkdir -p "$RELEASE_DIR"
    mkdir -p "$UPDATE_DIR"

    rsync -vaH --numeric-ids --delete --delete-delay --delay-updates \
        --progress --human-readable \
        "$RELEASE_URL" "$RELEASE_DIR"
    rsync -vaH --numeric-ids --delete --delete-delay --delay-updates \
        --exclude '**/debug' \
        --progress --human-readable \
        "$UPDATE_URL" "$UPDATE_DIR"
done
