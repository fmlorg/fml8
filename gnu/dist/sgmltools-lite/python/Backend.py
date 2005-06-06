#
#  Backend.py - Backend interface
#
#  $Id: Backend.py,v 1.1 2000/03/24 09:16:45 cdegroot Exp $
#
#  SGMLtools - an SGML toolkit.
#  Copyright (C)1998 Cees A. de Groot
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
#

"""
    This module defines base classes for backend modules. 
    Backends need to inherit from this.
"""

class Backend:
    """Base backend class.

	This class is actually a backend _process_, one is instantiated
	for every file processed. Therefore, the class may store
	information between passes to facilitate work.
    """

    _filename = ''
    _fileparts = ()

    def __init__(self, filename, fileparts, globs, tracer, autoconf):
	"""Create a new instance.

	    The filename is the file that will be parsed, the globs
	    argument is a pointer to the BackendGlobals class
	    associated with this object. Fileparts is a 3-tuple
	    containing (name, path, extension)

	    This base constructor stores the arguments in corresponding
	    fields (with underscore-prefix).
	"""

	self._filename = filename
	self._fileparts = fileparts
	self._globs = globs
	self._tracer = tracer
	self._autoconf = autoconf
    
    def preJade(self, fh):
	"""Execute actions that need to take place before Jade is invoked.

	    This method receives a filehandle that points to the main
	    input file as indicated on the command line.

	    The method should return a filehandle that needs to be
	    passed as input to Jade (the base implementation simply
	    returns its input filehandle).
	"""

	return fh

    def postJade(self, outfile, stdoutfile):
	"""Execute actions that need to take place after Jade has run.

	    The method receives two filenames: the first is the filename
	    that was given to Jade as a '-o' parameter, the second is the
	    filename where stdout was redirected to.

	"""

	pass
    

class BackendGlobals:
    """A class containing backend-global stuff.

	This base class will be instantiated exactly once per backend. It
	is used to handle and store options, etcetera.
    """

    def getName(self):
	"""Get the name for this backend. 

	    This returns the name which can be used on the command
	    line --backend option to invoke this backend.
	"""

	return 'base'

    def getMoreOptions(self):
	"""Get extra options for this backend.

	    This method should return, in the same form as the global
	    options in utils.py, a list containing any extra options
	    defined by this backend. Each element contains a tuple
	    (short, long, helptext)
	"""

	return []


    def setOptions(self, options):
	"""Communicate optoins back to the backend.

	    This method is called after option processing so that the
	    backend may do anything it wants with the options as passed
	    on the command line.
	"""

	pass

    def getJadeSettings(self):
	"""Return stylesheet/backend information for Jade.

	    This method returns a tuple containing two elements:
	    1. The Jade backend to use for this backend
	    2. The stylesheet to use.
	"""

	return ('', '')

    def printHelp(self, fh):
	"""Print help information on the backend."""

	pass


