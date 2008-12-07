AM_CPPFLAGS=-I$(top_srcdir)/include
AM_CFLAGS=$(GLIB_CFLAGS)

lib_LTLIBRARIES=libgregorio.la
libgregorio_la_SOURCES = struct.c messages.c plugin_loader.c unicode.c characters.c
libgregorio_la_LDFLAGS=-no-undefined \
	-version-info $(LIBGREGORIO_CURRENT):$(LIBGREGORIO_REVISION):$(LIBGREGORIO_AGE)
libgregorio_la_LIBADD = $(GLIB_LIBS) $(LIBINTL) $(LIBTOOL_LIB)

EXTRA_DIST=gregorio.pc.in

pkgconfigdir=$(libdir)/pkgconfig
pkgconfig_DATA=gregorio.pc
