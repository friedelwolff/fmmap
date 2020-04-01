===========================================================================
fmmap -- A fast implementation of mmap
===========================================================================

This module is a reimplementation of Python's builtin module mmap. It aims to
provide better performance while being API compatible with the builtin module.

.. code:: python

    import fmmap as mmap

Memory mapping is a technique of providing access to a file by mapping it into
the virtual address space of the function and letting the operating system
handle the input and output instead of explicitely reading from or writing to
the file. It can provide better performance over normal file access in some
cases. The builtin mmap mobule in Python exposes this functionality, but some
of the implementation is not as fast as possible.

Summary of the project status:

Currently only the `find()` function is improved over the
version in the standard library. More might follow, and contributions are
welcome.


Installation and usage
----------------------

The following requirements are supported and tested in all reasonable
combinations:

- Python versions: 3.7, 3.8.
- Interpreters: CPython.

.. code:: shell

    pip install --upgrade fmmap


Credits and Resources
---------------------

The code and tests in this project are based on the standard library's `mmap`_
module. Additional tests from the pypy project is also duplicated here that
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
