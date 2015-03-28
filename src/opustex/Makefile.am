AM_CPPFLAGS = -I$(top_srcdir)/include
AM_CFLAGS =

noinst_LTLIBRARIES = opustex.la

opustex_la_SOURCES = opustex-write.c opustex.h
opustex_la_LDFLAGS = -no-undefined -module -avoid-version
opustex_la_LIBADD = $(LIBINTL)

