# Change Log
All notable changes to this project will be documented in this file.
This project does not currently adhere to [Semantic Versioning](http://semver.org/), but should one day.

## [Unreleased][unreleased]
### Changed
- Improved includescore with GregorioTeX API version checking (auto-compiling when possibly breaking Gregorio update).
- Clivis stem length now follow Solesme's books conventions.
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
- `\gremanualinitialwidth` macro to specify width of all initials.
- Virga aucta (for liquescent salicus), gabc `iv>`.
- Torculus liquescent deminutus and quilisma version, gabc `dfec~` and `dwfec~`.
- Pressus maior liquescens: `hof~`.
- Rare form of scandicus.
- Added `<c>` markup in gabc to denote a change of color.
- Added `<nlba>` markup in gabc to get areas with no line breaks.
- Added `<eu>` markup in gabc to delimit /E u o u a e/ areas (changes spaces slightly).
- Possibility to center translation syllable by syllable, see [here](https://www.mail-archive.com/gregorio-users@gna.org/msg01760.html) and [here](https://www.mail-archive.com/gregorio-users@gna.org/msg01783.html).
- Possibility not to scale spaces but specify them in units proportional to main text font (e.g. `em`).
