#!/bin/sh

# install_rivendell_devel.sh
#
# Install the Rivendell development tools on a CentOS 7 system
#
#    Copyright (C) 2016-2021 Fred Gleason <fredg@paravelsystems.com>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of version 2 of the GNU General Public License as
#    published by the Free Software Foundation;
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, 
#    Boston, MA  02111-1307  USA
#

#
# Enable CodeReady Builder Repo
#
# subscription-manager repos --enable codeready-builder-for-rhel-8-x86_64-rpms

#
# Tag Dependencies
#
# dnf mark install apr apr-util apr-util-bdb apr-util-openssl cdparanoia-libs hpklinux httpd httpd-filesystem httpd-tools id3lib jack-audio-connection-kit libcoverart libdiscid libffado libxml++ mod_http2 python3-mysql python3-pyserial qt5-qtbase-mysql qt5-qtstyleplugins redhat-logos-httpd

#
# Install Packages
#
yum -y install \
    alsa-lib-devel \
    autoconf \
    automake \
    cdparanoia-devel \
    createrepo \
    docbook5-style-xsl \
    elfutils-libelf-devel \
    flac-devel \
    git \
    gcc-c++ \
    hpklinux-devel \
    id3lib-devel \
    jack-audio-connection-kit-devel \
    java-1.8.0-openjdk\
    kernel-devel \
    kernel-rpm-macros \
    lame-devel \
    libcoverart \
    libcoverart-devel \
    libcurl-devel \
    libdiscid-devel \
    libmad-devel \
    libmusicbrainz5-devel \
    libsamplerate-devel \
    libsndfile-devel \
    libtool \
    libvorbis-devel \
    libxslt \
    make \
    man-pages \
    openssl-devel \
    pam-devel \
    qt5-linguist \
    qt5-qtbase-devel \
    qt5-qtbase-mysql \
    rpm-build \
    rpm-sign \
    soundtouch-devel \
    twolame-devel \
    openssl-devel \
    taglib-devel

#
# Install fop(1)
#
rm -rf /usr/local/bin/fop-2.6
tar -C /usr/local/bin -zvxf /usr/share/rhel-rivendell-installer/fop-2.6-bin.tar.gz

#
# Configure Environment
#
echo "export DOCBOOK_STYLESHEETS=/usr/share/sgml/docbook/xsl-ns-stylesheets" > /etc/profile.d/docbook5.sh
echo "export PATH=\$PATH:/usr/local/bin/fop-2.6/fop" >> /etc/profile.d/docbook5.sh

#
# Finish Up
#
echo
echo "Installation of the Rivendell development tools is complete."
echo
