# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# cython: language_level: 3

from mmap import *
import sys

import cython

cdef extern from *:
    #GNU extension to glibc
    void *memmem(const void *haystack, size_t haystacklen,
                 const void *needle, size_t needlelen) nogil


_transform_flush_return_value = lambda value: value


if sys.version_info < (3, 8):
    # We want to implement the return convention for flush() introduced in
    # Python 3.8. If we are running on an earlier version, let's massage the
    # return value:

    IF UNAME_SYSNAME == "Windows":
        from cpython.exc import PyErr_SetFromWindowsErr

        def _transform_flush_return_value(value):
            if value == 0:
                # error
                PyErr_SetFromWindowsErr(0)
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


if sys.version_info < (3, 7):
    ACCESS_DEFAULT = 0


_mmap = mmap

class mmap(_mmap):

    if sys.version_info < (3, 9):

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

    if sys.version_info < (3, 8):

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
                return -1

        def flush(self, *args, **kwargs):
            value = super().flush(*args, **kwargs)
            return _transform_flush_return_value(value)

    if sys.version_info < (3, 6):

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
        cdef int needle_len = len(r)
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
        
    #TODO:
    # - rfind
    # - readline
    # - move?
