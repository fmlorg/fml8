#
#  backends/W3m.py
#
#  $Id: W3m.py,v 1.2 2000/11/27 20:11:57 dnedrow Exp $
#
#  SGMLtools W3m-based text backend driver.
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

class W3m(Backend):

    def preJade(self, fh):
	#
	#  Check whether W3m is there, if not: die
	#
	if self._autoconf['progs']['w3m'] == 'N/A':
	    raise Exception, 'w3m not configured, cannot produce output'
	else:
	    return fh

    def postJade(self, outfile, stdoutfile):
	#
	#  Jade wrote HTML, run it through w3m.
	#
	destfile = os.path.join(self._fileparts[1], self._fileparts[0] + '.txt')
	self._tracer.system ("w3m -T text/html -dump %s >%s" \
		    % (stdoutfile, destfile))


class W3mGlobals(BackendGlobals):

    def getName(self):
	#
	#  As long as we're the only txt backend, we pose as 'txt', not
	#  as 'w3m'
	#
	return 'w3m'

    def getJadeSettings(self):
	return ('sgmltools-w3m', 'sgml')

    def printHelp(self, fh):
        """Not much help for w3m."""
        print '\n\n'
        print 'w3m (http://ei5nazha.yz.yamagata-u.ac.jp/~aito/w3m/eng) is a'
        print 'text-based pager that can be used to browse websites from a'
        print 'console. It can also be used to generate text versions of'
        print 'websites, generally with better output than the Lynx dump'
        print 'facility. If w3m is found when sgmltools-lite is installed'
        print 'it becomes the default parser for the txt backend.'

        pass

