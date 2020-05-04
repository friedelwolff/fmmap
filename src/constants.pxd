# Some of the constants for madvise(2) are not guaranteed to be available.
# Apart from kernel version, it might be configured out, and simply not defined
# in the headers. While Cython lacks a #ifndef equivalent, we have to define a
# few things in a header file so that the names are defined so that the
# generated C file will compile.

cdef extern from "constants.h":

    # feature availability flags:
    enum: MEMMEM
    enum: MEMRCHR


    # constants related to madvise(2):

    # common
    enum: FREE

    # Linux
    enum: HWPOISON
    enum: MERGEABLE
    enum: SOFT_OFFLINE
    enum: HUGEPAGE
    enum: DUMP
    enum: ONFORK

    # In the following cases, the MADV_* constants are not all defined in
    # Cython's mman.pxd, so we add them in addition to our feature flags.

    # FreeBSD
    enum: NOSYNC
    enum: MADV_NOSYNC

    enum: AUTOSYNC
    enum: MADV_AUTOSYNC

    enum: NOCORE
    enum: MADV_NOCORE

    enum: CORE
    enum: MADV_CORE

    enum: PROTECT
    enum: MADV_PROTECT

    # OpenBSD
    enum: SPACEAVAIL
    enum: MADV_SPACEAVAIL

    # Solaris
    enum: ACCESS_DEFAULT
    enum: ACCESS_LWP
    enum: ACCESS_MANY
    enum: ACCESS_MANY_PSET
    enum: PURGE
    enum: MADV_ACCESS_DEFAULT
    enum: MADV_ACCESS_LWP
    enum: MADV_ACCESS_MANY
    enum: MADV_ACCESS_MANY_PSET
    enum: MADV_PURGE
