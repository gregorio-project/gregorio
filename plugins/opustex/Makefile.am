AM_CPPFLAGS=-I$(top_srcdir)/include -I$(top_srcdir)/lib
AM_CFLAGS =  -L$(top_srcdir)/lib

pkglib_LTLIBRARIES=opustex.la
opustex_la_SOURCES=opustex-write.c
opustex_la_LDFLAGS=-no-undefined -module -avoid-version
opustex_la_LIBADD = -lgregorio
