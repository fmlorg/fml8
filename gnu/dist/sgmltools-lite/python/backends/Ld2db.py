#
#  backends/Ld2db.py
#
#  $Id: Ld2db.py,v 1.2 2000/08/03 12:38:57 cdegroot Exp $
#
#  SGMLtools LinuxDoc conversion backend driver.
#
#  SGMLtools - an SGML toolkit.
#  Copyright (C) 1998 Cees A. de Groot
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

from Backend import Backend, BackendGlobals
import os, string

class Ld2db(Backend):

    def preJade(self, fh):
	#
	#  We need to patch up the SGML_CATALOG_FILES so that
	#  just the elements we need are in there. Otherwise, we
	#  have trouble with finding the wrong SGML declaration.
	#
	pathelems = string.split(os.environ["SGML_CATALOG_FILES"], ':')
	newcatfiles = []
	for i in pathelems:
	    if string.find(i, 'dtd/sgmltools') != -1:
		newcatfiles.append(i)
	    elif string.find(i, 'stylesheets/sgmltools') != -1:
		newcatfiles.append(i)
	    elif string.find(i, 'dtd/jade') != -1:
		newcatfiles.append(i)
	    elif string.find(i, 'entities/iso-entities-8879.1986') != -1:
		newcatfiles.append(i)

	os.environ["SGML_CATALOG_FILES"] = string.join(newcatfiles, ':')
	self._tracer.trace('SGML_CATALOG_FILES=' + 
			   os.environ["SGML_CATALOG_FILES"])

	return fh

    def postJade(self, outfile, stdoutfile):
	#
	#  Write generated DVI file to destination if we're the final
	#  backend. Note that Jade spits stuff to stdoutfile in this
	#  case.
	#
	destfile = os.path.join(self._fileparts[1], 
			self._fileparts[0] + '.db-sgml')
        self._tracer.mv(stdoutfile, destfile)


class Ld2dbGlobals(BackendGlobals):

    def getName(self):
	return 'ld2db'

    def getJadeSettings(self):
	return ('sgmltools-db', 'sgml')
