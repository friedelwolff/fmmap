# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# cython: language_level=3

from mmap import *
import sys


cdef str platform = <str>sys.platform

cdef int py_version = sys.hexversion
DEF PY39 = 0x030901f0
DEF PY38 = 0x030801f0
DEF PY37 = 0x030701f0
DEF PY36 = 0x030601f0


import cython
from cpython cimport exc
from libc cimport string

cimport constants


cdef extern from "<string.h>":
    #GNU extension to glibc
    unsigned char *memmem(const void *haystack, size_t haystacklen,
                 const void *needle, size_t needlelen) nogil


cdef unsigned char *my_memmem(
        const unsigned char *buf_p,
        size_t haystack_len,
        const unsigned char *needle,
        size_t needle_len,
    ) nogil:
    cdef unsigned char *c
    i = haystack_len - needle_len + 1
    c = <unsigned char *>string.memchr(buf_p, needle[0], i)
    while c:
        if string.memcmp(c, needle, needle_len) == 0:
            return c
        i = haystack_len - (c - buf_p) - needle_len
        c = <unsigned char *>string.memchr(c + 1, needle[0], i)

    return NULL


_transform_flush_return_value = lambda value: value


if py_version < PY38:
    # We want to implement the return convention for flush() introduced in
    # Python 3.8. If we are running on an earlier version, let's massage the
    # return value:

    IF UNAME_SYSNAME == "Windows":
        def _transform_flush_return_value(value):
            if value == 0:
                # error
                exc.PyErr_SetFromWindowsErr(0)
            else:
                # success
                return None
    ELSE:
        def _transform_flush_return_value(value):
            # unix (and others)
            if value == 0:
                # success
                return None
            else:
                # error
                # Should not be reached, since flush() raises an exception on
                # errors on Python < 3.8
                pass


if py_version < PY38 and not platform.startswith("windows"):
    # Constants needed for madvise

    from posix cimport mman

    MADV_NORMAL = mman.MADV_NORMAL
    MADV_RANDOM = mman.MADV_RANDOM
    MADV_SEQUENTIAL = mman.MADV_SEQUENTIAL
    MADV_WILLNEED = mman.MADV_WILLNEED
    MADV_DONTNEED = mman.MADV_DONTNEED
    # common in several Unix type systems;
    if constants.FREE:
        MADV_FREE = mman.MADV_FREE

    IF UNAME_SYSNAME == "Linux":

        from platform import uname

        kernel = tuple(int(x) for x in uname()[2].split('-')[0].split('.'))
        if kernel >= (2, 6, 16):
            MADV_REMOVE = mman.MADV_REMOVE
            MADV_DONTFORK = mman.MADV_DONTFORK
            MADV_DOFORK = mman.MADV_DOFORK
        if kernel >= (2, 6, 32):
            if constants.HWPOISON:
                MADV_HWPOISON = mman.MADV_HWPOISON
            if constants.MERGEABLE:
                MADV_MERGEABLE = mman.MADV_MERGEABLE
                MADV_UNMERGEABLE = mman.MADV_UNMERGEABLE
        if kernel >= (2, 6, 33) and constants.SOFT_OFFLINE:
            MADV_SOFT_OFFLINE = mman.MADV_SOFT_OFFLINE
        if kernel >= (2, 6, 38) and constants.HUGEPAGE:
            MADV_HUGEPAGE = mman.MADV_HUGEPAGE
            MADV_NOHUGEPAGE = mman.MADV_NOHUGEPAGE
        if kernel >= (3, 4, 0) and constants.DUMP:
            MADV_DONTDUMP = mman.MADV_DONTDUMP
            MADV_DODUMP = mman.MADV_DODUMP
        if kernel >= (4, 14, 0) and constants.ONFORK:
            MADV_WIPEONFORK = mman.MADV_WIPEONFORK
            MADV_KEEPONFORK = mman.MADV_KEEPONFORK
        del kernel
        del uname

    ELSE:
        # FreeBSD:
        if constants.NOSYNC:
            MADV_NOSYNC = constants.MADV_NOSYNC
            MADV_AUTOSYNC = constants.MADV_AUTOSYNC
        if constants.CORE:
            MADV_NOCORE = constants.MADV_NOCORE
            MADV_CORE = constants.MADV_CORE
        if constants.PROTECT:
            MADV_PROTECT = constants.MADV_PROTECT


# Some madvise constants aren't in the standard library (in any Python version
# so far), so we expose them here unconditionally:

# OpenBSD:
if constants.SPACEAVAIL:
    MADV_SPACEAVAIL = constants.MADV_SPACEAVAIL


if py_version < PY37:
    ACCESS_DEFAULT = 0


_mmap = mmap

