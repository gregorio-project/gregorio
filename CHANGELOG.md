# Change Log
All notable changes to this project will be documented in this file.
As of v3.0.0 this project adheres to [Semantic Versioning](http://semver.org/). It follows [some conventions](http://keepachangelog.com/).


## 3.0.0-beta - 2015-03-15
### Changed
- New incompatible format of space configuration files (`gsp-xxx.tex`).  Values are now scaled to the default staff size (see [#50](https://github.com/gregorio-project/gregorio/issues/50).  You now need to use `\gresetdim` for setting distances (`\somedistance = 3cm`) can no longer be used).  `\gresetdim` takes three arguments: the name of the distance, the desired value, and whether the distance should scale with changes in the staff size or not.  See `gsp-default.tex` for an example.
- All distances can now be set to scale with staff size, as a consequence `\grechangedim` now takes three arguments: the name of the distance, value to change the distance to (which now supports em and ex units), and whether or not this value should be scaled with changes in the staff size.  See doc/UserManual.pdf for details.
- `\setinitalspacing` , `\setspacebeforeinitial`, `\setspaceafterinitial`, and `\setaboveinitialseparation` now take an additional argument.  The new argument specifies whether the distance should scale when the staff size changes.
- Improved `\includescore` capabilities.  See doc/UserManual.pdf for full details.
- Clivis stem length now follow Solesmes' books conventions (see [#31](https://github.com/gregorio-project/gregorio/issues/31)).
- Windows TeXworks configuration script no longer adds deprecated `greg-book` and `gregorio` engines (see below).

### Fixed
- `\includescore` not finding files for autocompile under certain circumstances.  (see [this thread](http://www.mail-archive.com/gregorio-users@gna.org/msg02346.html)).

### Added
- `\setstafflinethickness` controls the thickness of the staff lines.  See doc/UserManual.pdf for full details.
- `\gre@debug`.  Writes messages to the log file when the debug flag is set to true (can be done manually via `\debugtrue`, or via the `debug` option when loading the gregoriotex package in LaTeX).
- doc folder and beginnings of User Manual.  Only contains spaces documentation at this point.
- This CHANGELOG.

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
