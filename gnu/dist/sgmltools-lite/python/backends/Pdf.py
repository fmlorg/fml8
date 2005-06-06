#
#  backends/Pdf.py
#
#  $Id: Pdf.py,v 1.2 2000/08/03 12:38:57 cdegroot Exp $
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
import os

class Pdf(Backend):

	def postJade(self, outfile, stdoutfile):

	    #
	    #  Looks like that from 1.1.8, jadetex writes output in cwd 
	    #  instead of TMPDIR. No matter what jadetex chooses to do, 
	    #  this will make sure it lands in TMPDIR. We set TEXINPUTS 
	    #  so that included graphics are found.
	    #
	    savdir = os.getcwd()
	    envname = 'TEXINPUTS'
	    if os.environ.has_key(envname):
		os.environ[envname] = '.:%s:%s' % (savdir, os.environ[envname])
	    else:
		os.environ[envname] = '.:%s:' % (savdir)
	    (tmpdir, junk) = os.path.split(outfile)
	    self._tracer.chdir(tmpdir)

	    #
	    #  Run JadeTeX on the generated file, thrice. 
	    #
	    (pdfbase, junk) = os.path.splitext(outfile)
	    destfile = pdfbase + '.pdf'
	    cmdline = 'pdfjadetex ' + outfile
	    for run in range(3):
		try:
		    os.unlink(destfile)
		except:
		    pass
		self._tracer.system(cmdline)
		if not os.path.isfile(destfile):
		    raise IOError, 'JadeTeX run failed'

	    #
	    #  Write generated PDF file to destination if we're the final
	    #  backend. If we're nested, leave the file hanging around.
	    #
	    self._tracer.chdir(savdir)
	    if self._globs.getName() == 'pdf':
		finalfile = os.path.join (self._fileparts[1],
				self._fileparts[0] + '.pdf')
                self._tracer.mv(destfile, finalfile)

            #
            #  Make sure that the temporary files are unlinked, later on.
            #
            registerTemp(os.path.join(tmpdir, pdfbase + '.log'))
            registerTemp(os.path.join(tmpdir, pdfbase + '.aux'))



class PdfGlobals(BackendGlobals):

    def getName(self):
	return 'pdf'

    def getJadeSettings(self):
	return ('sgmltools-pdf', 'tex')
