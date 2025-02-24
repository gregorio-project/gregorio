# Gregorio Windows files

This folder is dedicated to the windows installer. This file describes the steps to compile it.

## Building the gregorio executable

### Linux Hosts

While building the executable under Windows should be possible, none of the current developers build it that way, so we are unable to provide the exact steps required to do so.

Building under Linux worked when the mingw32 package was available using the following instructions:

 * install mingw32 (`aptitude install mingw32` under Debian)
 * run `./build.sh --mingw` in the main directory of the repository

However, the mingw32 package has not been available in the package repositories for several years (for Ubuntu, the 14.04 repositories are the most recent to contain it).  The more recent mingw-w64 package is the appropriate replacement, but as of yet we have not confirmed that it works.

### macOS Hosts

Building under macOS is possible using the following steps:

 - install [mingw-w64](https://mingw-w64.sourceforge.net/) using MacPorts: `port install mingw-w6` (most likely requires `sudo`)
 - run `./build.sh` in the main directory of the repository to build the native Mac binaries first (this is needed because some intermediate build steps require running files that have been built in earlier steps)
 - run `./build.sh --mingw` in the same directory to build the windows executable

This will create `src/gregorio-<version number>.exe`

### Building the installer

You need [InnoSetup](http://www.jrsoftware.org/isinfo.php) to be able to compile the installer. It runs fine under [Wine](https://www.winehq.org/). Once you have it installed: run InnoSetup.exe, open the `windows/gregorio.iss` file and compile it, it will produce `windows/Output/mysetup.exe`. You can also run it from command line: `wine 'C:\\Program Files (x86)\Inno Setup 6\ISCC.exe' gregorio.iss` in the `windows` directory (replace the `ISCC.exe` path with yours if different).

**Note:** If you're building the compiler on Ubuntu 14.04 (because of the above issue with mingw32) then you will need Inno Setup 5.x (which is installed to `C:\\Program Files (x86)\Inno Setup 5\` by default).  This is because the version of wine available on Ubuntu 14.04 emulates a version of Windows which is not compatible with Inno Setup 6.x.
