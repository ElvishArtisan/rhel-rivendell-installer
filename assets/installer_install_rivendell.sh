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

# USAGE: AddDbUser <dbname> <hostname> <username> <password>
function AddDbUser {
    echo "CREATE USER '${3}'@'${2}' IDENTIFIED BY '${4}';" | mysql -u root
    echo "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,INDEX,ALTER,CREATE TEMPORARY TABLES,LOCK TABLES ON ${1}.* TO '${3}'@'${2}';" | mysql -u root
}

function GenerateDefaultRivendellConfiguration {
    mkdir -p /etc/rivendell.d
    cat /usr/share/rhel-rivendell-installer/rd.conf-sample | sed s/%MYSQL_HOSTNAME%/$MYSQL_HOSTNAME/g | sed s/%MYSQL_LOGINNAME%/$MYSQL_LOGINNAME/g | sed s/%MYSQL_PASSWORD%/$MYSQL_PASSWORD/g | sed s^%NFS_MOUNT_SOURCE%^$NFS_MOUNT_SOURCE^g | sed s/%NFS_MOUNT_TYPE%/$NFS_MOUNT_TYPE/g > /etc/rivendell.d/rd-default.conf
    ln -s -f /etc/rivendell.d/rd-default.conf /etc/rd.conf
}

#
# Get Target Mode
#
if test $1 ; then
    case "$1" in
	--client)
            MYSQL_HOSTNAME=$2
            MYSQL_LOGINNAME=$3
            MYSQL_PASSWORD=$4
            MYSQL_DATABASE=$5
            NFS_HOSTNAME=$6
            NFS_MOUNT_SOURCE=$NFS_HOSTNAME:/var/snd
            NFS_MOUNT_TYPE="nfs"
	    MODE="client"
	    ;;

	--server)
	    MODE="server"
            MYSQL_HOSTNAME="localhost"
            MYSQL_LOGINNAME="rduser"
            MYSQL_PASSWORD=`tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1`
            MYSQL_DATABASE="Rivendell"
            NFS_HOSTNAME=""
            NFS_MOUNT_SOURCE=""
            NFS_MOUNT_TYPE=""
	    ;;

	--standalone)
	    MODE="standalone"
            MYSQL_HOSTNAME="localhost"
            MYSQL_LOGINNAME="rduser"
            MYSQL_PASSWORD=`tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1`
            MYSQL_DATABASE="Rivendell"
            NFS_HOSTNAME=""
            NFS_MOUNT_SOURCE=""
            NFS_MOUNT_TYPE=""
	    ;;

	*)
	    echo "invalid invocation!"
	    exit 256
            ;;
    esac
else
    MODE="standalone"
fi

#
# Dump Input Values
#
echo -n "MODE: " >> /root/rivendell_install_log.txt
echo $MODE >> /root/rivendell_install_log.txt

echo -n "MYSQL_HOSTNAME: " >> /root/rivendell_install_log.txt
echo $MYSQL_HOSTNAME >> /root/rivendell_install_log.txt

echo -n "MYSQL_LOGINNAME: " >> /root/rivendell_install_log.txt
echo $MYSQL_LOGINNAME >> /root/rivendell_install_log.txt

echo -n "MYSQL_PASSWORD: " >> /root/rivendell_install_log.txt
echo $MYSQL_PASSWORD >> /root/rivendell_install_log.txt

echo -n "MYSQL_DATABASE: " >> /root/rivendell_install_log.txt
echo $MYSQL_DATABASE >> /root/rivendell_install_log.txt

echo -n "NFS_HOSTNAME: " >> /root/rivendell_install_log.txt
echo $NFS_HOSTNAME >> /root/rivendell_install_log.txt

echo -n "NFS_MOUNT_SOURCE: " >> /root/rivendell_install_log.txt
echo $NFS_MOUNT_SOURCE >> /root/rivendell_install_log.txt

echo -n "NFS_MOUNT_TYPE: " >> /root/rivendell_install_log.txt
echo $NFS_MOUNT_TYPE >> /root/rivendell_install_log.txt

#
# Configure Repos
#
dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
/usr/bin/crb enable
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
    cp /usr/share/rhel-rivendell-installer/rivendell.cnf /etc/my.cnf.d/
    systemctl start mariadb
    systemctl enable mariadb

    #
    # Create Empty Database
    #
    echo "CREATE DATABASE $MYSQL_DATABASE;" | mysql -u root
    AddDbUser $MYSQL_DATABASE "localhost" $MYSQL_LOGINNAME $MYSQL_PASSWORD
    AddDbUser $MYSQL_DATABASE "%" $MYSQL_LOGINNAME $MYSQL_PASSWORD
    
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
    cp /usr/share/rhel-rivendell-installer/rivendell.cnf /etc/my.cnf.d/
    systemctl start mariadb
    systemctl enable mariadb

    #
    # Create Empty Database
    #
    echo "CREATE DATABASE $MYSQL_DATABASE;" | mysql -u root
    AddDbUser $MYSQL_DATABASE "localhost" $MYSQL_LOGINNAME $MYSQL_PASSWORD

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
cp /usr/share/rhel-rivendell-installer/asound.conf /etc/
cp /usr/share/rhel-rivendell-installer/Reyware.repo /etc/yum.repos.d/
cp /usr/share/rhel-rivendell-installer/RPM-GPG-KEY-Reyware /etc/pki/rpm-gpg/
mkdir -p /usr/share/pixmaps/rivendell
mv /etc/samba/smb.conf /etc/samba/smb-original.conf
cp /usr/share/rhel-rivendell-installer/smb.conf /etc/samba/
cp /usr/share/rhel-rivendell-installer/no_screen_blank.conf /etc/X11/xorg.conf.d/
mkdir -p /etc/skel/Desktop
cp /usr/share/rhel-rivendell-installer/skel/paravel_support.pdf /etc/skel/Desktop/First\ Steps.pdf
ln -s /usr/share/rivendell/opsguide.pdf /etc/skel/Desktop/Operations\ Guide.pdf
patch /etc/gdm/custom.conf /usr/share/rhel-rivendell-installer/autologin.patch
# FIXME: Add to existing accounts too!

#tar -C /etc/skel -zxf /usr/share/rhel-rivendell-installer/xfce-config.tgz
#adduser -c Rivendell\ Audio --groups audio,wheel $USER_NAME
#chown -R $USER_NAME:$USER_NAME /home/$USER_NAME
#chmod 0755 /home/$USER_NAME
#patch /etc/gdm/custom.conf /usr/share/rhel-rivendell-installer/autologin.patch
dnf -y install lame-libs rivendell

GenerateDefaultRivendellConfiguration

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
    echo update\ \`STATIONS\`\ set\ \`REPORT_EDITOR_PATH\`=\'/usr/bin/gedit\' | mysql -u $MYSQL_LOGINNAME -p$MYSQL_PASSWORD $MYSQL_DATABASE

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
    echo "update `STATIONS` set `REPORT_EDITOR_PATH`='/usr/bin/gedit'" | mysql -u $MYSQL_LOGINNAME -p$MYSQL_PASSWORD $MYSQL_DATABASE

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
    cat /usr/share/rhel-rivendell-installer/auto.rd.audiostore.template | sed s/@IP_ADDRESS@/$NFS_HOSTNAME/g > /etc/auto.rd.audiostore

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
    cat /usr/share/rhel-rivendell-installer/auto.misc.client_template | sed s/@IP_ADDRESS@/$NFS_HOSTNAME/g > /etc/auto.misc
    systemctl enable autofs
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
