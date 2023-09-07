FILES="apple2.bin LICENSE.html README.html"
DELETE="README.html LICENSE.html"

abort() {
	echo "Aborting: $*"
	rm -f $DELETE
	exit -1
}

checktool() {
	if ! $* > /dev/null 2>&1 ; then
		abort "\"$1\" is required but was not found."
	fi
}

md2html() {
	B=`basename $1 .md`
	H=$B.html
	if ! pandoc $1 -f markdown -t html -s -o $H -V mainfont=sans-serif -V maxwidth=50em --metadata title="$B"
	then
		abort "Couldn't create README.html"
	fi
}

checktool git --version
checktool gh --version
checktool zip --version
checktool pandoc --version

if [ "x$1" == "x" ]; then
	echo "Usage: $0 <version>"
	exit -1
fi

TAG=$1

STATUS=`git status --porcelain`
if [ "x$STATUS" != "x" ]; then
	git status --short
	abort "Working directory contains modified files."
fi

if ! git tag -a $1 -m $1 ; then
	abort "Failed to create git tag \"$1\""
fi
if ! git push origin $1 ; then
	abort "Failed to push \"$1\" to the origin"
fi

ZIPFILE=appleII_deadtest-BIN-$TAG.zip

if ! make cleanall all ; then
	abort "Couldn't create \"$ZIPFILE\""
fi

md2html README.md
md2html LICENSE.md

if ! zip $ZIPFILE $FILES ; then
	abort "Couldn't create \"$ZIPFILE\""
fi

if ! gh release create $TAG --draft --generate-notes ; then
	abort "Couldn't create the release"
fi

if ! gh release upload $TAG $FILES $ZIPFILE ; then
	abort "Couldn't upload the release files"
fi