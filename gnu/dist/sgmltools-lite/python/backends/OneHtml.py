#
#  backends/OneHtml.py
#
#  $Id: OneHtml.py,v 1.2 2000/08/03 12:38:57 cdegroot Exp $
#
#  SGMLtools DVI backend driver.
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
import os, string

class OneHtml(Backend):

	def postJade(self, outfile, stdoutfile):

	    #
	    #  Write generated HTML file to destination.
	    #
	    destfile = os.path.join(self._fileparts[1], 
				    self._fileparts[0] + '.html')
            self._tracer.mv(stdoutfile, destfile)

class OneHtmlGlobals(BackendGlobals):

    def getName(self):
	return 'onehtml'

    def getJadeSettings(self):
	return ('sgmltools-onehtml', 'sgml')
