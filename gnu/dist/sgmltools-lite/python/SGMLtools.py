#
#  SGMLtools.py - SGMLtools main routine.
#
#  $Id: SGMLtools.py,v 1.4 2000/10/25 06:00:05 cdegroot Exp $
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
    This module contains the main logic for SGMLtools. It is wrapped
    in a class so that once somebody cooks up a use for it, you can
    actually have multiple copies active (although we'd need to factor
    initialization into repeatable and non-repeatable parts, then).
"""

import sys, os, glob, imp, getopt
import Backend, utils

class SGMLtools:
    _globals = {}
    _classes = {}
    _autoconf = {}

    def __init__(self, autoconf):
	"""Create an SGMLtools object.

	    This method hunts for backend modules and does some other
	    assorted initialization things. The autoconf argument
	    contains some assorted settings that are passed down from
	    autoconf.

	"""

	self._autoconf = autoconf

	#
	#  Expand path
	#
	sys.path.append(os.path.join(autoconf['shrdir'], 'python'))
	sys.path = sys.path + autoconf['backends']

	#
	#  Import backends, instantiate a BackendGlobals object for
	#  each of them, and stash it away.
	#
	files = []
	for dir in autoconf['backends']:
	    pattern = os.path.join(dir, '*.py')
	    files = files + glob.glob(pattern)
	for file in files:
	    name, junk = os.path.splitext(file)
	    dir, module = os.path.split(name)
	    cmd = 'from %s import %s, %s' % (module, module, module + 'Globals')
	    exec cmd
	    cmd = 'glob = %sGlobals()' % module
	    exec cmd
	    self._globals[glob.getName()] = glob
	    cmd = 'cls = %s' % module
	    exec cmd
	    self._classes[glob.getName()] = cls

	#
	#  Read alias file
	#
	self._aliases = utils.readAliases(autoconf)
	

	#
	#  Setup SGML environment
	#
	if not os.environ.has_key('SGML_CATALOG_FILES'):
	    os.environ['SGML_CATALOG_FILES'] = \
			os.path.join(autoconf['etcdir'], 'catalog') \
                        + ":" + "/usr/share/sgml/stylesheets/sgmltools/sgmltools.cat" \
                        + ":" + "/usr/share/sgml/CATALOG.docbkdsl"


    def processOptions(self, args):
	"""Process command line options.

	    Process command line options, dynamically expanding them
	    based on the --backend option, and returning the list of
	    files that's left.
	"""

	#
	#  Hunt down the backend option. The first test tests for
	#  "-b x", the second for "-bx" (or the equivalend long versions).
	#
	numArgs = len(args)
	for i in range(numArgs):
	    arg = args[i]
	    if arg in ["-b", "--backend"]:
		if i+1 >= numArgs:
		    raise getopt.error, "option %s requires an argument" % arg
		miniargs = [arg, args[i+1]]
		break
	    if arg[:2] == "-b" or arg[:10] == "--backend=":
		miniargs = [arg]
		break
	else:
	    #
	    #  Default to the HTML backend.
	    #
	    miniargs = [ "--backend=onehtml" ];

	#
	#  We should have a backend option now. Ask getopt to parse it. Once
	#  we have it, ask the backend for extra options so we can get
	#  down to business.
	#
	opt, junk = getopt.getopt(miniargs, 'b:', ['backend='])
        #
        # if opt = 'txt', check for 'w3m' else fallback to 'lynx'
        #
        if opt[0][1] == "txt":
          if not self._autoconf['progs']['w3m'] == 'N/A':
            self._curbackend = "w3m"
          else:
            self._curbackend = "lynx"
        else:
          self._curbackend = opt[0][1]

	try:
		self._curglobal  = self._globals[self._curbackend]
	except KeyError:
	    utils.usage(None, "Unknown backend " + self._curbackend)
	if not self._globals.has_key(self._curbackend):
	    utils.usage(None, "Unknown backend " + self._curbackend)

	#
	#  Merge all the options and parse them. Return whatever is
	#  left (the list of files we need to run).
	#
	shortopts, longopts = utils.makeOpts(self._curglobal)
	try:
	    options, retval = getopt.getopt(args, shortopts, longopts)
	except getopt.error, e:
	    utils.usage(self._curglobal, 'Error parsing arguments: ' + `e`)

	self._options = utils.normalizeOpts(self._curglobal, options)

	#
	#  Check for help/version/... options
	#
	if utils.findOption(self._options, 'help'):
	    utils.version(self._autoconf['shrdir'])
	    print
	    utils.usage(self._curglobal, None)
	if utils.findOption(self._options, 'version'):
	    utils.version(self._autoconf['shrdir'])
	    sys.exit(0)
	if utils.findOption(self._options, 'license'):
	    utils.license()

	return retval

    def processFile(self, file):
	"""Process the indicated file"""


	#
	#  Some filename munching so the user can invoke us with our
	#  without the .sgml/.SGML extension.
	#
	filepath, filename = os.path.split(file)
	filename, fileext  = os.path.splitext(filename)
	if filepath == '':
	    filepath = '.'
	if os.path.isfile(file):
	    self._fileinfo = (filename, filepath, fileext)
	elif os.path.isfile(os.path.join(filepath, filename + '.sgml')):
	    self._fileinfo = (filename, filepath, '.sgml')
	elif os.path.isfile(os.path.join(filepath, filename + '.SGML')):
	    self._fileinfo = (filename, filepath, '.SGML')
	elif os.path.isfile(os.path.join(filepath, filename)):
	    self._fileinfo = (filename, filepath, '')
	else:
	    raise IOError, "file %s not found" % file

	self._filename = os.path.join(self._fileinfo[1], 
		    self._fileinfo[0] + self._fileinfo[2])

	#
	#  Create a backend instance.
	#
	if utils.findOption(self._options, 'verbose') != None:
	    dotrace = 1
	else:
	    dotrace = 0
	self._tracer = utils.Tracer(dotrace)
	be = self._classes[self._curbackend](self._filename, self._fileinfo,
			    self._curglobal, self._tracer, self._autoconf)

	#
	#  Make SGML_SEARCH_PATH absolute.
	#
	savdir = os.getcwd()
	os.chdir(filepath)
	envname = 'SGML_SEARCH_PATH'
	if os.environ.has_key(envname):
	    os.environ[envname] = os.environ[envname] + ':' + os.getcwd()
	else:
	    os.environ[envname] = os.getcwd()
	os.chdir(savdir)

	#
	#  Get the Jade parameters and see whether the stylesheet was
	#  overriden. Translate the stylesheet to an absolute filename
	#
	stylesheet, jadebe = self._curglobal.getJadeSettings()
	userSheet = utils.findOption(self._options, 'dsssl-spec')
	if userSheet != None:
	    stylesheet = userSheet
	dssslfile = utils.findStylesheet(stylesheet, self._aliases)
        addJadeOpt = ''
        userJadeOpt = utils.findOption(self._options, 'jade-opt')
	if userJadeOpt != None:
	    addJadeOpt = ' ' + userJadeOpt

	#
	#  Open the input file and give the pre-Jade routine a shot.
	#
	infile = open(self._filename, 'r')
	nextfile = be.preJade(infile)

	#
	#  Run Jade attached to a pipe
	#
	jadecmd = self._autoconf['progs']['jade']
	jadecmd = jadecmd + ' -t ' + jadebe
	jadecmd = jadecmd + ' -d ' + dssslfile
	jadeoutfile = utils.makeTemp()
	jadecmd = jadecmd + ' -o ' + jadeoutfile
	jadecmd = jadecmd + addJadeOpt
	jadestdoutfile = utils.makeTemp()
	jadecmd = jadecmd + ' >' + jadestdoutfile
	self._tracer.trace(jadecmd)
	jadepipe = os.popen(jadecmd, 'w')

	#
	#  Pump nextfile->jadepipe, and close all files.
	#
	jadepipe.writelines(nextfile.readlines())
	try:
	    jadepipe.close();
	    infile.close();
	    nextfile.close();
	except:
	    pass

	#
	#  Run the postJade stage.
	#
	be.postJade(jadeoutfile, jadestdoutfile)


