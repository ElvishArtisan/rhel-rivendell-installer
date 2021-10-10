## automake.am
##
## docs/Automake.am for rhel-rivendell-installer
##
## (C) Copyright 2016-2021 Fred Gleason <fredg@paravelsystems.com>
##
##   This program is free software; you can redistribute it and/or modify
##   it under the terms of the GNU General Public License version 2 as
##   published by the Free Software Foundation.
##
##   This program is distributed in the hope that it will be useful,
##   but WITHOUT ANY WARRANTY; without even the implied warranty of
##   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##   GNU General Public License for more details.
##
##   You should have received a copy of the GNU General Public
##   License along with this program; if not, write to the Free Software
##   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
##
## Use automake to process this into a Makefile.in

##
## Build Dependencies
##
%.html:	%.xml
	xsltproc -o $@ $(DOCBOOK_STYLESHEETS)/xhtml/docbook.xsl $<
%.pdf:	%.xml
	xsltproc $(DOCBOOK_STYLESHEETS)/fo/docbook.xsl $< | fop - -pdf $@

all-local:	index.html

EXTRA_DIST = index.html\
             index.xml\
             rhel8-addnewmountpoint.png\
             rhel8-addnewmountpointefi.png\
             rhel8-bootscreen.png\
             rhel8-createuser.png\
             rhel8-details-about.png\
             rhel8-gettingstarted.png\
             rhel8-gnomedesktop.png\
             rhel8-initialsetup.png\
             rhel8-installationcomplete.png\
             rhel8-installationdestination.png\
             rhel8-installationprogress.png\
             rhel8-installationsummary.png\
             rhel8-installationsummary1.png\
             rhel8-installationsummary2.png\
             rhel8-licenseinformation.png\
             rhel8-loginscreen.png\
             rhel8-manualpartitioning.png\
             rhel8-manualpartitioning_standard.png\
             rhel8-network.png\
             rhel8-passwordscreen.png\
             rhel8-readytogo.png\
             rhel8-setlanguage.png\
             rhel8-settings.png\
             rhel8-startterminal.png\
             rhel8-superuser.png\
             rhel8-typing.png\
             rhel8-welcome.png

CLEANFILES = *~
MAINTAINERCLEANFILES = *~\
                       *.1\
                       *.8\
                       *.html\
                       *.pdf\
                       aclocal.m4\
                       configure\
                       Makefile.in
