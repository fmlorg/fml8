#
#  backends/Lynx.py
#
#  $Id: Lynx.py,v 1.2 2000/10/25 06:00:05 cdegroot Exp $
#
#  SGMLtools Lynx-based text backend driver.
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

class Lynx(Backend):

    def preJade(self, fh):
	#
	#  Check whether Lynx is there, if not: die
	#
	if self._autoconf['progs']['lynx'] == 'N/A':
	    raise Exception, 'Lynx not configured, cannot produce output'
	else:
	    return fh

    def postJade(self, outfile, stdoutfile):
	#
	#  Jade wrote HTML, run it through lynx.
	#
	destfile = os.path.join(self._fileparts[1], self._fileparts[0] + '.txt')
	self._tracer.system ("lynx -dump -nolist -force_html %s >%s" \
		    % (stdoutfile, destfile))


class LynxGlobals(BackendGlobals):

    def getName(self):
	#
	#  Now that there is more than one txt backend, we pose as 'lynx', not
	#  as 'txt'
	#
	return 'lynx'

    def getJadeSettings(self):
	return ('sgmltools-lynx', 'sgml')

