AM_CPPFLAGS=-I$(top_srcdir)/include -I$(top_srcdir)/lib
AM_CFLAGS = -L$(top_builddir)/lib $(XML_CFLAGS)
xml_la_LIBADD = $(LIBINTL) $(XML_LIBS) -lgregorio
xml_la_SOURCES=xml-write.c xml-utils.c xml.h

if WITH_XML
xml_la_SOURCES+=xml-read.c
endif

if ALL_STATIC
noinst_LTLIBRARIES=xml.la
else
pkglib_LTLIBRARIES=xml.la
endif

xml_la_LDFLAGS=-no-undefined -module -avoid-version
