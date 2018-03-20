PyCygwin
########

Python and Cython wrappers for `Cygwin's C API
<https://cygwin.com/cygwin-api/>`_.


Installation
============

::

    pip install Cython
    pip install PyCygwin

Naturally, this is only installable in Cygwin-provided Python (i.e. where
``sys.platform == 'cygwin'``).  Cython is currently an installation
requirement, unfortunately, as PyPI will not allow uploading wheels for the
Cygwin platform.

Alternatively, you can direct pip to the wheels uploaded to GitHub, in
which case Cython should not be needed::

    pip install https://github.com/embray/PyCygwin/releases/download/0.1/PyCygwin-0.1-cp36-cp36m-cygwin_2_9_0_x86_64.whl

for Python 3.6, or for Python 2.7::

    pip install https://github.com/embray/PyCygwin/releases/download/0.1/PyCygwin-0.1-cp27-cp27m-cygwin_2_9_0_x86_64.whl


Usage
=====

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


API
===

.. automodule:: cygwin
    :members:
