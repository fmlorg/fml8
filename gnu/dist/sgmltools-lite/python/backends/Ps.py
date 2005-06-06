#
#  backends/Ps.py
#
#  $Id: Ps.py,v 1.1 2000/03/24 09:16:45 cdegroot Exp $
#
#  SGMLtools PostScript backend driver.
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
import os
from Dvi import Dvi

class Ps(Dvi):

    def postJade(self, outfile, stdoutfile):
	#
	#  Call the DVI postJade routine, this leaves a DVI file we
	#  can postprocess.
	#
	Dvi.postJade(self, outfile, stdoutfile)

	(tmpdir, junk) = os.path.split(outfile)
	(dvibase, junk) = os.path.splitext(outfile)
	dvifile = os.path.join(tmpdir, dvibase + '.dvi')

	destfile = os.path.join(self._fileparts[1], 
			self._fileparts[0] + '.ps')

	#
	#  Call dvips on the DVI file.
	#
	cmdline = 'dvips -o %s %s' % (destfile, dvifile)
	self._tracer.system(cmdline)


class PsGlobals(BackendGlobals):

    def getName(self):
	return 'ps'

    def getJadeSettings(self):
	return ('sgmltools-ps', 'tex')
