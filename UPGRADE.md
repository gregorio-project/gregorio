# Upgrade Manual

This file contains instructions to upgrade to a new release of Gregorio.

##4.0
### Barred letters

If you are using barred letters in your document and if you use a font other than libertine, you must adjust the horizontal placement of the bar on the letter. To do so, use the `\gresimpledefbarglyph` macro. For example, use `\gresimpledefbarglyph{A}{0.3em}` in your preamble, tweaking the second argument to have a good result (same for R and V). See the documentation of `\gresimpledefbarglyph` in the PDF documentation for more details.

If you were using `\Vbarsmall`, `\greletterbar`, and `\greletteraltbar`, you must use `\gresimpledefbarglyph` to redefine your barred letters (see PDF documentation for details).

### .gtex extension

The `gregorio` executable now uses the `.gtex` extension by default (instead of `.tex`, formerly) for GregorioTeX files that it produces.  If you use `\includescore{file.tex}`, then you should change this to `\includescore{file.gtex}` or use the newer autocompilation feature.

### Custom spacings

If you are using custom spacings, please update the values of `interwordspacetext`, `intersyllablespacenotes` and `interwordspacenotes` to match their new definitions (in the comments in `gsp-default.tex`).

### Euouae blocks

You are advised to surround you *Euouae* blocks by the new `<eu>` tag. For instance, 

    E(i) u(i) o(i) u(h) a(h) e(fe..)

can become

    <eu>E(i) u(i) o(i) u(h) a(h) e</eu>(fe..)

This will prevent line breaking, so if you were using so called *no linebreak areas* (with `{` in gabc) just for Euouae blocks, you can switch to this new tag, it will make things clearer and allow further spacing customization.

### Horizontal episema improvements

Changes to the way the horizontal episema is placed and "bridged" to other notes within the syllable may cause Gregorio to render things differently in the more esoteric (or bug-ridden) cases.  If you are depending on the old behavior, you might need to add suffixes to the `_` in gabc to get what you want:

- Add `0` to force the episema to appear below the note.
- Add `1` to force the episema to appear above the note.
- Add `2` to prevent Gregorio from attempting to connect this episema to the next.
- Add `3` to use a small episema, aligned to the left of the note.
- Add `4` to use a small episema, centered in the middle of the note.
- Add `5` to use a small episema, aligned to the right of the note.

Note: `3`, `4`, and `5` encompass a new feature and are listed here only for completeness.

### Choral sign dimension renames

- `beforechoralsignspace` has been renamed to `beforelowchoralsignspace`.
- `lowchoralsignshift` has been renamed to `choralsigndownshift`.
- `highchoralsignshift` has been renamed to `choralsignupshift` and its sign inverted.

### Colored lines

Since `\grecoloredlines` now takes a named color as it's argument, if you were using it to custom color your lines, you must now define a named color using `\definecolor{yourcolorname}{RGB}{#,#,#}` and then pass that color to the command: `\grecoloredlines{yourcolorname}`.  The `\redlines` command continues to work as it did before, but will now respond to a change to `gregoriocolor` the way colored text does.

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
