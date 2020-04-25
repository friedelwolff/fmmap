#!/usr/bin/env python

import mmap
import sys
import timeit

import fmmap


NUMBER=5


needle = sys.argv[1].encode('utf-8')


def find(m, needle=needle):
    return m.find(needle)


def rfind(m, needle=needle):
    return m.rfind(needle)


for name in sys.argv[2:]:
    with open(name, 'rb') as f:

        # built-in mmap
        with mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ) as m:
            a_find = find(m)
            print("mmap: find:", a_find)
            a1 = timeit.timeit('find(m)', number=NUMBER, globals={"m": m, "find": find})
            print(f"{a1:.3f}")
            a_rfind = rfind(m)
            print("mmap: rfind:", a_rfind)
            a2 = timeit.timeit('find(m)', number=NUMBER, globals={"m": m, "find": rfind})
            print(f"{a2:.3f}")

        # fmmap
        with fmmap.mmap(f.fileno(), 0, access=fmmap.ACCESS_READ) as m:
            b_find = find(m)
            print("fmmap: find:", a_find)
            b1 = timeit.timeit('find(m)', number=NUMBER, globals={"m": m, "find": find})
            print(f"{b1:.3f}")
            b_rfind = rfind(m)
            print("fmmap: rfind:", b_rfind)
            b2 = timeit.timeit('find(m)', number=NUMBER, globals={"m": m, "find": rfind})
            print(f"{b2:.3f}")

        if a_find != b_find:
            print("Results for find() differs!")
        if a_rfind != b_rfind:
            print("Results for rfind() differs!")

        print()
        print("Ratio mmap:fmmap (bigger than 1.0 means fmmap is faster)")
        print(f"find:  {a1/b1:2.2f}")
        print(f"rfind: {a2/b2:2.2f}")
