AM_CPPFLAGS = -I$(top_srcdir)/include
AM_CFLAGS =

noinst_LTLIBRARIES = gregoriotex.la

gregoriotex_la_SOURCES = gregoriotex-write.c gregoriotex.h
gregoriotex_la_LDFLAGS = -no-undefined -module -avoid-version
gregoriotex_la_LIBADD = $(LIBINTL)
