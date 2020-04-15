# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# cython: language_level=3

from mmap import *
import sys
version_info = sys.version_info


import cython
from cpython cimport exc

cimport constants


cdef extern from *:
    void *memrchr(const void *haystack, const int c, size_t haystacklen) nogil
    int memcmp(const void *s1, const void *s2, size_t n) nogil
    #GNU extension to glibc
    void *memmem(const void *haystack, size_t haystacklen,
                 const void *needle, size_t needlelen) nogil



_transform_flush_return_value = lambda value: value


if version_info < (3, 8):
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

    # Constants needed for madvise

    from posix cimport mman

    MADV_NORMAL = mman.MADV_NORMAL
    MADV_RANDOM = mman.MADV_RANDOM
    MADV_SEQUENTIAL = mman.MADV_SEQUENTIAL
    MADV_WILLNEED = mman.MADV_WILLNEED
    MADV_DONTNEED = mman.MADV_DONTNEED

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
        if kernel >= (4, 5, 0) and constants.FREE:
            MADV_FREE = mman.MADV_FREE
        if kernel >= (4, 14, 0) and constants.ONFORK:
            MADV_WIPEONFORK = mman.MADV_WIPEONFORK
            MADV_KEEPONFORK = mman.MADV_KEEPONFORK
        del kernel


if version_info < (3, 7):
    ACCESS_DEFAULT = 0


_mmap = mmap

class mmap(_mmap):

    if version_info < (3, 9):

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

    if version_info < (3, 8):

        def madvise(self, option, start=0, length=None):
            cdef const unsigned char[:] buf = self
            cdef int buf_len = len(buf)
            cdef void *buf_p

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

        def flush(self, *args, **kwargs):
            value = super().flush(*args, **kwargs)
            return _transform_flush_return_value(value)

    if version_info < (3, 6):

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
    def _find(object self, r, int start, int end):
        cdef const unsigned char[:] buf = self
        cdef const unsigned char[:] needle = r
        cdef int buf_len = len(buf)
        cdef int needle_len = len(needle)
        cdef void *c
        cdef void *buf_p
        cdef void *needle_p

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

        with nogil:
            buf_p = &buf[start]
            needle_p = &needle[0]
            c = memmem(buf_p, end-start, needle_p, needle_len)

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
    def _rfind(object self, r, int start, int end):
        cdef const unsigned char[:] buf = self
        cdef const unsigned char[:] needle = r
        cdef int buf_len = len(buf)
        cdef int needle_len = len(needle)
        cdef void *c = NULL
        cdef void *buf_p
        cdef void *needle_p
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
            c = memrchr(buf_p, needle[0], i)
            while c:
                if memcmp(c, needle_p, needle_len) == 0:
                    break
                c = memrchr(buf_p, needle[0], c - buf_p)

        if c is NULL:
            return -1
        return c - buf_p + start

    #TODO:
    # - readline
    # - move?


del version_info
