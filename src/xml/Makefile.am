AM_CPPFLAGS = -I$(top_srcdir)/include
AM_CFLAGS =
xml_la_LIBADD = $(LIBINTL) $(XML_LIBS)
xml_la_SOURCES = xml-write.c xml-utils.c xml.h

if WITH_XML
xml_la_SOURCES += xml-read.c
endif

noinst_LTLIBRARIES = xml.la

xml_la_LDFLAGS = -no-undefined -module -avoid-version
