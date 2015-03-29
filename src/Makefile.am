SUBDIRS = dump gregoriotex gabc

AM_CPPFLAGS = -I$(top_srcdir)/src
AM_CFLAGS =

.rc.o:
	$(RC) $(RCFLAGS) $< -o $@

bin_PROGRAMS = gregorio
gregorio_SOURCES = characters.c gregorio-utils.c messages.c struct.c \
				   unicode.c struct.h messages.h unicode.h characters.h \
				   plugins.h

if HAVE_RC
gregorio_SOURCES += ../windows/gregorio-resources.rc
endif
gregorio_LDADD = $(LIBINTL) $(LIBTOOL_LIB) dump/dump.la \
				 gregoriotex/gregoriotex.la gabc/gabc.la
