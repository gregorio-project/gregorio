AM_CPPFLAGS=-I$(top_srcdir)/plugins -I$(top_srcdir)/include

lib_LTLIBRARIES=libgregorio.la
libgregorio_la_SOURCES = struct.c messages.c
libgregorio_la_LDFLAGS=-no-undefined
libgregorio_la_LIBADD = $(LIBINTL)
pkginclude_HEADERS = struct.h messages.h
