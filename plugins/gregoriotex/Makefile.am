AM_CPPFLAGS = -I$(top_srcdir)/include -I$(top_srcdir)/lib
AM_CFLAGS =  -L$(top_srcdir)/lib

pkglib_LTLIBRARIES=gregoriotex.la
gregoriotex_la_SOURCES=gregoriotex-write.c
gregoriotex_la_LDFLAGS=-no-undefined -module -avoid-version
gregoriotex_la_LIBADD = $(LIBINTL) -lgregorio
