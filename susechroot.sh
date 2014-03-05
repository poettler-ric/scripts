#!/bin/sh

# script to create chroot environments on suse

RC_FILE=~/.susechrootrc

BIND_MOUNTS="/dev /proc /var/cache/zypp/packages /usr/src/packages/SOURCES $CCACHE_DIR"
REPOSITORIES="repo-oss repo-non-oss repo-update repo-update-non-oss"
#BASE_PACKAGES="zypper"
BASE_PACKAGES=""
DEV_PACKAGES="rpm-build"
#COPY_FILES="/etc/resolv.conf"
COPY_FILES=""
COMPILERS="cc gcc c++ g++"
TMPFS="0"
TMPFS_SIZE="6g"

# TODO: copy users / groups?
# TODO: implement commands "count-files", "diff-files"

if [ -r "$RC_FILE" ]
then
	. "$RC_FILE"
fi

bind_mount() {
	check_chroot

	for i in $BIND_MOUNTS
	do
		if [ -d "$i" ]
		then
			mkdir -p "${ROOT}${i}"
			mount -B "$i" "${ROOT}${i}"
		fi
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
	if [ -d "$ROOT" ]
	then
		echo "chroot directory '$ROOT' already exits"
		exit 2
	fi

	mkdir -p "$ROOT"

	if [ "$TMPFS" -ne 0 ]
	then
		if [ -n "$TMPFS_SIZE" ]
		then
			SIZE_STATEMENT=" -o size=$TMPFS_SIZE "
		fi
		mount -t tmpfs $SIZE_STATEMENT none "$ROOT"
	fi

	bind_mount

	for i in $REPOSITORIES
	do
		zypper --root "$ROOT" ar -kf "/etc/zypp/repos.d/${i}.repo"
	done

	zypper --root "$ROOT" --gpg-auto-import-keys refresh

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

destroy_chroot() {
	check_chroot

	bind_umount

	if [ "$TMPFS" -ne 0 ]
	then
		umount "$ROOT"
	fi

	rm -r "$ROOT"
}

prepare_spec() {
	if [ -z "$1" ]
	then
		echo "no .spec file given"
		exit 1
	fi
	if [ ! -f "$1" ]
	then
		echo "$1 isn't file"
		exit 1
	fi

	check_chroot

	bind_mount

	sed -e 's/#.*//' "$1" \
		| sed -e 's/buildrequires/buildrequires/I' \
		| sed -ne '/buildrequires/p' \
		| sed -re 's/buildrequires:(.*)/\1/' \
		| xargs zypper --root "$ROOT" in

	bind_umount
}

install_package() {
	if [ -z "$1" ]
	then
		echo "no package file given"
		exit 1
	fi

	check_chroot

	bind_mount

	zypper --root "$ROOT" in $1

	bind_umount
}

link_ccache() {
	# similar funktionality like ccache in debian
	# prepend your PATH with /usr/lib/ccache to use the links

	check_chroot

	mkdir -p "$ROOT/usr/lib/ccache"

	install_package ccache

	for i in $COMPILERS
	do
		if [ -x "$ROOT/usr/bin/$i" -a ! -e "$ROOT/usr/lib/ccache/$i" ]
		then
			ln -rs "$ROOT/usr/bin/ccache" "$ROOT/usr/lib/ccache/$i"
		fi
	done
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
	- destroy
	- bind
	- unbind
	- prepare-spec <spec-file>
	- install <package>
	- ccache
eof
	exit 1
fi

ROOT=$(readlink -f "$2")

case $1 in
create)
	create_chroot
	;;
destroy)
	destroy_chroot
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
install)
	install_package "$3"
	;;
ccache)
	link_ccache
	;;
*)
	echo "no command '$1' defined"
	exit 2
	;;
esac

