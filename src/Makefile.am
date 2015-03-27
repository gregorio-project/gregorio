AM_CPPFLAGS=-I$(top_srcdir)/include -I$(top_srcdir)/lib -I$(top_srcdir)/plugins -DLOCALEDIR=\"$(localedir)\" -DPLUGINDIR=\"$(libdir)/gregorio\"
AM_CFLAGS=

.rc.o:
	$(RC) $(RCFLAGS) $< -o $@

bin_PROGRAMS=gregorio
if HAVE_RC
gregorio_SOURCES=gregorio-utils.c  ../windows/gregorio-resources.rc
else
gregorio_SOURCES=gregorio-utils.c
endif
gregorio_LDADD=$(LIBINTL) $(LIBTOOL_LIB) ../lib/libgregorio.la
if ALL_STATIC
gregorio_LDADD+= ../plugins/dump/dump.la ../plugins/opustex/opustex.la ../plugins/gregoriotex/gregoriotex.la ../plugins/gabc/gabc.la ../plugins/xml/xml.la
endif
