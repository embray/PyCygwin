# -*- coding: utf-8 -*-
"""High-level Python wrappers for Cygwin API functions."""


try:
    __version__ = \
        __import__('pkg_resources').get_distribution('pycygwin').version
except:
    __version__ = ''


import os
import sys

from . import _cygwin


PY2 = sys.version_info[0] == 2
if PY2:
    text_type = unicode
else:
    text_type = str


__all__ = ['cygpath', 'winpid_to_pid', 'pid_to_winpid']


def cygpath(path, mode='unix', absolute=True):
    r"""
    Provides a Python implementation of Cygwin path conversion à la the
    ``cygpath`` system utility from Cygwin.

    Currently this does not supply a full replacement for the ``cygpath``
    utility, but does provide the most common functionality (replacing UNIX
    paths with Windows paths and vice-versa).

    Parameters
    ----------
    path : `str` or path-like
        The path to convert; either a UNIX-style path or a Windows-style path.
    mode : `str`, optional
        Currently supports one of ``'u'``/``'unix'`` or ``'w'``/``'windows'``
        indicating the style of path to *return* (regardless of the style of
        the input path, which can be either) (default: ``'unix'``).
    absolute : `bool`, optional
        If `True`, return an absolute path; otherwise return a relative path
        (default: `True`).

    Examples
    --------
    For conversions from a given POSIX path to its associated Windows path,
    most paths starting with ``/`` and not under ``/cygdrive`` will be relative
    to the Cygwin install path::

        >>> import os, cygwin
        >>> cyg_root = cygwin.cygpath('/', 'w')
        >>> cygdrive = os.path.dirname(cygwin.cygpath('C:\\').rstrip('/'))

    However, ``/cygdrive`` paths are special and will map directly to the
    equivalent Windows path (the path does not have to actually exist)::

        >>> print(cygwin.cygpath(cygdrive + '/c/Windows', 'w'))
        C:\Windows
        >>> print(cygwin.cygpath(cygdrive + '/q/DOES_NOT_EXIST', 'w'))
        Q:\DOES_NOT_EXIST

    When going from Windows to POSIX paths, if the path is relative to the
    Cygwin install root, then the returned path will be directly under ``/``,
    without the cygdrive prefix, even if it doesn't exist::

        >>> print(cygwin.cygpath(cyg_root))
        /
        >>> print(cygwin.cygpath(cyg_root + '\\usr'))
        /usr
        >>> print(cygwin.cygpath(cyg_root + '\\does_not_exist'))
        /does_not_exist

    However, if the Windows path is not relative to the Cygwin install root
    then the returned path is relative to the cygdrive prefix::

        >>> pth = cygwin.cygpath('C:\\')
        >>> pth
        '.../c/'
        >>> pth == os.path.join(cygdrive, 'c/')
        True
        >>> pth = cygwin.cygpath('Q:\\DOES_NOT_EXIST')
        >>> pth
        '.../q/DOES_NOT_EXIST'
        >>> pth == os.path.join(cygdrive, 'q/DOES_NOT_EXIST')
        True
    """

    supported_modes = {
        'u': 'unix',
        'w': 'windows'
    }

    if (not mode or mode[0] not in supported_modes or
            (len(mode) > 1 and mode != supported_modes[mode[0]])):
        raise ValueError("mode must be one of " +
                ' '.join("'{}'/'{}'".format(item)
                         for item in sorted(supported_modes.items())))

    mode = supported_modes[mode[0]]

    if not isinstance(path, (text_type, bytes)):
        path = text_type(path)

    char_width = 'W' if isinstance(path, text_type) else 'A'

    if mode == 'unix':
        what = getattr(_cygwin, 'CCP_WIN_{}_TO_POSIX'.format(char_width))
    else:
        what = getattr(_cygwin, 'CCP_POSIX_TO_WIN_{}'.format(char_width))

    if absolute:
        what |= _cygwin.CCP_ABSOLUTE
    else:
        what |= _cygwin.CCP_RELATIVE

    return _cygwin.conv_path(what, path)


# This one is easy--just use the low-level implementation directly
winpid_to_pid = _cygwin.winpid_to_pid


def pid_to_winpid(pid):
    """
    Converts the PID of a Cygwin process to its native Windows PID.

    Raises ``OSError(ESRCH, ...)`` if no process with the given PID exists.

    Parameters
    ----------
    pid : `int`
        The PID of a Cygwin process to convert.
    """

    return _cygwin.internal(_cygwin.CW_CYGWIN_PID_TO_WINPID, pid)
