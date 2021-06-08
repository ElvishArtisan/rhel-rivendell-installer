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
             rhel7-addnewmountpoint.png\
             rhel7-addnewmountpointefi.png\
             rhel7-bootscreen.png\
             rhel7-installationcomplete.png\
             rhel7-installationdestination.png\
             rhel7-installationsummary.png\
             rhel7-installationsummarydone.png\
             rhel7-installing-set-root-password.png\
             rhel7-manualpartitioning.png\
             rhel7-manualpartitioning_standard.png\
             rhel7-minimal-mode.png\
             rhel7-nmtui-edit-menu.png\
             rhel7-nmtui-editconnection-menu.png\
             rhel7-installer_menu.png\
             rhel7-nmtui-invocation.png\
             rhel7-nmtui-mainscreen.png\
             rhel7-root-login.png\
             rhel7-setlanguage.png\
             rhel7-set-root-password.png

CLEANFILES = *~
MAINTAINERCLEANFILES = *~\
                       *.1\
                       *.8\
                       *.html\
                       *.pdf\
                       aclocal.m4\
                       configure\
                       Makefile.in
