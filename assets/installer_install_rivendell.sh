#!/bin/sh

# installer_install_rivendell.sh
#
# Install Rivendell 4.x on an RHEL 8 system
#

#
# Site Defines
#
REPO_HOSTNAME="software.paravelsystems.com"
USER_NAME="rd"

#
# Get Target Mode
#
if test $1 ; then
    case "$1" in
	--client)
	    MODE="client"
	    ;;

	--server)
	    MODE="server"
	    IP_ADDR=$2
	    ;;

	--standalone)
	    MODE="standalone"
	    ;;

	*)
	    echo "USAGE: ./install_rivendell.sh --client|--server|--standalone"
	    exit 256
            ;;
    esac
else
    MODE="standalone"
fi

#
# Configure Repos
#
dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
wget https://$REPO_HOSTNAME/rhel/8com/Paravel-Commercial.repo -P /etc/yum.repos.d/

#
# Install Dependencies
#
dnf -y install patch evince telnet lwmon nc samba paravelview ntpstat emacs twolame-libs libmad nfs-utils cifs-utils samba-client net-tools alsa-utils cups tigervnc-server-minimal pygtk2 cups gedit ntfs-3g ntfsprogs autofs

if test $MODE = "server" ; then
    #
    # Install MariaDB
    #
    dnf -y install mariadb-server
    systemctl start mariadb
    systemctl enable mariadb
    mkdir -p /etc/systemd/system/mariadb.service.d/
    cp /usr/share/rhel-rivendell-installer/limits.conf /etc/systemd/system/mariadb.service.d/
    systemctl daemon-reload

    #
    # Enable DB Access for localhost
    #
    echo "CREATE DATABASE Rivendell;" | mysql -u root
    echo "CREATE USER 'rduser'@'localhost' IDENTIFIED BY 'letmein';" | mysql -u root
    echo "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,INDEX,ALTER,CREATE TEMPORARY TABLES,LOCK TABLES ON Rivendell.* TO 'rduser'@'localhost';" | mysql -u root

    #
    # Enable DB Access for all remote hosts
    #
    echo "CREATE USER 'rduser'@'%' IDENTIFIED BY 'letmein';" | mysql -u root
    echo "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,INDEX,ALTER,CREATE TEMPORARY TABLES,LOCK TABLES ON Rivendell.* TO 'rduser'@'%';" | mysql -u root

    #
    # Enable NFS Access for all remote hosts
    #
    echo "/var/snd *(rw,no_root_squash)" >> /etc/exports
    echo "/home/$USER_NAME/rd_xfer *(rw,no_root_squash)" >> /etc/exports
    echo "/home/$USER_NAME/music_export *(rw,no_root_squash)" >> /etc/exports
    echo "/home/$USER_NAME/music_import *(rw,no_root_squash)" >> /etc/exports
    echo "/home/$USER_NAME/traffic_export *(rw,no_root_squash)" >> /etc/exports
    echo "/home/$USER_NAME/traffic_import *(rw,no_root_squash)" >> /etc/exports
    systemctl enable rpcbind
    systemctl enable nfs-server

    #
    # Enable CIFS File Sharing
    #
    systemctl enable smb
    systemctl enable nmb
fi

if test $MODE = "standalone" ; then
    #
    # Install MariaDB
    #
    dnf -y install mariadb-server
    systemctl start mariadb
    systemctl enable mariadb
    mkdir -p /etc/systemd/system/mariadb.service.d/
    cp /usr/share/rhel-rivendell-installer/limits.conf /etc/systemd/system/mariadb.service.d/
    systemctl daemon-reload

    #
    # Enable DB Access for localhost
    #
    echo "CREATE DATABASE Rivendell;" | mysql -u root
    echo "CREATE USER 'rduser'@'localhost' IDENTIFIED BY 'letmein';" | mysql -u root
    echo "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,INDEX,ALTER,CREATE TEMPORARY TABLES,LOCK TABLES ON Rivendell.* TO 'rduser'@'localhost';" | mysql -u root

    #
    # Enable CIFS File Sharing
    #
    systemctl enable smb
    systemctl enable nmb
fi

#
# Install Rivendell
#
patch -p0 /etc/rsyslog.conf /usr/share/rhel-rivendell-installer/rsyslog.conf.patch
mv /etc/selinux/config /etc/selinux/config-original
cp -f /usr/share/rhel-rivendell-installer/selinux.config /etc/selinux/config
systemctl disable firewalld
rm -f /etc/asound.conf
cp /usr/share/rhel-rivendell-installer/asihpi.conf /etc/modprobe.d/
cp /usr/share/rhel-rivendell-installer/asound.conf /etc/
cp /usr/share/rhel-rivendell-installer/Reyware.repo /etc/yum.repos.d/
cp /usr/share/rhel-rivendell-installer/RPM-GPG-KEY-Reyware /etc/pki/rpm-gpg/
mkdir -p /usr/share/pixmaps/rivendell
cp /usr/share/rhel-rivendell-installer/rdairplay_skin.png /usr/share/pixmaps/rivendell/
cp /usr/share/rhel-rivendell-installer/rdpanel_skin.png /usr/share/pixmaps/rivendell/
mv /etc/samba/smb.conf /etc/samba/smb-original.conf
cp /usr/share/rhel-rivendell-installer/smb.conf /etc/samba/
cp /usr/share/rhel-rivendell-installer/no_screen_blank.conf /etc/X11/xorg.conf.d/
mkdir -p /etc/skel/Desktop
cp /usr/share/rhel-rivendell-installer/skel/paravel_support.pdf /etc/skel/Desktop/First\ Steps.pdf
ln -s /usr/share/rivendell/opsguide.pdf /etc/skel/Desktop/Operations\ Guide.pdf
# FIXME: Add to existing accounts too!

