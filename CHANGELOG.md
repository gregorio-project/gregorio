# Change Log
All notable changes to this project will be documented in this file.
This project does not currently adhere to [Semantic Versioning](http://semver.org/), but should one day.


## [Unrelased][ongoing]
### Changed

### Fixed

### Added


## 2.4.3 - 2015-03-14
### Changed
- Temporary distance registers systematized
- `\setinitalspacing` now takes four arguments.  New arguments specifies value for `\gre@scale@...` for the three distances.
- User settable distances now have `\gre@scale@...` property which determines if they scale or not when `\grefactor` changes.  Property is controlled by `\gresetdim`, `\grechangedim`, `\grenoscaledim`, and `\grescaledim`
- `\grechangedim` updated to reflect string storage of distances
- User settable distances now stored as strings (see #50)
- `\gre@stafflinefactor` now uses same scale as `\grefactor`
- Improved `\includescore` to remove outdated files ([#61](https://github.com/gregorio-project/gregorio/issues/61)).
- TeXworks configuration script for Windows updated
- Windows installer documentation updated
- Clivis stem length now follow Solesme's books conventions (see [#31](https://github.com/gregorio-project/gregorio/issues/31)).
- Space Configuration Loading code refactored
- Most distance calculations disentangled so that each calculate functions do not call each other (helps to avoid circularity)
- `\grefactor` is now initialized at 17 (the default value).  Necessitated that most distances be rescaled (see [#50](https://github.com/gregorio-project/gregorio/issues/50)).
- Distances renamed to `\gre@...`  Functions which calculate distances renamed to `\gre@calculate@...`
- All code which defines or calculates a space (and nothing else) now reside in gregoriotex-spaces.tex

### Fixed
- Fixed deprecated code in autoconfig.ac (see [#57](https://github.com/gregorio-project/gregorio/issues/57)).
- `\includescore` not finding files for autocompile under certain circumstances.

### Added
- `\gre@debug`.  Enables the printing of debug messages with debug flag is set to true (can be done manually via `\debugtrue`, or via the `debug` option when loading the gregoriotex package in LaTeX)
- doc folder and beginnings of User Manual.  Only contains spaces documentation at this point.
- `\setstafflinethickness` changes the thickness of the staff lines
- Distances now set with `\gresetdim`
- This CHANGELOG

### Deprecated
- `\GreSetSpaceBeforeInitial`, supplanted by `\setspacebeforeinitial`
- `\GreSetSpaceAfterInitial`, supplanted by `\setspaceafterinitial`
- `\GreSetAboveInitialSeparation`, supplanted by `\setaboveinitialseparation`
- `\gresetstafflinefactor`, supplanted by `\setstafflinethickness`

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
