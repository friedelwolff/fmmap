===========================================================================
fmmap -- A fast implementation of mmap
===========================================================================

This module is a reimplementation of Python's builtin module mmap. It aims to
provide better performance while being API compatible with the builtin module.
Development tracks new Python versions, therefore this module is mostly usable
as a backport to older Python versions -- consult the documentation about any
changes to the mmap API in Python. You should be able to shadow the builtin
module and forget about it.

Install on the command line:

.. code:: shell

    pip install --upgrade fmmap

Import in Python under the name ``mmap``:

.. code:: python

    import fmmap as mmap

Memory mapping is a technique of providing access to a file by mapping it into
the virtual address space of the process and letting the operating system
handle the input and output instead of explicitely reading from or writing to
the file. It can provide better performance over normal file access in some
cases. The builtin mmap mobule in Python exposes this functionality, but some
of the implementation is not as fast as possible.

Summary of the project status:


The ``find()`` and ``rfind()`` functions in fmmap should be faster than the
version in the standard library. These two functions also release the global
interpreter lock (GIL) while searching, which might provide some benefit if
you have multithreaded code.

A number of features, bug fixes and API changes introduced in the standard
library between Python 3.5 - Python 3.9 are supported in fmmap when running on
older versions, notably:

- The API of ``flush()`` works like Python > 3.7.
- ``madvise()`` is implemented and most of the ``MADV_...`` constants are exposed.


Requirements and Assumptions
----------------------------

The following requirements are supported and tested:

- Python versions: 3.4, 3.5, 3.6, 3.7, 3.8.
- Interpreters: CPython.
- Operating systems: Linux, FreeBSD, NetBSD, OpenBSD.
  Most Unix type operating systems should work fine.

The speed improvements depend on the quality of implementation of certain
functions in your C library. Recent versions of glibc is known to be very good.
Other C libraries are not really tested, and the performance advantage over the
built-in module might be smaller.

The code of fmmap currently assumes that your platform has an ``madvise(2)``
implementation and has the header file <sys/mman.h>.


Credits and Resources
---------------------

The code and tests in this project are based on the standard library's `mmap`_
module. Additional tests from the pypy project are also duplicated here which
helped to identify a few bugs. Most functionality is just inherrited from the
current runtime. The rest is implemented in optimized Cython code.

.. _mmap: https://docs.python.org/3/library/mmap.html

Further readding on Wikipedia:

- `The mmap(2) system call <https://en.wikipedia.org/wiki/mmap>`__
- `Memory-mapped file <https://en.wikipedia.org/wiki/Memory-mapped_file>`__

Contributing
------------

1. Clone this repository (``git clone ...``)
2. Create a virtualenv
3. Install package dependencies: ``pip install --upgrade pytest tox``
4. Change some code
5. Run the tests: in the project root simply execute ``pytest``, and afterwards
   preferably ``tox`` to test the full test matrix. Consider installing as many
   supported interpreters as possible (having them in your ``PATH`` is often
   sufficient).
6. Submit a pull request and check for any errors reported by the Continuous
   Integration service.

License
-------

The MPL 2.0 License

Copyright (c) 2020 `Friedel Wolff <https://fwolff.net.za/>`_.
