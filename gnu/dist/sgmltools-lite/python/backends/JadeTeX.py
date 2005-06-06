#
#  backends/JadeTeX.py
#
#  $Id: JadeTeX.py,v 1.3 2000/08/03 12:38:57 cdegroot Exp $
#
#  SGMLtools JadeTeX backend driver.
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
from utils import registerTemp
import os

class JadeTeX(Backend):

	def postJade(self, outfile, stdoutfile):

	    savdir = os.getcwd()
	    (tmpdir, junk) = os.path.split(outfile)
	    self._tracer.chdir(savdir)
            finalfile = os.path.join(self._fileparts[1],
                self._fileparts[0] + '.tex')
            self._tracer.mv(outfile, finalfile)

class JadeTeXGlobals(BackendGlobals):

    def getName(self):
	return 'jadetex'

    def getJadeSettings(self):
	return ('sgmltools-tex', 'tex')
