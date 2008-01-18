AM_CPPFLAGS = -I$(top_srcdir)/include -I$(top_srcdir)/lib
AM_CFLAGS =  -L$(top_srcdir)/lib

pkglib_LTLIBRARIES=dump.la
dump_la_SOURCES=dump.c
dump_la_LDFLAGS=-no-undefined -module -avoid-version
dump_la_LIBADD = -lgregorio
