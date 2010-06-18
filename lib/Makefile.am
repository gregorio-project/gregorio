AM_CPPFLAGS=-I$(top_srcdir)/include
EXTRA_DIST=gregorio.pc.in

if ALL_STATIC
noinst_LTLIBRARIES=libgregorio.la
else
pkglib_LTLIBRARIES=libgregorio.la
endif
libgregorio_la_SOURCES = struct.c messages.c unicode.c characters.c
libgregorio_la_LDFLAGS = -no-undefined
if ALL_STATIC
else
libgregorio_la_SOURCES += plugin_loader.c
libgregorio_la_LDFLAGS += -version-info $(LIBGREGORIO_CURRENT):$(LIBGREGORIO_REVISION):$(LIBGREGORIO_AGE)
endif
libgregorio_la_LIBADD= $(LIBINTL) $(LIBTOOL_LIB)

pkgconfigdir=$(libdir)/pkgconfig
pkgconfig_DATA=gregorio.pc
