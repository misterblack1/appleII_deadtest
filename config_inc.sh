#!/bin/sh

if (git --version > /dev/null 2>&1); then
	VERSION=`git describe --tags --always --dirty=-LOCAL --broken=-X | tr a-z A-Z`
else
	VERSION="LOCAL_BUILD"
fi

echo ".define VERSION_STR \"$VERSION\""
