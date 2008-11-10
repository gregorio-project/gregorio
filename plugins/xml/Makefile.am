AM_CPPFLAGS=-I$(top_srcdir)/include -I$(top_srcdir)/lib
xml_la_CFLAGS = $(XML_CFLAGS) -L$(top_builddir)/lib
xml_la_LIBADD = $(LIBINTL) $(XML_LIBS) -lgregorio

pkglib_LTLIBRARIES=xml.la
pkginclude_HEADERS = xml.h
xml_la_SOURCES=xml-read.c xml-write.c xml-utils.c
xml_la_LDFLAGS=-no-undefined -module -avoid-version
