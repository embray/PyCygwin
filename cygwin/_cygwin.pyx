"""Low-level wrappers around ``<sys/cygwin.h>`` functions."""

import locale
import sys

from cpython.bytes cimport PyBytes_FromStringAndSize, PyBytes_AS_STRING
from cpython.unicode cimport PyUnicode_Decode
from libc.errno cimport errno, ENOSYS, ESRCH
from libc.string cimport strerror, strlen


cdef extern from "Python.h":
    # Missing from cpython.unicode in Cython 0.27.3
    char* PyUnicode_AsUTF8(object s)


cdef inline strerror_as_str(int err):
    """
    Wrapper for ``strerror`` that returns the correct `str` type for the
    current Python version.
    """

    IF PY_MAJOR_VERSION == 2:
        return sterror(err)
    ELSE:
        cdef const char* s
        cdef const char* enc
        s = strerror(err)
        enc = PyUnicode_AsUTF8(locale.getpreferredencoding(False))
        return PyUnicode_Decode(s, strlen(s), enc, "ignore")


def conv_path(what, path):
    r"""
    Wrapper around ``cygwin_conv_path()`` that accepts unicode or bytes strings
    and returns the converted path as the same type as the original path.

    That as, if a unicode string is given, a unicode string is returned, and
    likewise for bytes--similarly to other path-related functions in the Python
    standard library.

    The meaning of the ``what`` argument is as documented in
    https://cygwin.com/cygwin-api/func-cygwin-conv-path.html

    Examples
    --------

    CCP_POSIX_TO_WIN_* convert a given POSIX path to its associated Windows
    path.  Most paths starting with ``/`` and not under ``/cygdrive`` will be
    relative to the Cygwin install path::

        >>> import os
        >>> from cygwin._cygwin import *
        >>> cyg_root = conv_path(CCP_POSIX_TO_WIN_A, '/')
        >>> cygdrive = os.path.dirname(
        ...     conv_path(CCP_WIN_A_TO_POSIX, 'C:\\').rstrip('/'))

    However, ``/cygdrive`` paths are special and will map directly to the
    equivalent Windows path (the path does not have to actually exist)::

        >>> print(conv_path(CCP_POSIX_TO_WIN_A, cygdrive + '/c/Windows'))
        C:\Windows
        >>> print(conv_path(CCP_POSIX_TO_WIN_A, cygdrive + '/q/DOES_NOT_EXIST'))
        Q:\DOES_NOT_EXIST

    When going from Windows to POSIX paths, if the path is relative to the
    Cygwin install root, then the returned path will be directly under ``/``,
    without the cygdrive prefix, even if it doesn't exist::

        >>> print(conv_path(CCP_WIN_A_TO_POSIX, cyg_root))
        /
        >>> print(conv_path(CCP_WIN_A_TO_POSIX, cyg_root + '\\usr'))
        /usr
        >>> print(conv_path(CCP_WIN_A_TO_POSIX, cyg_root + '\\does_not_exist'))
        /does_not_exist

    However, if the Windows path is not relative to the Cygwin install root
    then the returned path is relative to the cygdrive prefix::

        >>> pth = conv_path(CCP_WIN_A_TO_POSIX, 'C:\\')
        >>> pth
        '.../c/'
        >>> pth == os.path.join(cygdrive, 'c/')
        True
        >>> pth = conv_path(CCP_WIN_A_TO_POSIX, 'Q:\\DOES_NOT_EXIST')
        >>> pth
        '.../q/DOES_NOT_EXIST'
        >>> pth == os.path.join(cygdrive, 'q/DOES_NOT_EXIST')
        True
    """

    cdef ssize_t size
    cdef bytes to
    cdef int decode = 0

    # & out other modifiers to the "what" argument to get the basic
    # conversion mode
    mode = what & 0xff

    if isinstance(path, unicode):
        if mode == CCP_WIN_W_TO_POSIX:
            # Need to append an additional null byte for proper UTF-16
            # termination
            path = path.encode('utf-16-le') + b'\x00'
        else:
            # TODO: Should this really use UTF-8, or should it be based on the
            # current locale and/or code page?  Not clear at the moment.
            path = path.encode('utf-8')
        decode = 1

    size = cygwin_conv_path(what, PyBytes_AS_STRING(path), NULL, 0)
    if size < 0:
        raise OSError(errno, strerror_as_str(errno), path)

    to = PyBytes_FromStringAndSize("", size)

    size = cygwin_conv_path(what, PyBytes_AS_STRING(path),
                            PyBytes_AS_STRING(to), size)
    if size < 0:
        raise OSError(errno, strerror_as_str(errno), path)

    if decode:
        if mode == CCP_POSIX_TO_WIN_W:
            return to.decode('utf-16-le')[:-1]
        else:
            return to.decode('utf-8')[:-1]

    if mode == CCP_POSIX_TO_WIN_W:
        return to[:-2]

    return to[:-1]


def winpid_to_pid(pid):
    """
    Converts the native Windows PID of a Cygwin process to its Cygwin PID.

    Sometimes these are identical, but they don't have to be.  Raises an
    `OSError` if the PID does not exist, or does not map to a Cygwin PID.
    """

    pid = cygwin_winpid_to_pid(pid)
    if pid < 0:
        raise OSError(errno, strerror_as_str(errno))

    return pid


def internal(cygwin_getinfo_types t, *args):
    """
    Wrapper for the workhorse ``cygwin_internal()`` function, which provides
    interfaces to all sorts of internal Cygwin functionality for which there
    are not explicit functions (like ``cygwin_winpid_to_pid()``).

    The first argument to this function is one of the methods listed in the
    ``cygwin_getinfo_types`` enum.  The remaining arguments depend on which
    method we're calling.

    Some of the functionality provided by this function is simple enough that
    maybe it should have its own function, but historically it was simpler to
    always add more functionality to this function.  Its other advantage is
    that it will work across all Cygwin versions, and if we try some method on
    it that isn't supported by the current Cygwin version we'll just get an
    error (as opposed to failing to compile in the first place).

    Some of these methods are already no longer supported by recent Cygwin
    versions.  And many of them are for such low-level introspection that
    they may not ever be useful to wrap.

    For the first version this actually only supports one method:
    ``CW_CYGWIN_PID_TO_WINPID``.  This is the complement to the
    ``cygwin_pid_to_winpid()`` function, which for some reason is implemented
    in ``cygwin_internal()`` rather than having its own function.

    Some other ``cygwin_internal()`` methods may be useful as well, and support
    for them may be added in the future.  Calling this with an unsupported
    method raises an `OSError` with ``ENOSYS``.
    """

    # TODO: Generalize argument parsing and dispatching for cygwin_internal
    # methods.  Right now we only support one such method so it's moot.
    ret = None

    if t == CW_CYGWIN_PID_TO_WINPID:
        try:
            pid = args[0]
        except IndexError:
            raise TypeError(
                'cygwin_internal(CW_CYGWIN_PID_TO_WINPID, ...) takes exactly 1 '
                'argument ({} given)'.format(len(args)))

        ret = <pid_t>cygwin_internal(t, <pid_t>pid)
        if not ret:
            errno = ESRCH

    if errno:
        raise OSError(errno, strerror_as_str(errno))
    elif ret is None:
        raise OSError(ENOSYS, strerror_as_str(ENOSYS))

    return ret
