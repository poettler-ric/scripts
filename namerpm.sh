#!/bin/sh

# script to hormalize rpm filenames

if [ "$#" -lt 1 ]
then
	echo "usage: $0 <package>"
	exit 1
fi

cp "$1" $(rpm -q --qf "%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm" -p $1 2>/dev/null)
