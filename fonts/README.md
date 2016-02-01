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

# Stem length

Stem length are entirely configurable in gregorio, but are set during the time of font creation, so you cannot change it without modifying the font.

You can change stem length schema in a font when building it, by passing the `-sc` option to `squarize.py`, followed by the stem length schema you want your font to get. Currently available schemas are

- default, adapted from the 1934 Antiphonale Monasticum, see comments in [stemsschema.py](stemsschema.py) for more information
- solesmes, a schema provided by the Abbey of Solesmes

If you want a version of a font build with solesmes schema, or would like to see a new schema implemented, please contact the developpers.

# Ancient notation fonts

The file [gregall.sfd](gregall.sfd) contains the images on which the author has drawn the fonts. The images come from:

- St. Gallen, Stiftsbibliothek (http://www.e-codices.unifr.ch)
- Einsiedeln, Stiftsbibliothek (http://www.e-codices.unifr.ch)

and are published here with the consent of these two institutions, which we thank. You can see the source for each glyph in [GregorioNabcRef](../doc/GregorioNabcRef.tex). Anyone wanting to improve/fork the font can base on this file, at the condition to release the new font under the [SIL Open Font License](http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=OFL).

# The case of Gregoria

Support for Gregoria has been dropped.

[Gregoria](http://www.anatoletype.net/projects/gregoria) cannot be used by Gregorio directly (although it was the primary goal of Gregorio when it was created). As the font is not free, it's not possible to use the same process as [caeciliae](http://marello.org/caeciliae/), because it would require to distribute a modified version.
