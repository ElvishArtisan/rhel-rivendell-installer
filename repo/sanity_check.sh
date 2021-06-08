#!/bin/sh

. /etc/os-release

if test $ID != "centos" ; then
    echo "unsupported distro \"$PRETTY_NAME\" detected"
    exit 1
fi
if test $VERSION_ID != "7" ; then
    echo "unsupported CentOS version \"$VERSION_ID\" detected"
    exit 1
fi

exit 0
