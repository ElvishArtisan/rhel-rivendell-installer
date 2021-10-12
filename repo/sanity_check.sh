#!/bin/sh

. /etc/os-release

if test $ID != "rhel" ; then
    echo "unsupported distro \"$PRETTY_NAME\" detected"
    exit 1
fi
if test $VERSION_ID != "8.4" ; then
    echo "unsupported RHEL version \"$VERSION_ID\" detected"
    exit 1
fi

exit 0
