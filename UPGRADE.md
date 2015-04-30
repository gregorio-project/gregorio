# Upgrade Manual

This file contains instructions to upgrade to a new release of Gregorio.

##4.0
### Barred letters

If you are using barred letters in your document and if you use a font other than libertine, you must adjust the horizontal placement of the bar on the letter. To do so, use the `\gresimpledefbarglyph` macro. For example, use `\gresimpledefbarglyph{A}{0.3em}` in your preamble, tweaking the second argument to have a good result (same for R and V). See the documentation of `\gresimpledefbarglyph` in the PDF documentation for more details.

If you were using `\Vbarsmall`, `\greletterbar`, and `\greletteraltbar`, you must use `\gresimpledefbarglyph` to redefine your barred letters (see PDF documentation for details).

### .gtex extension

The `gregorio` executable now uses the `.gtex` extension by default (instead of `.tex`, formerly) for GregorioTeX files that it produces.  If you use `\includescore{file.tex}`, then you should change this to `\includescore{file.gtex}` or use the newer autocompilation feature.

## 3.0
### TeX Live 2013

Because of changes necessary to future-proof the fonts, please upgrade to at least TeX Live 2013 if you are using an older version.  If the neumes do not appear or look strange in the output, you may also need to clear your LuaTeX font cache by using `luaotfload-tool --cache=erase`.

### Score inclusion

When migrating to this release, you should start to use the new `\includescore` system, as other ways of score inclusion are deprecated and will start disapear soon. See GregorioRef.pdf for details.

#### For users of version 2.4.2

In version 2.4.2, an early version of the feature to auto-compile gabc score was added.  Because of the confusion this caused with old users upgrading to 2.4.2, the `\includescore` command now works in a backwards-compatible way so scores created using this command for versions of Gregorio prior than 2.4.2 should work with no change.  However, for users of 2.4.2, the following changes are necessary:

- If you were using `\includescore[f]`, the equivalent command is now `\includescore[n]`, but due to this change, you should be able to just use `\includescore` without the optional parameter.
- If you were using the auto-compile feature, you should use `\autocompilegabc` in your tex file prior to using `\includescore`.  This is only necessary once and **does not need to be used before each use** of `\includescore`.

### Custom dimension changes

If you use custom space definitions (`gsp-foo.tex`), the format have changed, and you must rewrite it completely. See the new `gsp-default.tex` for an example, and GregorioRef.pdf for documentation.

### Color definition

If you want to change color in gabc, using the `<c>` markup is the safest way, and you should migrate to that, as Gregorio introduced mechanisms that may break badly formatted color changes (e.g. `\color{red}foo\color{black}`).