#tar -C /etc/skel -zxf /usr/share/rhel-rivendell-installer/xfce-config.tgz
#adduser -c Rivendell\ Audio --groups audio,wheel $USER_NAME
#chown -R $USER_NAME:$USER_NAME /home/$USER_NAME
#chmod 0755 /home/$USER_NAME
#patch /etc/gdm/custom.conf /usr/share/rhel-rivendell-installer/autologin.patch
dnf -y install lame-libs rivendell rivendell-opsguide

if test $MODE = "server" ; then
    #
    # Initialize Automounter
    #
    cp /etc/auto.misc /etc/auto.misc-original
    cp -f /usr/share/rhel-rivendell-installer/auto.misc.template /etc/auto.misc
    systemctl enable autofs

    #
    # Create Rivendell Database
    #
    rddbmgr --create --generate-audio
    echo "update STATIONS set REPORT_EDITOR_PATH=\"/usr/bin/gedit\"" | mysql -u rduser -pletmein Rivendell

    #
    # Create common directories
    #
    mkdir -p /home/$USER_NAME/rd_xfer
    chown $USER_NAME:$USER_NAME /home/$USER_NAME/rd_xfer

    mkdir -p /home/$USER_NAME/music_export
    chown $USER_NAME:$USER_NAME /home/$USER_NAME/music_export

    mkdir -p /home/$USER_NAME/music_import
    chown $USER_NAME:$USER_NAME /home/$USER_NAME/music_import

    mkdir -p /home/$USER_NAME/traffic_export
    chown $USER_NAME:$USER_NAME /home/$USER_NAME/traffic_export

    mkdir -p /home/$USER_NAME/traffic_import
    chown $USER_NAME:$USER_NAME /home/$USER_NAME/traffic_import
fi

if test $MODE = "standalone" ; then
    #
    # Initialize Automounter
    #
    cp -f /usr/share/rhel-rivendell-installer/auto.misc.template /etc/auto.misc
    systemctl enable autofs

    #
    # Create Rivendell Database
    #
    rddbmgr --create --generate-audio
    echo "update STATIONS set REPORT_EDITOR_PATH=\"/usr/bin/gedit\"" | mysql -u rduser -pletmein Rivendell

    #
    # Create common directories
    #
    mkdir -p /home/$USER_NAME/rd_xfer
    chown $USER_NAME:$USER_NAME /home/$USER_NAME/rd_xfer

    mkdir -p /home/$USER_NAME/music_export
    chown $USER_NAME:$USER_NAME /home/$USER_NAME/music_export

    mkdir -p /home/$USER_NAME/music_import
    chown $USER_NAME:$USER_NAME /home/$USER_NAME/music_import

    mkdir -p /home/$USER_NAME/traffic_export
    chown $USER_NAME:$USER_NAME /home/$USER_NAME/traffic_export

    mkdir -p /home/$USER_NAME/traffic_import
    chown $USER_NAME:$USER_NAME /home/$USER_NAME/traffic_import
fi

if test $MODE = "client" ; then
    #
    # Initialize Automounter
    #
    rm -f /etc/auto.rd.audiostore
    cat /usr/share/rhel-rivendell-installer/auto.rd.audiostore.template | sed s/@IP_ADDRESS@/$IP_ADDR/g > /etc/auto.rd.audiostore

    rm -f /home/$USER_NAME/rd_xfer
    ln -s /misc/rd_xfer /home/$USER_NAME/rd_xfer
    rm -f /home/$USER_NAME/music_export
    ln -s /misc/music_export /home/$USER_NAME/music_export
    rm -f /home/$USER_NAME/music_import
    ln -s /misc/music_import /home/$USER_NAME/music_import
    rm -f /home/$USER_NAME/traffic_export
    ln -s /misc/traffic_export /home/$USER_NAME/traffic_export
    rm -f /home/$USER_NAME/traffic_import
    ln -s /misc/traffic_import /home/$USER_NAME/traffic_import
    rm -f /etc/auto.misc
    cat /usr/share/rhel-rivendell-installer/auto.misc.client_template | sed s/@IP_ADDRESS@/$IP_ADDR/g > /etc/auto.misc
    systemctl enable autofs

    #
    # Configure Rivendell
    #
    cat /etc/rd.conf | sed s/localhost/$IP_ADDR/g > /etc/rd-temp.conf
    rm -f /etc/rd.conf
    mv /etc/rd-temp.conf /etc/rd.conf
fi

#
# Finish Up
#
echo
echo "Installation of Rivendell is complete.  Reboot now."
echo
echo "IMPORTANT: Be sure to see the FINAL DETAILS section in the instructions"
echo "           to ensure that your new Rivendell system is properly secured."
echo
