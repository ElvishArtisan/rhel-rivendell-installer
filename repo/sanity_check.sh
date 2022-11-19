#!/bin/sh

. /etc/os-release

if test $ID != "rocky" ; then
    echo "unsupported distro \"$PRETTY_NAME\" detected"
    exit 1
fi
VER=`echo $VERSION_ID | tr -cd 9`
if test $VER -eq 99 ; then
    $VER=9
fi
if test $VER != "9" ; then
    echo "unsupported RHEL version \"$VERSION_ID\" detected"
    exit 1
fi

exit 0
