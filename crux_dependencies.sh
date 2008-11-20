#!/bin/sh

# creates a graph out of crux repositories to be represented with graphviz

REPO_DIR=/usr/ports

function header {
echo 'digraph dependencies {'
echo '    label="CRUX port dependencies";'
echo '    ranksep=2;'
echo '    ratio=auto;'
echo '    node [fontsize=8];'
}

function footer {
echo '}'
}

function makeCluster {
	if [ $# -ne 1 ]
	then
		echo "makeCluster: number of arguments must be 1!" >&2
		exit 1
	fi

	echo "    subgraph cluster_$1 {"
	echo "        label="$1";"

	# adding the color
	if [ $1 == "core" ]
	then
		echo '        color="red"'
	elif [ $1 == "opt" ]
	then
		echo '        color="blue"'
	elif [ $1 == "contrib" ]
	then
		echo '        color="green"'
	elif [ $1 == "xorg" ]
	then
		echo '        color="yellow"'
	fi

	# adding the nodes
	for port in `ls $REPO_DIR/$1`
	do
		echo "        `normalizePortName $port`;"
	done

	echo '    }'
}

function makeEdges {
	if [ $# -ne 1 ]
	then
		echo "makeEdges: number of arguments must be 1!" >&2
		exit 1
	fi

	for port in $REPO_DIR/$1/*
	do
		for dep in `sed -n -e '/^[ 	]*#[ 	]*Depends/{ 
			s|,| |g 
			s|^[^:]*:|| 
			p 
		}' $port/Pkgfile`
		do
			echo "    `normalizePortName $dep` -> `basename \`normalizePortName $port\``;"
		done
	done
}

function normalizePortName {
	if [ $# -ne 1 ]
	then
		echo "normalizePortName: number of arguments must be 1!" >&2
		exit 1
	fi

	echo -n $1 | sed -e 's|[+-]|_|g'
}

header
# make the clusters
for repo in $@
do
	makeCluster $repo
done
# list the edges
for repo in $@
do
	makeEdges $repo
done
footer
