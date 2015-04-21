# Font generation

Gregorio uses .ttf fonts to for the chant. They are built in the distributed tarballs, but if you really need to compile them:
 * install [fontforge](http://fontforge.github.io) with python extension
 * run `make fonts` in this directory (using the `-j` argument can save you some time here)
 * then you can test them directly, or install them (see next section)

# Font installation

Fonts are installed with the usual process:
 * `install-gtex.sh` if you're under OSX or GNU/Linux
 * copy in `C:\Windows\Fonts` under Windows

The most important is that they must be found by [fontconfig](http://www.freedesktop.org/wiki/Software/fontconfig/).

# The case of Gregoria

Support for Gregoria has be dropped.

[Gregoria](http://www.anatoletype.net/projects/gregoria) cannot be used by Gregorio directly (although it was the primary goal of Gregorio when it was created). As the font is not free, it's not possible to use the same process as [caeciliae](http://marello.org/caeciliae/), because it would require to distribute a modified version.
