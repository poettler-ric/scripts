#!/bin/sh

# following variables are possible to set in  ~/.sync.fedora.sh
#
# BASEARCH ... architectures to sync
#
# FEDORA_RELEASES ... fedora releases to sync e.g. "1 2"
# FEDORA_LOCAL ... local root directory for fedora repositories
# FEDORA_MIRROR ... remote root directory for fedora repositories
#
# RPMFUSION_RELEASES ... rpmfusion releases to sync e.g. "1 2"
# RPMFUSION_LOCAL ... local root directory for rpmfusion repositories
# RPMFUSION_MIRROR ... remote root directory for rpmfusion repositories


readonly RC_FILE=~/.sync.fedora.sh

if [ -f "$RC_FILE" ]
then
    . "$RC_FILE"
fi

for RELEASE_VER in $FEDORA_RELEASES
do
    RELEASE_URL="rsync://$FEDORA_MIRROR/releases/$RELEASE_VER/Everything/$BASEARCH/os/"
    RELEASE_DIR="${FEDORA_LOCAL}/releases/$RELEASE_VER/Everything/$BASEARCH/os/"

    UPDATE_URL="rsync://$FEDORA_MIRROR/updates/$RELEASE_VER/$BASEARCH/"
    UPDATE_DIR="${FEDORA_LOCAL}/updates/$RELEASE_VER/$BASEARCH/"

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
