#!/usr/bin/env python

import json
import os
import time
import sys

from distutils import log
from distutils.command.build import build as _build
from distutils.command.build_ext import build_ext
from distutils.errors import DistutilsModuleError, DistutilsOptionError

from setuptools import setup, Command, Extension

class build_cython(Command):
    description = "compile Cython extensions into C/C++ extensions"

    user_options = [
        ('build-dir=', 'd',
         "directory for compiled C/C++ sources and header files"),
        ('profile', 'p',
         "enable Cython profiling support"),
        ('parallel=', 'j',
         "run cythonize in parallel with N processes"),
        ('force=', 'f',
         "force files to be cythonized even if the are not changed")
    ]

    boolean_options = ['debug', 'profile', 'force']

    def initialize_options(self):
        self.extensions = None
        self.build_base = None
        self.build_dir = None

        # Always have Cython produce debugging info by default, unless
        # SAGE_DEBUG=no explicitly
        self.debug = True
        self.profile = None
        self.parallel = None
        self.force = None

        self.cython_directives = None
        self.compile_time_env = None

        self.build_lib = None
        self.cythonized_files = None

    def finalize_options(self):
        self.extensions = self.distribution.ext_modules

        # Let Cython generate its files in the "cythonized"
        # subdirectory of the build_base directory.
        self.set_undefined_options('build', ('build_base', 'build_base'))
        self.build_dir = self.build_base

        # Inherit some options from the 'build_ext' command if possible
        # (this in turn implies inheritance from the 'build' command)
        inherit_opts = [('build_lib', 'build_lib'),
                        ('debug', 'debug'),
                        ('force', 'force')]

        # Python 3.5 now has a parallel option as well
        if sys.version_info[:2] >= (3, 5):
            inherit_opts.append(('parallel', 'parallel'))

        self.set_undefined_options('build_ext', *inherit_opts)

        if self.debug:
            log.info('Enabling Cython debugging support')

        if self.profile:
            log.info('Enabling Cython profiling support')

        if self.parallel is None:
            self.parallel = 0

        try:
            self.parallel = int(self.parallel)
        except ValueError:
            raise DistutilsOptionError("parallel should be an integer")

        try:
            import Cython
        except ImportError:
            raise DistutilsModuleError(
                "Cython must be installed and importable in order to run "
                "the cythonize command")

        # Cython compiler directives
        self.cython_directives = dict(
            auto_pickle=False,
            autotestdict=False,
            cdivision=True,
            embedsignature=True,
            fast_getattr=True,
            profile=self.profile,
        )

        self.compile_time_env = dict(
            PY_MAJOR_VERSION=sys.version_info[0]
        )

        # We check the Cython version and some relevant configuration
        # options from the earlier build to see if we need to force a
        # recythonization. If the version or options have changed, we
        # must recythonize all files.
        self._version_file = os.path.join(self.build_dir, '.cython_version')
        self._version_stamp = json.dumps({
            'version': Cython.__version__,
            'debug': self.debug,
            'directives': self.cython_directives,
            'compile_time_env': self.compile_time_env
        }, sort_keys=True)

        # Read an already written version file if it exists and compare to the
        # current version stamp
        try:
            if open(self._version_file).read() == self._version_stamp:
                force = False
            else:
                # version_file exists but its contents are not what we
                # want => recythonize all Cython code.
                force = True
                # In case this cythonization is interrupted, we end up
                # in an inconsistent state with C code generated by
                # different Cython versions or with different options.
                # To ensure that this inconsistent state will be fixed,
                # we remove the version_file now to force a
                # recythonization the next time we build Sage.
                os.unlink(self._version_file)
        except IOError:
            # Most likely, the version_file does not exist
            # => (re)cythonize all Cython code.
            force = True

        # If the --force flag was given at the command line, always force;
        # otherwise use what we determined from reading the version file
        if self.force is None:
            self.force = force

    def run(self):
        """
        Call ``cythonize()`` to replace the ``ext_modules`` with the
        extensions containing Cython-generated C code.
        """
        from Cython.Build import cythonize
        import Cython.Compiler.Options

        Cython.Compiler.Options.embed_pos_in_docstring = True

        log.info("Updating Cython code....")
        t = time.time()
        extensions = cythonize(
            self.extensions,
            nthreads=self.parallel,
            build_dir=self.build_dir,
            force=self.force,
            compiler_directives=self.cython_directives,
            compile_time_env=self.compile_time_env,
            # Debugging
            gdb_debug=self.debug,
            output_dir=self.build_dir,
            # Disable Cython caching, which is currently too broken to
            # use reliably: http://trac.sagemath.org/ticket/17851
            cache=False,
            )

        for ext in extensions:
            # Hack around a Cython/setutools bug
            ext._needs_stub = False

        # We use [:] to change the list in-place because the same list
        # object is pointed to from different places.
        self.extensions[:] = extensions

        log.info("Finished Cythonizing, time: {:.2f} seconds.".format(
            (time.time() - t)))

        with open(self._version_file, 'w') as f:
            f.write(self._version_stamp)


class build(_build):
    """
    Same as the default build command, but adds build_cython as a
    sub-command.
    """

    sub_commands = ([('build_cython', lambda *args: True)] +
                    _build.sub_commands)


setup(
    name='PyCygwin',
    version='0.1',
    packages=['cygwin'],
    ext_modules=[Extension('cygwin._cygwin',
                 [os.path.join('cygwin', '_cygwin.pyx')])],
    cmdclass={
        'build_cython': build_cython,
        'build': build
    }
)
