PyCygwin
########

Python and Cython wrappers for `Cygwin's C API
<https://cygwin.com/cygwin-api/>`_.


Installation
============

::

    pip install PyCygwin

Naturally, this is only installable in Cygwin-provided Python (i.e. where
``sys.platform == 'cygwin'``).


Documentation
=============

The initial version (v0.1) does not provide a complete cover for the API.
It only supports three useful functions:

* :func:`cygwin.cygpath` -- this provides a (partial) equivalent to the
  `cygpath <https://cygwin.com/cygwin-ug-net/cygpath.html>`_ system utility,
  supporting the most useful functionality thereof (that is, converting
  Cygwin paths to native Windows paths and vice-versa).

* :func:`cygwin.winpid_to_pid` -- converts the native Windows PID of a
  process to its PID in Cygwin (if it is a Cygwin process).

* :func:`cygwin.pid_to_winpid` -- likewise, converts the PID of a Cygwin
  process to its native Windows PID.
