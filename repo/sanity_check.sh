#!/bin/sh

. /etc/os-release

if test $ID != "rocky" ; then
    echo "unsupported distro \"$PRETTY_NAME\" detected"
    exit 1
fi
VER=`echo $VERSION_ID | tr -cd 8`
if test $VER -eq 88 ; then
    $VER=8
fi
if test $VER != "8" ; then
    echo "unsupported RHEL version \"$VERSION_ID\" detected"
    exit 1
fi

exit 0
