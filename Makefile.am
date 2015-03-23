SUBDIRS= include lib plugins src examples tex contrib doc

ACLOCAL_AMFLAGS = -I m4

EXTRA_DIST = build-aux/config.rpath fonts

dist-hook:
	-cp $(srcdir)Changelog.md > $(distdir)/ChangeLog
