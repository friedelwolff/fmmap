import sys

import pytest

import fmmap as mmap


def test_off_by_one():
    m = mmap.mmap(-1, 10)
    m.write(b"jj________")
    m.seek(0)
    assert m.find(b"jj") == 0
    assert m.rfind(b"jj") == 0


def test_needle_too_big():
    m = mmap.mmap(-1, 10)
    m.write(b"jj________")
    m.seek(0)
    assert m.find(b"abc", 9) == -1
    assert m.rfind(b"abc", 9) == -1


def test_clean_namespace():
    # We shouldn't soil the module namespace with our own extras
    assert getattr(mmap, "version_info", None) is None
    assert getattr(mmap, "kernel", None) is None
    assert getattr(mmap, "OS", None) is None
    assert getattr(mmap, "uname", None) is None


@pytest.mark.skipif(not sys.platform.startswith("linux"), reason="Linux only")
def test_linux_constants():
    assert getattr(mmap, "MADV_DONTFORK") > 0
    assert getattr(mmap, "MADV_REMOVE") > 0


@pytest.mark.skipif(not sys.platform.startswith("freebsd"), reason="FreeBSD only")
def test_freebsd_constants():
    assert getattr(mmap, "MADV_FREE") > 0
    assert getattr(mmap, "MADV_NOSYNC") > 0


@pytest.mark.skipif(not sys.platform.startswith("openbsd"), reason="OpenBSD only")
def test_openbsd_constants():
    assert getattr(mmap, "MADV_FREE") > 0
    assert getattr(mmap, "MADV_SPACEAVAIL") > 0
