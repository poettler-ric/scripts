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


sync_repo() {
    REPO_URL="$1"
    LOCAL_FOLDER="$2"

    mkdir -p "$LOCAL_FOLDER"

    rsync -vaH --numeric-ids --delete --delete-delay --delay-updates \
        --progress --human-readable \
        --exclude '**/debug' \
        "$REPO_URL" "$LOCAL_FOLDER"
}


readonly RC_FILE=~/.sync.fedora.sh

if [ -f "$RC_FILE" ]
then
    . "$RC_FILE"
fi

for RELEASE_VER in $FEDORA_RELEASES
do
    sync_repo \
        "rsync://$FEDORA_MIRROR/releases/$RELEASE_VER/Everything/$BASEARCH/os/" \
        "$FEDORA_LOCAL/releases/$RELEASE_VER/Everything/$BASEARCH/os/"
    sync_repo \
        "rsync://$FEDORA_MIRROR/updates/$RELEASE_VER/$BASEARCH/" \
        "$FEDORA_LOCAL/updates/$RELEASE_VER/$BASEARCH/"
done
