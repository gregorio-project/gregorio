# Supplamental Fonts

In addition to the default font, Greciliae, there are two fully featured supplamental fonts:

 * Gregorio, the original font produced as part of this project
 * Grana Padano, an adaptation of Parmesan from [Lilypond](http://www.lilypond.org/index.html)

Like Greciliae, each of these fonts comes with separate file for solid, hollow, and hole glyphs (holes are the "filling" in a hollow glyph which prevent an object behind the hollow glyph from showing through).

Also like Greciliae, each file also has an "-op" variant in which certain glyph shapes are tweaked to be more like the shapes found in specifically Dominican chant collections.

## Font installation

The Lua script `install_supp_fonts.lua` can be used to install Gregorio and Grana Padano.  To use this script, open Terminal (or Command Prompt, if you are on Windows), change to this directory, and then run `texlua install_supp_fonts.lua`.  This command can take an argument indicating where you want the fonts to go:

 * `auto` (optional): the same folder as Greciliae
 * `system`: the appropriate font folder in `$TEXMFLOCAL`
 * `user`: the appropriate font folder in `$TEXMFHOME`
 * `<dir>`: the name of an alternate texmf root directory you want to use
 
**Note:** The script assumes you only need to access the fonts from within a TeX document.  If you want to use the fonts in other programs, then you will need to consult the documentation appropriate to your platform and manually move, copy, or link the fonts to the necessary location.

