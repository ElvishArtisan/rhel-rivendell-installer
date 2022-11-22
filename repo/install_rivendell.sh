#!/bin/bash

# install_rivendell.sh
#
# User-facing installation script for Rivendell
#
#   (C) Copyright 2021-2022 Fred Gleason <fredg@paravelsystems.com>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as
#   published by the Free Software Foundation; either version 2 of
#   the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

function Continue {
  read -a RESP -p "Continue (y/N) "
  echo
  if [ -z $RESP ] ; then
    exit 0
  fi
  if [ $RESP != "y" -a $RESP != "Y" ] ; then
    exit 0
  fi
}


function CheckNetwork {
    ping -c 2 software.paravelsystems.com > /dev/null 2> /dev/null
    if [ $? != 0 ] ; then
	echo "Unable to access the public Internet, exiting."
	exit 1
    fi
}


function AddRepos {
    echo "Adding repo..."
    wget https://software.paravelsystems.com/rhel/9rd4/RPM-GPG-KEY-Paravel-Broadcast -P /etc/pki/rpm-gpg/
    wget https://software.paravelsystems.com/rhel/9rd4/Paravel-Rivendell4.repo -P /etc/yum.repos.d/
    dnf -y clean expire-cache
    dnf -y install rhel-rivendell-installer
}


function InstallStandalone {
    CheckNetwork
    AddRepos
    /usr/share/rhel-rivendell-installer/installer_install_rivendell.sh --standalone
#    dnf -y remove rhel-rivendell-installer
    exit 0
}


function InstallServer {
    CheckNetwork
    AddRepos
    /usr/share/rhel-rivendell-installer/installer_install_rivendell.sh --server
#    dnf -y remove rhel-rivendell-installer
    exit 0
}


function InstallClient {
    echo -n "Enter IP address of Rivendell server: "
    read RD_SERVER
    CheckNetwork
    AddRepos
    /usr/share/rhel-rivendell-installer/installer_install_rivendell.sh --client $RD_SERVER
#    dnf -y remove rhel-rivendell-installer
    exit 0
}

#
# Print welcome message and menu
#
echo "Welcome to the Rivendell installer!"
echo
echo "This installer downloads the Rivendell Radio Automation System from"
echo "the Internet and installs it on this system."
echo
echo "Three different styles of setup for Rivendell are available:"
echo
echo " 1) Standalone. All system components (Rivendell code, database server"
echo "    and audio store) will be installed on this system, allowing it to"
echo "    function as a self-contained, autonomous Rivendell system."
echo
echo " 2) Server. Same as Standalone, but in addition, configure the database"
echo "    and audio store to be shared with other Rivendell systems over the"
echo "    network."
echo
echo " 3) Client. Install just the Rivendell components, configuring it to"
echo "    use the database and audio store on a shared server."
echo
echo " 4) Do nothing, and exit this installer."
echo
read -a RESP -p " Your choice [4]? "
echo

if [ -z $RESP ] || [ $RESP == "4" ] ; then
    exit 0
fi

if [ $RESP == "1" ] ; then
    InstallStandalone
fi
if [ $RESP == "2" ] ; then
    InstallServer
fi
if [ $RESP == "3" ] ; then
    InstallClient
fi

echo "Unrecognized choice: $RESP"
exit 1
