#
#  backends/Rtf.py
#
#  $Id: Rtf.py,v 1.2 2000/08/03 12:38:57 cdegroot Exp $
#
#  SGMLtools RTF backend driver.
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

class Rtf(Backend):

    def postJade(self, outfile, stdoutfile):
	#
	#  Jade wrote RTF, send it to its final destination
	#
	destfile = os.path.join(self._fileparts[1], self._fileparts[0] + '.rtf')
        self._tracer.mv(outfile, destfile)


class RtfGlobals(BackendGlobals):

    def getName(self):
	return 'rtf'

    def getJadeSettings(self):
	return ('sgmltools-rtf', 'rtf')

