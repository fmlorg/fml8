#
#  backends/iSilo.py
#
#  $Id: iSilo.py,v 1.2 2000/11/27 20:11:57 dnedrow Exp $
#
#  SGMLtools iSilo-based text backend driver.
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

class iSilo(Backend):

    def preJade(self, fh):
	#
	#  Check whether iSilo is there, if not: die
	#
	if self._autoconf['progs']['iSilo'] == 'N/A':
	    raise Exception, 'iSilo not configured, cannot produce output'
	else:
	    return fh

    def postJade(self, outfile, stdoutfile):
	#
	#  Jade wrote HTML, run it through iSilo.
	#
	destfile = os.path.join(self._fileparts[1], self._fileparts[0] + '.pdb')
	self._tracer.system ("%s -y -I %s %s" \
		    % (self._autoconf['progs']['iSilo'],
                       stdoutfile, destfile))


class iSiloGlobals(BackendGlobals):

    def getName(self):
	#
	#  As long as we're the only txt backend, we pose as 'pdb', not
	#  as 'iSilo'
	#
	return 'pdb'

    def getJadeSettings(self):
	return ('sgmltools-pdb', 'sgml')

    def printHelp(self, fh):
        """Not much help for iSilo."""
        print '\n\n'
        print 'iSilo (http://www.isilo.com) is an application that converts'
        print 'HTML and ASCII to documents which can be viewed on Palm'
        print 'compatible devices using the free iSilo reader.'
        print ''
        print 'While iSilo can parse HTML directly, the sgmltools'
        print 'implementation uses a text backend to generate the input'
        print 'to the iSilo encoder.'
        print ''
        print 'A future improvement to this backend will be input options'
        print 'that will allow the user to specify pre-processing formats.'
        print ''
        print 'Free linux encoders and Palm readers are available from the'
        print 'URL above.'

        pass

