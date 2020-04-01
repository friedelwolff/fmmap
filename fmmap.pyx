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


_mmap = mmap

class mmap(_mmap):

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
    # - flush
    # - madvise
    # - rfind
    # - readline
    # - move?
    # - write:
    #   Changed in version 3.5: Writable bytes-like object is now accepted.
    #   Changed in version 3.6: The number of bytes written is now returned.
