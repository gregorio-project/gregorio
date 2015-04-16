# Change Log
All notable changes to this project will be documented in this file.
As of v3.0.0 this project adheres to [Semantic Versioning](http://semver.org/). It follows [some conventions](http://keepachangelog.com/).

## [Unreleased][unreleased]
### Fixed
- Handling of the first syllable in gabc is now more consistent with the all other syllables.  This centers the syllable correctly when using latin syllable centering (see [#42](https://github.com/gregorio-project/gregorio/issues/42)) and makes the use of styles less surprising in the first syllable (see [#135](https://github.com/gregorio-project/gregorio/issues/135)).

### Changed
- The `O` modifier in gabc now has expanded uses beyond the salicus `(egOi)`.  A stemmed oriscus will appear on a lone pitch `(gO)` or a followed by a lower pitch `(gOe)` (see [#76](https://github.com/gregorio-project/gregorio/issues/76)).  A virga strata will appear on the second note of two ascending pitches `(giO)`.

### Removed
- GregorioXML and OpusTeX output

## [3.0.0-rc2] - 2015-04-14
### Changed
- Clarified post installation options for Windows installer.  What was the "Install Fonts" option is now labeled to indicate that this also adds GregorioTeX files to the texmf tree.
- `\grechangedim` now checks to make sure it only operates on existing distances and doesn't create a new one.

### Fixed
- Windows post install script wasn't adding files to texmf tree.  Bug introduced by 3.0.0-rc1.
- Tarball distribution was missing `gregoriotex-chars.tex` file.
- Spacing between a syllable and a syllable with text and only a bar was too short.

## [3.0.0-rc1] - 2015-04-06
### Changed
- [New website](http://gregorio-project.github.io) containing instructions only for new versions of Gregorio starting with this release, in English only.
- New clean Mac OSX installer (intel only).
- New incompatible format of space configuration files (`gsp-xxx.tex`).  Values are now scaled to the default staff size (see [#50](https://github.com/gregorio-project/gregorio/issues/50).  You now need to use `\gresetdim` for setting distances (`\somedistance = 3cm`) can no longer be used).  `\gresetdim` takes three arguments: the name of the distance, the desired value, and whether the distance should scale with changes in the staff size or not.  See `gsp-default.tex` for an example.
- All distances can now be set to scale with staff size, as a consequence `\grechangedim` now takes three arguments: the name of the distance, value to change the distance to (which now supports em and ex units), and whether or not this value should be scaled with changes in the staff size.  See doc/UserManual.pdf for details.
- `\setinitalspacing` , `\setspacebeforeinitial`, `\setspaceafterinitial`, and `\setaboveinitialseparation` now take an additional argument.  The new argument specifies whether the distance should scale when the staff size changes.
- Improved `\includescore` capabilities.  The `\includescore[f]` parameter has changed to `\includescore[n]` compared to version 2.4.2.  See doc/UserManual.pdf for full details and UPGRADING.md for instructions on how to upgrade your score from 2.4.2.
- Clivis stem length now follow Solesmes' books conventions (see [#31](https://github.com/gregorio-project/gregorio/issues/31)).
- Windows TeXworks configuration script no longer adds deprecated `greg-book` and `gregorio` engines (see below).
- `build.sh` and `install.sh` scripts are now used to build and install Gregorio with common options.

### Fixed
- `\includescore` not finding files for autocompile under certain circumstances.  (see [this thread](http://www.mail-archive.com/gregorio-users@gna.org/msg02346.html)).

### Added
- `\setstafflinethickness` controls the thickness of the staff lines.  See GregorioRef.pdf for full details.
- `\gre@debug`.  Writes messages to the log file when the debug flag is set to true (can be done manually via `\debugtrue`, or via the `debug` option when loading the gregoriotex package in LaTeX).
- New documentation in PDF: GregorioRef.pdf. You can find it in the [release files](https://github.com/gregorio-project/gregorio/releases).
- A migration guide ([UPGRADE.md](UPGRADE.md))
- This CHANGELOG.

### Deprecated
- OpusTeX writing and GregorioXML reading and writing features will disappear in next minor release
- The [old website](http://home.gna.org/gregorio/) contains instructions for old versions of Gregorio only, and will not be updated anymore.
- the `-O` option
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
- Quilisma was melting too much with next note when in a second interval.
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
- Possibility to center translation syllable by syllable, see [here](https://www.mail-archive.com/gregorio-users@gna.org/msg01760.html) and [here](https://www.mail-archive.com/gregorio-users@gna.org/msg01783.html).

## 2.0 - 2010-09-27
### Changed
- gregorio API changed and GregorioTeX macros prepended with `\gre`, to avoid potential name conflicts
- updated greciliae font
- fine-tuning the spacing, and making it easier for users to change the defaults
- GregorioXML reading is now optional (via `--enable-xml-read` flag)

### Fixed
- as always, fixing a lot of bugs

### Added
- Automatic Windows installer
- adding requested features: Dominican bars, choral signs, text above staff lines
- enabling comments in gabc files
- adding ability to write verbatim TeX at {note, glyph, element} level
- introducing horizontal episemus bridges
- default output is now utf8 directly; the `-O`  option allows old-style TeX output, i.e. `\char XXXX`
- new static build system for packaged distributions


## 1.0 - 2009-10-19
### Changed
- changing the number of arguments of some TeX function
- changing the glyph names
- improving the spacings
- better management of the penalty in TeX so that the line changes are more consistent
- changing the markup system in gabc to be more natural

### Fixed
- fixing a lot of bugs

### Added
- adding the possibility to put a flat after the clef
- adding the possibility to put a custo before a clef change


## 0.9.2 - 2008-12-27
### Changed
- changing the number of arguments of some TeX function
- changing the glyph names

### Fixed
- fixing a lot of bugs

### Added
- LuaTeX additional functionalities


## 0.9.1 - 2008-11-23
### Changed
- changing the number of arguments of some TeX functions

### Fixed
- fixing a lot of small bugs


## 0.9 - 2008-07-25
### Changed
- stabilizing the TeX API

### Added
- adding support for Cygwin compilation
- adding too many new features to be listed


## 0.3 - 2008-01-18
### Changed
- changing the architecture of libraries and plugins

### Added
- adding support for end of lines
- adding support for compilation on MAC OSX

     
## 0.2.2 - 2007-06-14
### Added
- adding styles and centering in text
