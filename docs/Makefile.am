## automake.am
##
## docs/Automake.am for rhel-rivendell-installer
##
## (C) Copyright 2016-2022 Fred Gleason <fredg@paravelsystems.com>
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

post:	
	rsync -rptgoDv --copy-links --delete --exclude Makefile --exclude Makefile.in --exclude Makefile.am --exclude *.xml . software.paravelsystems.com::howtos/rhel/9rd4/

EXTRA_DIST = index.html\
             index.xml\
             rhel9-addnewmountpointefi.png\
             rhel9-addnewmountpoint.png\
             rhel9-bootscreen.png\
             rhel9-createuser.png\
             rhel9-gnomedesktop.png\
             rhel9-installationcomplete.png\
             rhel9-installationdestination.png\
             rhel9-installationprogress.png\
             rhel9-installationsummary1.png\
             rhel9-installationsummary2.png\
             rhel9-installationsummary.png\
             rhel9-installer_menu.png\
             rhel9-loginscreen.png\
             rhel9-manualpartitioning.png\
             rhel9-manualpartitioning_standard.png\
             rhel9-network.png\
             rhel9-search-settings.png\
             rhel9-sethostname.png\
             rhel9-setlanguage.png\
             rhel9-softwareselection.png\
             rhel9-superuser.png\
             rhel9-terminal-window.png\
             rhel9-welcome.png

CLEANFILES = *~
MAINTAINERCLEANFILES = *~\
                       *.1\
                       *.8\
                       *.html\
                       *.pdf\
                       aclocal.m4\
                       configure\
                       Makefile.in
