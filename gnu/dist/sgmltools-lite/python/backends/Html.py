#
#  backends/Html.py
#
#  $Id: Html.py,v 1.5 2000/10/26 06:20:23 cdegroot Exp $
#
#  SGMLtools HTML backend driver.
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
import utils, os, string, stat

class Html(Backend):
    
    def preJade(self, fh):
	#
	#  Make a temporary directory, and change in there. Correct the
	#  filename if it wasn't absolute by prepending the old working
	#  directory.
	#
	self._savdir = os.getcwd();
	self._tempdir, junk = os.path.splitext(utils.makeTemp())
	self._tracer.mkdir(self._tempdir, 0700)
	self._tracer.chdir(self._tempdir)

	return fh

    def postJade(self, outfile, stdoutfile):
	#
	#  If we land here, everything worked out fine. Below the
	#  original working directory, create a subdirectory, and copy
	#  the results from the temporary directory over there.
	#
	#  We clean the destination directory first so that old parts
	#  don't hang around, and we make a symlink named "index.html"
	#  pointing to the logical starting point of the resulting html
	#  set.
	#
	self._tracer.chdir(self._savdir)	# so relative names work ok.
	(srcdir, junk) = os.path.split(outfile)
	destdir = os.path.join(self._fileparts[1], self._fileparts[0])

        if os.path.exists(destdir):
            self._tracer.system('rm -rf ' + destdir + '/*')
        else:
            self._tracer.mkdir(destdir)

        self._tracer.mv(self._tempdir + '/*', destdir)
	self._tracer.rmdir(self._tempdir)

	#
	#  The first file in the manifest is what we'll see as index.html
	#
	self._tracer.chdir(destdir)
	try:
	    fh = open('HTML.manifest', 'r')
	    indexfile = string.strip(fh.readline())
	    fh.close()
	    self._tracer.symlink(indexfile, 'index.html')
	except:
	    pass


	self._tracer.chdir(self._savdir)


class HtmlGlobals(BackendGlobals):

    def getName(self):
	return 'html'

    def getJadeSettings(self):
	return ('sgmltools-html', 'sgml')
