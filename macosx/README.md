# Building a Mac OS X Package


To build the distribution package for Gregorio for Mac, you first need to install [Packages](http://s.sudre.free.fr/Software/Packages/about.html) and [Pandoc](johnmacfarlane.net/pandoc/index.html).  Once those are installed, simply run:

`create_pacakge.sh`

This script contains all the necessary commands to create the distribution package.  It will first build and "install" the package into the `macosx` directory (this way we know where everything is).  It will then use Pandoc to convert the necessary documentation files from markdown to ??? (the format required by Packages).  Once that's done, it will use the command line interface for Packages to build the installer package.

The distribution package is composed of several raw packages, each responsible for installing different things:

1. gregorio-base: This installs the command line tool and the GregorioTeX files.  These are the required components and must be installed.
2. examples: This installs the examples folder.  This is an optional install (installed by default).
3. contrib: This installs the contrib folder.  This is an optional install (installed by default).
4. documentation: This installs the documentation (doc folder).  This is an optional install (installed by default).

## Known Issues

It is problematic (to say the least) for a package installer to place files in a user's home directory on a Mac.  As a result, this installer will always target a systme-wide installation for both the command-line tool and TeXLive.

This installer is only targeted at Intel based Macs.
