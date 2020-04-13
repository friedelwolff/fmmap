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
