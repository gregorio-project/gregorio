AM_CFLAGS = -Wall
AM_CFLAGS += --std=c99
AM_CFLAGS += -Wunused
AM_CFLAGS += -Wno-unused-parameter
AM_CFLAGS += -Wdeclaration-after-statement
AM_CFLAGS += -Wmissing-prototypes
AM_CFLAGS += -Wmissing-declarations
AM_CFLAGS += -Wextra
AM_CFLAGS += -Wshadow
AM_CFLAGS += -Wcast-align
AM_CFLAGS += -Wsign-compare
AM_CFLAGS += -Wundef
AM_CFLAGS += -Wuninitialized
AM_CFLAGS += -Winit-self
AM_CFLAGS += -Wpointer-arith
AM_CFLAGS += -Wredundant-decls
## this warning complains with gettext
##AM_CFLAGS += -Wformat-nonliteral
AM_CFLAGS += -Wno-format-zero-length
AM_CFLAGS += -Wmissing-format-attribute

gregorio_CPPFLAGS=-I$(top_srcdir)/include -I$(top_srcdir)/lib -I$(top_srcdir)/plugins -DLOCALEDIR=\"$(localedir)\" -DPLUGINDIR=\"$(libdir)/gregorio\"

bin_PROGRAMS=gregorio
gregorio_SOURCES=gregorio-utils.c
gregorio_LDADD=$(LIBINTL) $(LIBTOOL_LIB) ../lib/libgregorio.la
