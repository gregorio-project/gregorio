AM_CPPFLAGS = -I$(top_srcdir)/src -I$(top_srcdir)/src/gabc  -I$(top_srcdir)/src/dump  -I$(top_srcdir)/src/gregoriotex
AM_CFLAGS =

bin_PROGRAMS = gregorio
gregorio_SOURCES = characters.c gregorio-utils.c messages.c struct.c \
				   unicode.c struct.h messages.h unicode.h characters.h \
				   plugins.h config.h dump/dump.c dump/dump.h \
				   gregoriotex/gregoriotex-write.c gregoriotex/gregoriotex.h

@MK@ifneq ($(wildcard ../.git),)
@MK@  _branch_ = $(shell git rev-parse --abbrev-ref HEAD)
@MK@  ifneq ($(_branch_),master)
@MK@    DEFS += -DBRANCH_VERSION='"b$(_branch_)-$(shell date +%Y%m%d_%H%m)-$(shell git rev-parse --short HEAD)"'
@MK@  endif
@MK@else
@MK@  ifneq ($(wildcard ../.hg/git),)
@MK@    _branch_ = $(shell cat ../.hg/bookmarks.current)
@MK@    ifneq ($(_branch_),master)
@MK@      DEFS += -DBRANCH_VERSION='"b$(shell git --git-dir=../.hg/git rev-parse --abbrev-ref '$(_branch_)')-$(shell date +%Y%m%d_%H%m)-$(shell git --git-dir=../.hg/git rev-parse --short '$(_branch_)')"'
@MK@    endif
@MK@  endif
@MK@endif

if HAVE_RC
# Windows resources (see windows/README.md)
.rc.o:
	$(RC) $(RCFLAGS) $< -o $@

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
