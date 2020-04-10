import fmmap as mmap


def test_off_by_one():
    m = mmap.mmap(-1, 10)
    m.write(b"jj________")
    m.seek(0)
    assert m.find(b"jj") == 0
    assert m.rfind(b"jj") == 0
