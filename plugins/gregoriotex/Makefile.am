AM_CPPFLAGS = -I$(top_srcdir)/include -I$(top_srcdir)/lib
AM_CFLAGS = -L$(top_builddir)/lib

if ALL_STATIC
noinst_LTLIBRARIES=gregoriotex.la
else
pkglib_LTLIBRARIES=gregoriotex.la
endif
gregoriotex_la_SOURCES=gregoriotex-write.c gregoriotex.h
gregoriotex_la_LDFLAGS=-no-undefined -module -avoid-version
gregoriotex_la_LIBADD = $(LIBINTL) -lgregorio
