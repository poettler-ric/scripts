#!/bin/sh

# copies files from a svn tag to the trunk directory and creates the appropiate commits

TAG=function_symbols_merged
FROM=https://iris-reasoner.svn.sourceforge.net/svnroot/iris-reasoner/iris/tags/$TAG/
TO=https://iris-reasoner.svn.sourceforge.net/svnroot/iris-reasoner/iris/trunk/

FILES=( \
	test/org/deri/iris/evaluation_old/common/ExtractRelevantRulesTest.java \
	)

MESSAGE="copied from tag $TAG"
MESSAGE_DIRS="creating the directory for"

function createParent() {
	local parent=`dirname $1`
	svn ls $parent 2>/dev/null >&2
	if [ $? -eq 1 ]
	then
		# check the parent's parent
		createParent $parent $2
		# create the parent
		svn mkdir -m "$MESSAGE_DIRS ${2:-$parent}" $parent >/dev/null
	fi
}

for i in ${FILES[@]}
do
	# check the parent directories
	echo checking parents for $i
	createParent $TO$i $i
	# copy the file
	echo copying $i
	svn cp -m "$i $MESSAGE" $FROM$i $TO$i >/dev/null
done
