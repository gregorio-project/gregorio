AM_CPPFLAGS=-I$(top_srcdir)/include -I$(top_srcdir)/lib
AM_CFLAGS=$(GLIB_CFLAGS) -L$(top_builddir)/lib

pkglib_LTLIBRARIES=skel.la
skel_la_SOURCES=skel.c
skel_la_LDFLAGS=-no-undefined -module -avoid-version
skel_la_LIBADD=$(GLIB_LIBS) $(LIBINTL) -lgregorio
