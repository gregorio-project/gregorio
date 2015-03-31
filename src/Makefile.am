AM_CPPFLAGS = -I$(top_srcdir)/src -I$(top_srcdir)/src/gabc  -I$(top_srcdir)/src/dump  -I$(top_srcdir)/src/gregoriotex
AM_CFLAGS =

bin_PROGRAMS = gregorio
gregorio_SOURCES = characters.c gregorio-utils.c messages.c struct.c \
				   unicode.c struct.h messages.h unicode.h characters.h \
				   plugins.h dump/dump.c dump/dump.h gregoriotex/gregoriotex-write.c \
				   gregoriotex/gregoriotex.h

# Windows resources (see windows/README.md)
.rc.o:
	$(RC) $(RCFLAGS) $< -o $@

if HAVE_RC
gregorio_SOURCES += ../windows/gregorio-resources.rc
endif

# gabc files
gregorio_SOURCES += gabc/gabc-elements-determination.c gabc/gabc-write.c \
					gabc/gabc-glyphs-determination.c gabc/gabc.h \
					gabc/gabc-score-determination.h
nodist_gregorio_SOURCES = gabc/gabc-score-determination-l.c \
						 gabc/gabc-notes-determination-l.c \
						 gabc/gabc-score-determination-l.h \
						 gabc/gabc-score-determination-y.c \
						 gabc/gabc-score-determination-y.h
gregorio_LDADD = @LEXLIB@

EXTRA_DIST = gabc/gabc-score-determination.l gabc/gabc-score-determination.y \
			 gabc/gabc-notes-determination.l

gabc/gabc-score-determination-l.o: gabc/gabc-score-determination-l.c \
								   gabc/gabc-score-determination.h \
								   gabc/gabc-score-determination-y.h

gabc/gabc-score-determination-l.h: gabc/gabc-score-determination-l.c
gabc/gabc-score-determination-l.c: gabc/gabc-score-determination.l
	$(LEX) -o $@ --header-file=gabc/gabc-score-determination-l.h $<

gabc/gabc-score-determination-y.o: gabc/gabc-score-determination-y.c \
								   gabc/gabc-score-determination.h \
								   gabc/gabc-score-determination-l.h

gabc/gabc-score-determination-y.h: gabc/gabc-score-determination-y.c
gabc/gabc-score-determination-y.c: gabc/gabc-score-determination.y
	$(YACC) -d -p "gabc_score_determination_" -o $@ $<

gabc/gabc-notes-determination-l.c: gabc/gabc-notes-determination.l
	$(LEX) -o $@ $<

CLEANFILES = gabc/gabc-score-determination-l.c \
			 gabc/gabc-notes-determination-l.c \
			 gabc/gabc-score-determination-l.h \
			 gabc/gabc-score-determination-y.c \
			 gabc/gabc-score-determination-y.h
