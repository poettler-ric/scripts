#!/bin/sh

# script to create build chroot on suse

BIND_MOUNTS="/dev /proc /var/cache/zypp/packages /usr/src/packages/SOURCES"
REPOSITORIES="repo-oss repo-non-oss repo-update repo-update-non-oss"
#BASE_PACKAGES="zypper"
BASE_PACKAGES=""
#DEV_PACKAGES="rpm-build"
DEV_PACKAGES=""
#COPY_FILES="/etc/resolv.conf"
COPY_FILES=""

# TODO: copy users / groups?
# TODO: ccache
# TODO: implement commands "count-files", "diff-files"

bind_mount() {
	check_chroot

	for i in $BIND_MOUNTS
	do
		mkdir -p "${ROOT}${i}"
		mount -B "$i" "${ROOT}${i}"
	done
}

bind_umount() {
	check_chroot

	for i in $BIND_MOUNTS
	do
		umount "${ROOT}${i}"
	done
}

create_chroot() {
	mkdir -p "$ROOT"

	bind_mount

	for i in $REPOSITORIES
	do
		zypper --root "$ROOT" ar -kf "/etc/zypp/repos.d/${i}.repo"
	done

	zypper --root "$ROOT" refresh

	if [ -n "$BASE_PACKAGES" -o -n "$DEV_PACKAGES" ]
	then
		zypper --root "$ROOT" in $BASE_PACKAGES $DEV_PACKAGES
	fi

	for i in $COPY_FILES
	do
		mkdir -p $(dirname "${ROOT}${i}")
		cp $i "${ROOT}${i}"
	done

	bind_umount
}

prepare_spec() {
	check_chroot

	bind_mount

	if [ $# -lt 1 ]
	then
		echo "no .spec file given"
		exit 1
	fi
	if [ ! -f "$1" ]
	then
		echo "$1 isn't file"
		exit 1
	fi

	sed -e 's/#.*//' "$1" \
		| sed -e 's/buildrequires/buildrequires/I' \
		| sed -ne '/buildrequires/p' \
		| sed -re 's/buildrequires:(.*)/\1/' \
		| xargs zypper --root "$ROOT" in

	bind_umount
}

check_chroot() {
	if [ ! -d "$ROOT" ]
	then
		echo "chroot directory '$ROOT' doesn't exits"
		exit 2
	fi
}

if [ $# -lt 2 ]
then
	cat <<eof
usage: $0 <command> <chroot>
commands are:
	- create
	- bind
	- unbind
	- prepare-spec
eof
	exit 1
fi

ROOT=$(readlink -f "$2")

case $1 in
create)
	create_chroot
	;;
bind)
	bind_mount
	;;
unbind)
	bind_umount
	;;
prepare-spec)
	prepare_spec "$3"
	;;
*)
	echo "no command '$1' defined"
	exit 2
	;;
esac

