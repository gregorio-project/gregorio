AM_CPPFLAGS=-I$(top_srcdir)/include -I$(top_srcdir)/lib -I$(top_srcdir)/plugins -DLOCALEDIR=\"$(localedir)\" -DPLUGINDIR=\"$(libdir)/gregorio\"
AM_CFLAGS=

bin_PROGRAMS=gregorio
gregorio_SOURCES=gregorio-utils.c
gregorio_LDADD=$(LIBINTL) $(LIBTOOL_LIB) ../lib/libgregorio.la
