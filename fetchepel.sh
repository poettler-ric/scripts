#!/bin/sh

RC_FILE="$HOME/.fetchepelrc"
CACHE_FILE="$HOME/.fetchepeldb"

PACKAGES="ansible dkms libdnet libyaml open-vm-tools python-httplib2 python-keyczar PyYAML"

VERSION="6"
ARCH="x86_64"
EPEL_BASE_URL="http://dl.fedoraproject.org/pub/epel/${VERSION}/${ARCH}/repoview"

OUTPUT_DIRECTORY="."

if [ -r "$RC_FILE" ]
then
    . "$RC_FILE"
fi

for p in $PACKAGES
do
    CHECK_URL="${EPEL_BASE_URL}/${p}.html"
    CONTENT=$(curl -s "$CHECK_URL")
    SHA=$(echo "$CONTENT" | sha256sum)

    # get cached checksum
    OLD_SHA=$(grep "$p" "$CACHE_FILE" | cut -d ' ' -f 1 --complement)

    # compare checksum
    if [ "$SHA" != "$OLD_SHA" ]
    then
	# fetch the rpms
	for r in $(echo "$CONTENT" | grep -Eo '[0-9a-zA-Z_./-]+\.rpm')
	do
	    RPM_URL="$(dirname $CHECK_URL)/${r}"
	    echo "fetching $(basename $RPM_URL)"
	    cd "$OUTPUT_DIRECTORY"
	    curl -sO "$RPM_URL"
	done

	# store new checksum
	if [ -w "$CACHE_FILE" ]
	then
	    sed -i "/${p}/d" "$CACHE_FILE"
	fi
	echo "${p} $SHA" >>"$CACHE_FILE"
    fi
done

