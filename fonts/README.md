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

# Ancient notation fonts

The file [gregall.sfd](gregall.sfd) contains the images on which the author has drawn the fonts. The images come from:

- St. Gallen, Stiftsbibliothek (http://www.e-codices.unifr.ch)
- Einsiedeln, Stiftsbibliothek (http://www.e-codices.unifr.ch)

and are published here with the consent of these two institutions, which we thank. You can see the source for each glyph in [GregorioNabcRef](../doc/GregorioNabcRef.tex). Technically, this means that the font is looking precisely like these old codices, and that anyone wanting to improve/fork the font can resuse these images, at the condition to release his font under the [SIL Open Font License](http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=OFL).

# The case of Gregoria

Support for Gregoria has be dropped.

[Gregoria](http://www.anatoletype.net/projects/gregoria) cannot be used by Gregorio directly (although it was the primary goal of Gregorio when it was created). As the font is not free, it's not possible to use the same process as [caeciliae](http://marello.org/caeciliae/), because it would require to distribute a modified version.