class mmap(_mmap):

    if py_version < PY39:

        def __init__(self, *args, **kwargs):
            self._fileno = kwargs.get("fileno", args[0])
            # remember a few parameters for __repr__
            self._access = kwargs.get("access", 0)  # kwarg only
            self._offset = kwargs.get("offset", 0)  # kwarg only
            _mmap.__init__(*args, **kwargs)

        def __repr__(self):
            if self.closed:
                return "<fmmap.mmap closed=True>"
            names = {
                    ACCESS_DEFAULT: "ACCESS_DEFAULT",
                    ACCESS_READ: "ACCESS_READ",
                    ACCESS_WRITE: "ACCESS_WRITE",
                    ACCESS_COPY: "ACCESS_COPY",
            }
            access = names.get(self._access, "unknown!")
            return ("<fmmap.mmap "
                f"closed=False, "
                f"access={access}, "
                f"length={len(self)}, "
                f"pos={self.tell()}, "
                f"offset={self._offset}>"
            )

    if py_version < PY38 and not platform.startswith("windows"):

        def madvise(self, option, start=0, length=None):
            cdef const unsigned char[:] buf = self
            cdef ssize_t buf_len = len(buf)
            cdef unsigned char *buf_p

            if length is None:
                length = buf_len

            if start < 0 or start >= buf_len:
                raise ValueError("madvise start out of bounds")
            if length < 0:
                raise ValueError("madvise length invalid")
            if sys.maxsize - start < length:
                raise OverflowError("madvise length too large")

            if start + length > buf_len:
                length = buf_len - start

            buf_p = &buf[start]
            if mman.madvise(buf_p, length, option) != 0:
                exc.PyErr_SetFromErrno(OSError)

    if py_version < PY38:

        def flush(self, *args, **kwargs):
            value = super().flush(*args, **kwargs)
            return _transform_flush_return_value(value)

    if py_version < PY36:

        def __add__(self, value):
            raise TypeError()

        def __mul__(self, value):
            raise TypeError()

        def write(self, bytes):
            cdef const unsigned char[:] buf = bytes
            super().write(buf)
            return len(buf)

        def resize(self, newsize):
            if self._access not in (ACCESS_WRITE, ACCESS_DEFAULT):
                raise TypeError()
            if newsize < 0 or sys.maxsize - newsize < self._offset:
                raise ValueError("new size out of range")
            if self._fileno != -1:
                super().resize(newsize)
                return

            # There is a bug in Python versions before 3.6. It would call
            # ftruncate(2) on file descriptor -1 (anonymous memory), so we
            # can't fall back on the built-in implementation.
            raise SystemError("Can't resize anonymous memory in Python < 3.6")


    def find(object self, sub, start=None, end=None):
        cdef const unsigned char[:] buf = self
        if start is None:
            start = self.tell()
        if end is None:
            end = len(buf)
        return self._find(sub, start, end)

    @cython.boundscheck(False)
    def _find(object self, r, ssize_t start, ssize_t end):
        cdef const unsigned char[:] buf = self
        cdef const unsigned char[:] needle = r
        cdef ssize_t buf_len = len(buf)
        cdef ssize_t needle_len = len(needle)
        cdef unsigned char *c
        cdef unsigned char *buf_p
        cdef unsigned char *needle_p

        # negative slicing and bounds checking
        if start < 0:
            start += buf_len
            if start < 0:
                start = 0
        elif start > buf_len:
            start = buf_len
        if end < 0:
            end += buf_len
            if end < 0:
                end = 0
        elif end > buf_len:
            end = buf_len

        # trivial cases
        if start >= end:
            return -1
        if needle_len == 0:
            return 0
        if buf_len == 0 or needle_len > buf_len:
            return -1
        if end - start < needle_len:
            return -1

        with nogil:
            buf_p = &buf[start]
            needle_p = &needle[0]
            if constants.MEMMEM:
                c = memmem(buf_p, end-start, needle_p, needle_len)
            else:
                c = my_memmem(buf_p, end-start, needle_p, needle_len)

        if c is NULL:
            return -1
        return c - buf_p + start
        
    def rfind(object self, sub, start=None, end=None):
        cdef const unsigned char[:] buf = self
        if start is None:
            start = self.tell()
        if end is None:
            end = len(buf)
        return self._rfind(sub, start, end)

    @cython.boundscheck(False)
    def _rfind(object self, r, ssize_t start, ssize_t end):
        cdef const unsigned char[:] buf = self
        cdef const unsigned char[:] needle = r
        cdef ssize_t buf_len = len(buf)
        cdef ssize_t needle_len = len(needle)
        cdef unsigned char *c = NULL
        cdef unsigned char *buf_p
        cdef unsigned char *needle_p
        cdef ssize_t i

        # negative slicing and bounds checking
        if start < 0:
            start += buf_len
            if start < 0:
                start = 0
        elif start > buf_len:
            start = buf_len
        if end < 0:
            end += buf_len
            if end < 0:
                end = 0
        elif end > buf_len:
            end = buf_len

        # trivial cases
        if start >= end:
            return -1
        if needle_len == 0:
            return 0
        if buf_len == 0 or needle_len > buf_len:
            return -1
        if needle_len > end - start:
            return -1

        with nogil:
            # Maybe not as fast as a good memmem(), but memrchr is hopefully
            # optimised. Worst case is still O(nm) where
            #  - n = len(buf)
            #  - m = len(needle)
            # Hopefully it is still faster than the naive algorithm in
            # CPython, or looping ourselves here.
            #
            # We repeatedly search for the first byte of needle from end to
            # start. When finding it, we check if the whole needle is there.

            buf_p = &buf[start]
            needle_p = &needle[0]
            i = end - start - needle_len + 1
            c = <unsigned char *>string.memrchr(buf_p, needle[0], i)
            while c:
                if string.memcmp(c, needle_p, needle_len) == 0:
                    break
                c = <unsigned char *>string.memrchr(buf_p, needle[0], c - buf_p)

        if c is NULL:
            return -1
        return c - buf_p + start
