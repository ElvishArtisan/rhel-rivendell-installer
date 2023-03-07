#!/bin/sh

# installer_install_rivendell.sh
#
# Install Rivendell 4.x on a CentOS 7 system
#

#
# Site Defines
#
REPO_HOSTNAME="software.paravelsystems.com"

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
	    MODE="client"
	    MYSQL_HOSTNAME=$2
	    MYSQL_LOGINNAME=$3
	    MYSQL_PASSWORD=$4
	    MYSQL_DATABASE=$5
	    NFS_HOSTNAME=$6
	    NFS_MOUNT_SOURCE=$NFS_HOSTNAME:/var/snd
	    NFS_MOUNT_TYPE="nfs"
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
yum -y install epel-release
wget http://$REPO_HOSTNAME/CentOS/7com/Paravel-Commercial.repo -P /etc/yum.repos.d/

#
# Install XFCE4
#
yum -y groupinstall "X window system"
yum -y groupinstall xfce
systemctl set-default graphical.target

#
# Install Dependencies
#
yum -y install patch evince telnet lwmon nc samba paravelview ntp emacs twolame libmad nfs-utils cifs-utils samba-client ssvnc xfce4-screenshooter net-tools alsa-utils cups tigervnc-server-minimal pygtk2 cups system-config-printer gedit ntfs-3g ntfsprogs autofs

if test $MODE = "server" ; then
    #
    # Install MariaDB
    #
    yum -y install mariadb-server
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
    echo "/home/rd/rd_xfer *(rw,no_root_squash)" >> /etc/exports
    echo "/home/rd/music_export *(rw,no_root_squash)" >> /etc/exports
    echo "/home/rd/music_import *(rw,no_root_squash)" >> /etc/exports
    echo "/home/rd/traffic_export *(rw,no_root_squash)" >> /etc/exports
    echo "/home/rd/traffic_import *(rw,no_root_squash)" >> /etc/exports
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
    yum -y install mariadb-server
    systemctl start mariadb
    systemctl enable mariadb
    mkdir -p /etc/systemd/system/mariadb.service.d/
    cp /usr/share/rhel-rivendell-installer/limits.conf /etc/systemd/system/mariadb.service.d/
    systemctl daemon-reload

    #
    # Create Empty Database
    #
    echo "CREATE DATABASE Rivendell;" | mysql -u root
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
cp -f /usr/share/rhel-rivendell-installer/selinux.config /etc/selinux/config
systemctl disable firewalld
yum -y remove chrony openbox
systemctl start ntpd
systemctl enable ntpd
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
tar -C /etc/skel -zxf /usr/share/rhel-rivendell-installer/xfce-config.tgz
adduser -c Rivendell\ Audio --groups audio,wheel rd
chown -R rd:rd /home/rd
chmod 0755 /home/rd
patch /etc/gdm/custom.conf /usr/share/rhel-rivendell-installer/autologin.patch
yum -y remove alsa-firmware alsa-firmware-tools
yum -y install lame rivendell

GenerateDefaultRivendellConfiguration

if test $MODE = "server" ; then
    #
    # Initialize Automounter
    #
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
    mkdir -p /home/rd/rd_xfer
    chown rd:rd /home/rd/rd_xfer

    mkdir -p /home/rd/music_export
    chown rd:rd /home/rd/music_export

    mkdir -p /home/rd/music_import
    chown rd:rd /home/rd/music_import

    mkdir -p /home/rd/traffic_export
    chown rd:rd /home/rd/traffic_export

    mkdir -p /home/rd/traffic_import
    chown rd:rd /home/rd/traffic_import
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
    echo update\ \`STATIONS\`\ set\ \`REPORT_EDITOR_PATH\`=\'/usr/bin/gedit\' | mysql -u $MYSQL_LOGINNAME -p$MYSQL_PASSWORD $MYSQL_DATABASE

    #
    # Create common directories
    #
    mkdir -p /home/rd/rd_xfer
    chown rd:rd /home/rd/rd_xfer

    mkdir -p /home/rd/music_export
    chown rd:rd /home/rd/music_export

    mkdir -p /home/rd/music_import
    chown rd:rd /home/rd/music_import

    mkdir -p /home/rd/traffic_export
    chown rd:rd /home/rd/traffic_export

    mkdir -p /home/rd/traffic_import
    chown rd:rd /home/rd/traffic_import
fi

if test $MODE = "client" ; then
    #
    # Initialize Automounter
    #
    rm -f /etc/auto.rd.audiostore
    cat /usr/share/rhel-rivendell-installer/auto.rd.audiostore.template | sed s/@IP_ADDRESS@/$NFS_HOSTNAME/g > /etc/auto.rd.audiostore

    rm -f /home/rd/rd_xfer
    ln -s /misc/rd_xfer /home/rd/rd_xfer
    rm -f /home/rd/music_export
    ln -s /misc/music_export /home/rd/music_export
    rm -f /home/rd/music_import
    ln -s /misc/music_import /home/rd/music_import
    rm -f /home/rd/traffic_export
    ln -s /misc/traffic_export /home/rd/traffic_export
    rm -f /home/rd/traffic_import
    ln -s /misc/traffic_import /home/rd/traffic_import
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
