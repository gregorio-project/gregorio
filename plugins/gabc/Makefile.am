AM_CPPFLAGS = -I$(top_srcdir)/include -I$(top_srcdir)/lib
AM_CFLAGS = -L$(top_builddir)/lib

if ALL_STATIC
noinst_LTLIBRARIES=gabc.la
else
pkglib_LTLIBRARIES=gabc.la
endif
gabc_la_LDFLAGS = -no-undefined -module -avoid-version

gabc_la_SOURCES = gabc-elements-determination.c gabc-write.c \
	gabc-glyphs-determination.c gabc.h gabc-score-determination-l.h \
	gabc-score-determination-l.c  gabc-score-determination-y.h \
	gabc-notes-determination-l.c gabc-score-determination-y.c
gabc_la_LIBADD = @LEXLIB@ $(LIBINTL) -lgregorio

EXTRA_DIST=gabc-score-determination.l gabc-score-determination.y \
	gabc-notes-determination.l

gabc-score-determination-l.c: gabc-score-determination.l gabc-score-determination-y.c
	$(LEX) -C $<

gabc-score-determination-y.c: gabc-score-determination.y
	$(YACC) -d -p "gabc_score_determination_" -o $@ $<

gabc-notes-determination-l.c: gabc-notes-determination.l
	$(LEX) $<

%-y.h: %-y.c
%-l.h: %-l.c

CLEANFILES = gabc-score-determination-l.c gabc-score-determination-y.c \
	gabc-notes-determination-l.c gabc-score-determination-y.h

