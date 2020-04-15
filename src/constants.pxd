# Some of the constants for madvise(2) are not guaranteed to be available.
# Apart from kernel version, it might be configured out, and simply not defined
# in the headers. While Cython lacks a #ifndef equivalent, we have to define a
# few things in a header file so that the names are defined so that the
# generated C file will compile.

cdef extern from "constants.h":

    # Linux
    enum: HWPOISON
    enum: MERGEABLE
    enum: SOFT_OFFLINE
    enum: HUGEPAGE
    enum: DUMP
    enum: FREE
    enum: ONFORK
