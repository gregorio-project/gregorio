AM_CPPFLAGS = -I$(top_srcdir)/include -I$(top_srcdir)/lib
AM_CFLAGS =  -L$(top_srcdir)/lib

pkglib_LTLIBRARIES = gabc.la
gabc_la_LDFLAGS = -no-undefined -module -avoid-version

gabc_la_SOURCES = gabc-elements-determination.c gabc-write.c \
	gabc-glyphs-determination.c
nodist_gabc_la_SOURCES = gabc-score-determination-l.c \
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

CLEANFILES = gabc-score-determination-l.c gabc-score-determination-y.c \
	gabc-notes-determination-l.c gabc-score-determination-y.h

