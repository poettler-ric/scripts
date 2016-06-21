#!/bin/sh

# syncronizes fedora and rpmfusion repositories
#
# following variables are taken from  ~/.sync.fedora.sh
#
# BASEARCH ... architectures to sync
# CLEANUP ... if set to "1" then old development directories will be deleted
#
# FEDORA_RELEASES ... fedora releases to sync e.g. "1 2"
# FEDORA_LOCAL ... local root directory for fedora repositories
# FEDORA_MIRROR ... remote root directory for fedora repositories
#
# RPMFUSION_DEVELOPMENT ... rpmfusion development releases to sync e.g. "1 2"
# RPMFUSION_RELEASES ... rpmfusion releases to sync e.g. "1 2"
# RPMFUSION_LOCAL ... local root directory for rpmfusion repositories
# RPMFUSION_MIRROR ... remote root directory for rpmfusion repositories
#
# BW_LIMIT ... bandwidth limit passed to rsync


sync_repo() {
    REPO_URL="$1"
    LOCAL_FOLDER="$2"

    mkdir -p "$LOCAL_FOLDER"

    rsync -vaH --numeric-ids --delete --delete-delay --delay-updates \
        --progress --human-readable \
        --exclude '**/debug' \
        --exclude '**/repoview' \
        $BW_LIMIT_ARGS \
        "$REPO_URL" "$LOCAL_FOLDER"
}


readonly RC_FILE=~/.sync.fedora.sh

if [ -f "$RC_FILE" ]
then
    . "$RC_FILE"
fi

if [ -n "$BW_LIMIT" ]
then
    readonly BW_LIMIT_ARGS=" --bwlimit=$BW_LIMIT "
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

for RELEASE_VER in $RPMFUSION_DEVELOPMENT
do
    sync_repo \
        "rsync://$RPMFUSION_MIRROR/free/fedora/development/$RELEASE_VER/$BASEARCH/os/" \
        "$RPMFUSION_LOCAL/free/fedora/development/$RELEASE_VER/$BASEARCH/os/"
    sync_repo \
        "rsync://$RPMFUSION_MIRROR/free/fedora/updates/testing/$RELEASE_VER/$BASEARCH/" \
        "$RPMFUSION_LOCAL/free/fedora/updates/testing/$RELEASE_VER/$BASEARCH/"

    sync_repo \
        "rsync://$RPMFUSION_MIRROR/nonfree/fedora/development/$RELEASE_VER/$BASEARCH/os/" \
        "$RPMFUSION_LOCAL/nonfree/fedora/development/$RELEASE_VER/$BASEARCH/os/"
    sync_repo \
        "rsync://$RPMFUSION_MIRROR/nonfree/fedora/updates/testing/$RELEASE_VER/$BASEARCH/" \
        "$RPMFUSION_LOCAL/nonfree/fedora/updates/testing/$RELEASE_VER/$BASEARCH/"
done

for RELEASE_VER in $RPMFUSION_RELEASES
do
    if [ "$CLEANUP" == "1" ]
    then
        rm -rf "$RPMFUSION_LOCAL/free/fedora/development/$RELEASE_VER"
    fi
    sync_repo \
        "rsync://$RPMFUSION_MIRROR/free/fedora/releases/$RELEASE_VER/Everything/$BASEARCH/os/" \
        "$RPMFUSION_LOCAL/free/fedora/releases/$RELEASE_VER/Everything/$BASEARCH/os/"
    sync_repo \
        "rsync://$RPMFUSION_MIRROR/free/fedora/updates/$RELEASE_VER/$BASEARCH/" \
        "$RPMFUSION_LOCAL/free/fedora/updates/$RELEASE_VER/$BASEARCH/"
    sync_repo \
        "rsync://$RPMFUSION_MIRROR/free/fedora/updates/testing/$RELEASE_VER/$BASEARCH/" \
        "$RPMFUSION_LOCAL/free/fedora/updates/testing/$RELEASE_VER/$BASEARCH/"

    if [ "$CLEANUP" == "1" ]
    then
        rm -rf "$RPMFUSION_LOCAL/nonfree/fedora/development/$RELEASE_VER"
    fi
    sync_repo \
        "rsync://$RPMFUSION_MIRROR/nonfree/fedora/releases/$RELEASE_VER/Everything/$BASEARCH/os/" \
        "$RPMFUSION_LOCAL/nonfree/fedora/releases/$RELEASE_VER/Everything/$BASEARCH/os/"
    sync_repo \
        "rsync://$RPMFUSION_MIRROR/nonfree/fedora/updates/$RELEASE_VER/$BASEARCH/" \
        "$RPMFUSION_LOCAL/nonfree/fedora/updates/$RELEASE_VER/$BASEARCH/"
    sync_repo \
        "rsync://$RPMFUSION_MIRROR/nonfree/fedora/updates/testing/$RELEASE_VER/$BASEARCH/" \
        "$RPMFUSION_LOCAL/nonfree/fedora/updates/testing/$RELEASE_VER/$BASEARCH/"
done
