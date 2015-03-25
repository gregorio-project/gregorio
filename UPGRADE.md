# Upgrade Manual

This file contains instructions to upgrade to a new release of Gregorio.

## 3.0
### Score inclusion

When migrating to this release, you should start to use the new `\includescore` system, as other ways of score inclusion are deprecated and will start disapear soon. See UserManual.pdf for details.

### Custom dimension changes

If you use custom space definitions (`gsp-foo.tex`), the format have changed, and you must rewrite it completely. See the new `gsp-default.tex` for an example, and UserManual.pdf for documentation.

### Color definition

If you want to change color in gabc, using the `<c>` markup is the safest way, and you should migrate to that, as Gregorio introduced mechanisms that may break badly formatted color changes (e.g. `\color{red}foo\color{black}`).
