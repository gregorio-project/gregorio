AM_CPPFLAGS=-I$(top_srcdir)/include -DLOCALEDIR=\"$(localedir)\"

bin_PROGRAMS=gregorio
gregorio_SOURCES=dump.c gregorio-utils.c struct-utils.c xml-write.c \
	gabc-elements-determination.c gabc-write.c messages.c \
	xml-read.c gabc-glyphs-determination.c gregoriotex-write.c \
	opustex-write.c xml-utils.c
nodist_gregorio_SOURCES=gabc-score-determination-l.c \
	gabc-notes-determination-l.c gabc-score-determination-y.c
gregorio_LDADD=@LEXLIB@ $(LIBINTL)

EXTRA_DIST=gabc-score-determination.l gabc-score-determination.y \
	gabc-notes-determination.l

gabc-score-determination-l.c: gabc-score-determination.l gabc-score-determination-y.c
	$(LEX) -o $@ -C --header-file="gabc-score-determination-l.h" \
	     --prefix="gabc_score_determination_" $<

gabc-score-determination-y.c: gabc-score-determination.y
	$(YACC) -d -p "gabc_score_determination_" -o $@ $<

gabc-notes-determination-l.c: gabc-notes-determination.l
	$(LEX) -o $@ --prefix="gabc_notes_determination_" $<

CLEANFILES=gabc-score-determination-l.c gabc-score-determination-y.c \
	gabc-notes-determination-l.c gabc-score-determination-l.h \
	gabc-score-determination-y.h
