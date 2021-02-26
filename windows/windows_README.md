# Gregorio Windows files

This folder is dedicated to the windows installer. This file describes the steps to compile it.

### Building the gregorio executable

Building the `gregorio.exe` file cannot currently be made under Windows, but it is possible under Linux:

 * install [mingw](http://www.mingw.org/) (`aptitude install mingw32` under Debian)
 * run `./build.sh --mingw` in the main directory of the repository

This will create `src/gregorio.exe`.

**Note:** Currently the build script only supports building a 32-bit executable (using mingw32).  This package is not available by default on Ubuntu 16.04 or later.  Anyone willing to help us update the build script to use the 64-bit cross compilers that are readily available on more recent versions of Ubuntu (or other *nix distributions) is very much welcome.

### Building the installer

You need [InnoSetup](http://www.jrsoftware.org/isinfo.php) to be able to compile the installer. It runs fine under [Wine](https://www.winehq.org/). Once you have it installed: run InnoSetup.exe, open the `windows/gregorio.iss` file and compile it, it will produce `windows/Output/setup.exe`. You can also run it from command line: `wine 'C:\\Program Files (x86)\Inno Setup 5\ISCC.exe' gregorio.iss` in the `windows` directory (replace the `ISCC.exe` path with yours if different).

**Note:** If you're building the compiler on Ubuntu 14.04 (because of the above issue with mingw32) then you will need Inno Setup 5.x.  This is because the version of wine available on Ubuntu 14.04 emulates a version of Windows which is not compatible with Inno Setup 6.x.
