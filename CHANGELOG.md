# Change Log
All notable changes to this project will be documented in this file.
As of v3.0.0 this project adheres to [Semantic Versioning](http://semver.org/). It follows [some conventions](http://keepachangelog.com/).


## 3.0.0-beta - 2015-03-15
### Changed
- Unify version numbers. The `gregoriotex_api_version` has been deprecated. The only version number is the gregorio release version. This simplifies the versioning process and should make bug reports easier to address.
- Distances in default space configuration (`gsp-default.tex`) have been changed so that they represent the actual printed dimension at the default staff size (see [#50](https://github.com/gregorio-project/gregorio/issues/50)).
- User settable distance names have been simplified by removing the `\gre` prefix.  See doc/UserManual.pdf section ?? for a full list of the distance names.
- Space configuration files (`gsp-xxx.tex`) have been reformated.  You now need to use `\gresetdim` for setting distances.  The TeX primitive notation (`\somedistance = 3cm`) can no longer be used.  `\gresetdim` takes three arguments: the name of the distance, the desired value, and whether the distance should scale with changes in the staff size or not.  See `gsp-default.tex` for an example.
- All distances can now be set to scale with staff size, as a consequence `\grechangedim` now takes three arguments: the name of the distance, value to change the distance to (which now supports em and ex units), and whether or not this value should be scaled with changes in the staff size.  See doc/UserManual.pdf section ?? for details.
- `\setinitalspacing` , `\setspacebeforeinitial`, `\setspaceafterinitial`, and `\setaboveinitialseparation` now take an additional argument.  The new argument specifies whether the distance should scale when the staff size changes.
- Improved `\includescore` capabilities.  See doc/UserManual.pdf section ?? for full details.
- Windows installer documentation updated
- Clivis stem length now follow Solesmes' books conventions (see [#31](https://github.com/gregorio-project/gregorio/issues/31)).
- TeXworks configuration script for Windows updated.  `greg-book` and `gregorio` engines will no longer be added since their functionality is considered Deprecated (see below).

### Fixed
- `\includescore` not finding files for autocompile under certain circumstances.  (see [this thread](http://www.mail-archive.com/gregorio-users@gna.org/msg02346.html))

### Added
- `\setstafflinethickness` controls the thickness of the staff lines.  See doc/UserManual.pdf section ?? for full details.
- `\gre@debug`.  Writes messages to the log file when the debug flag is set to true (can be done manually via `\debugtrue`, or via the `debug` option when loading the gregoriotex package in LaTeX).
- doc folder and beginnings of User Manual.  Only contains spaces documentation at this point.
- This CHANGELOG

### Deprecated
- `\includetexscore`, supplanted by `\includescore[n]`
- `\greincludetexscore`, supplanted by `\includescore[n]`
- `\includegabcscore`, supplanted by `\includescore[f]`
- `\greincludegabcscore`, supplanted by `\includescore[f]`
- `\GreSetSpaceBeforeInitial`, supplanted by `\setspacebeforeinitial`
- `\GreSetSpaceAfterInitial`, supplanted by `\setspaceafterinitial`
- `\GreSetAboveInitialSeparation`, supplanted by `\setaboveinitialseparation`
- `\gresetstafflinefactor`, supplanted by `\setstafflinethickness`
- `greg-book` and `greg-lily-book` engines, supplanted by improved capabilities of `\includescore` for compiling gabc files at time of document compilation.

## 2.4.3 - 2015-03-14 [YANKED]

## 2.4.2 - 2015-02-27
### Changed
- Improved `\includescore` with GregorioTeX API version checking (auto-compiling when possibly breaking Gregorio update).
- Clivis and pes quadratum alignment now follows Solesmes' conventions more closely (see [#10](https://github.com/gregorio-project/gregorio/issues/10)).

### Fixed
- Reducing horizontal episemus width.
- Reducing flat stem length.
- `mode` and `anotation-line` now do their job.
- Low episemus (`_0`) under consecutive notes are now aligned correctly.
- Quilisma was melting too much with next note when in a second.
- Fixed custo blocking possibility.
- Fixing glyphs disapearing when importing into Illustrator.

### Added
- English centering scheme now available as GregorioTeX option.
- `\setinitialspacing` to control all spaces related to initial with one command.
- `\gremanualinitialwidth` macro to specify width of all initials.
- Virga aucta (for liquescent salicus), gabc `iv>`.
- Torculus liquescent deminutus and quilisma version, gabc `dfec~` and `dwfec~`.
- Pressus maior liquescens: `hof~`.
- Rare form of scandicus.
- Added `<c>` markup in gabc to denote a change of color.
- Added `<nlba>` markup in gabc to get areas with no line breaks.
- Added `<eu>` markup in gabc to delimit _E u o u a e_ areas (changes spaces slightly).
- Possibility to center translation syllable by syllable, see [here](https://www.mail-archive.com/gregorio-users@gna.org/msg01760.html) and [here](https://www.mail-archive.com/gregorio-users@gna.org/msg01783.html).
- Possibility not to scale spaces but specify them in units proportional to main text font (e.g. `em`).
