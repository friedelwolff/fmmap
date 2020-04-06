# Always prefer setuptools over distutils
from setuptools import setup, find_packages
from distutils.extension import Extension
from os import path
# io.open is needed for projects that support Python 2.7
# It ensures open() defaults to text mode with universal newlines,
# and accepts an argument to specify the text encoding
# Python 3 only projects can skip this import
from io import open


try:
    from Cython.Build import cythonize
    USE_CYTHON = True
except ImportError:
    USE_CYTHON = False

ext = '.pyx' if USE_CYTHON else '.c'
extensions = [Extension("fmmap", ["fmmap"+ext])]

if USE_CYTHON:
    from Cython.Build import cythonize
    extensions = cythonize(extensions)


here = path.abspath(path.dirname(__file__))

# Get the long description from the README file
with open(path.join(here, 'README.rst'), encoding='utf-8') as f:
    long_description = f.read()


setup(
    name='fmmap',
    version='0.2.0',
    description='A fast reimplementation of mmap',
    long_description=long_description,
    author='Friedel Wolff',
    author_email='friedel@translate.org.za',

    # For a list of valid classifiers, see https://pypi.org/classifiers/
    classifiers=[  # Optional
        #   5 - Production/Stable
        'Development Status :: 4 - Beta',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: Mozilla Public License 2.0 (MPL 2.0)',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
    ],

    # Note that this is a string of words separated by whitespace, not a list.
    keywords='mmap',
    #ext_modules=cythonize("fmmap.pyx"),
    ext_modules=extensions,
    #cmdclass={'build_ext': Cython.Build.new_build_ext},

    # Specify which Python versions you support. In contrast to the
    # 'Programming Language' classifiers above, 'pip install' will check this
    # and refuse to install the project if the version does not match. If you
    # do not support Python 2, you can simplify this to '>=3.5' or similar, see
    # https://packaging.python.org/guides/distributing-packages-using-setuptools/#python-requires
    python_requires='>=3.4, <4',

    # List additional groups of dependencies here (e.g. development
    # dependencies). Users will be able to install these using the "extras"
    # syntax, for example:
    #
    #   $ pip install sampleproject[dev]
    #
    # Similar to `install_requires` above, these must be valid existing
    # projects.
    extras_require={  # Optional
        'dev': ['check-manifest'],
        'test': ['coverage'],
    },

    url='https://github.com/friedelwolff/fmmap/',
    # This field corresponds to the "Project-URL" metadata fields:
    # https://packaging.python.org/specifications/core-metadata/#project-url-multiple-use
    project_urls={
        'Bug Reports': 'https://github.com/friedelwolff/fmmap/issues',
        'Source': 'https://github.com/friedelwolff/fmmap/',
    },
)
