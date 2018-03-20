"""Definitions from ``<sys/cygwin.h>``."""


from libc.stdint cimport uintptr_t
from posix.types cimport pid_t


cdef extern from "<sys/cygwin.h>" nogil:
    cpdef enum:
        CCP_POSIX_TO_WIN_A = 0
        CCP_POSIX_TO_WIN_W
        CCP_WIN_A_TO_POSIX
        CCP_WIN_W_TO_POSIX
        CCP_CONVTYPE_MASK = 3

        CCP_ABSOLUTE = 0
        CCP_RELATIVE = 0x100
        CCP_PROC_CYGDRIVE = 0x200
        CCP_CONVFLAGS_MASK = 0x300

    ctypedef unsigned int cygwin_conv_path_t

    ssize_t cygwin_conv_path(cygwin_conv_path_t what, const void* from_,
                             const void* to, size_t size)
    ssize_t cygwin_conv_path_list(cygwin_conv_path_t what, const void* from_,
                                  const void* to, size_t size)
    ssize_t cygwin_create_path(cygwin_conv_path_t what, const void* from_)

    pid_t cygwin_winpid_to_pid(int winpid)
    int cygwin_posix_path_list_p(const char* path)
    void cygwin_split_path(const char* path, char* dir, char* file)

    # These are keys into the cygwin_internal function to access internal
    # functionality from the Cygwin DLL that is not exposed through their
    # own dedicated functions.  Most of this functionality is undocumented
    # and is not to be used "unless you know what you're doing":
    # https://cygwin.com/cygwin-api/func-cygwin-internal.html
    #
    # Some of these methods are historical and still only defined in the enum
    # for backwards-compatibility, but don't really do anything.  Here we
    # attempt to document some of these methods for the current Cygwin version 
    # (2.8.x, though these interfaces didn't change for some time before then)
    cpdef enum:
        CW_LOCK_PINFO  # no-op
        CW_UNLOCK_PINFO  # no-op
        CW_GETTHREADNAME  # returns pointer to the current thread name
        # given a Cygwin PID, returns a pointer to an external_pinfo struct
        # for the associated process
        CW_GETPINFO
        CW_SETPINFO
        CW_SETTHREADNAME  # no-op except for setting errno=ENOSYS
        # returns a pointer of a human-readable string containing several
        # Cygwin-related versions (the same displayed by cygcheck -s under
        # "Cygwin DLL version info")
        CW_GETVERSIONINFO
        CW_READ_V1_MOUNT_TABLES  # no-op except for setting errno=ENOSYS
        # returns pointer to a low-level per_process struct that each user of
        # the Cygwin DLL (e.g. other DLLs) has filled out; this has no
        # immediately-obvious use as it is very low-level so we don't implement
        # any support for it currently
        CW_USER_DATA
        # takes an argument to an array of struct __cygwin_perfile structs;
        # this can be used as a hack in porting some software to force the
        # default file open flags for either specific files or all files; we
        # don't do anything with this for now
        CW_PERFILE
        CW_GET_CYGDRIVE_PREFIXES
        CW_GETPINFO_FULL
        CW_INIT_EXCEPTIONS
        CW_GET_CYGDRIVE_INFO
        CW_SET_CYGWIN_REGISTRY_NAME
        CW_GET_CYGWIN_REGISTRY_NAME
        CW_STRACE_TOGGLE
        CW_STRACE_ACTIVE
        CW_CYGWIN_PID_TO_WINPID
        CW_EXTRACT_DOMAIN_AND_USER
        CW_CMDLINE
        CW_CHECK_NTSEC
        CW_GET_ERRNO_FROM_WINERROR
        CW_GET_POSIX_SECURITY_ATTRIBUTE
        CW_GET_SHMLBA
        CW_GET_UID_FROM_SID
        CW_GET_GID_FROM_SID
        CW_GET_BINMODE
        CW_HOOK
        CW_ARGV
        CW_ENVP
        CW_DEBUG_SELF
        CW_SYNC_WINENV
        CW_CYGTLS_PADSIZE
        CW_SET_DOS_FILE_WARNING
        CW_SET_PRIV_KEY
        CW_SETERRNO
        CW_EXIT_PROCESS
        CW_SET_EXTERNAL_TOKEN
        CW_GET_INSTKEY
        CW_INT_SETLOCALE
        CW_CVT_MNT_OPTS
        CW_LST_MNT_OPTS
        CW_STRERROR
        CW_CVT_ENV_TO_WINENV
        CW_ALLOC_DRIVE_MAP
        CW_MAP_DRIVE_MAP
        CW_FREE_DRIVE_MAP
        CW_SETENT
        CW_GETENT
        CW_ENDENT
        CW_GETNSSSEP
        CW_GETPWSID
        CW_GETGRSID
        CW_CYGNAME_FROM_WINNAME
        CW_FIXED_ATEXIT
        CW_GETNSS_PWD_SRC
        CW_GETNSS_GRP_SRC
        CW_EXCEPTION_RECORD_FROM_SIGINFO_T
        CW_CYGHEAP_PROFTHR_ALL

    # Really cygwin_getinfo_types should by typedef'd from the above
    # enum, but current Cython does not allow doing that and cpdef-ing
    # it at the same time.
    ctypedef unsigned int cygwin_getinfo_types

    uintptr_t cygwin_internal(cygwin_getinfo_types t, ...)
