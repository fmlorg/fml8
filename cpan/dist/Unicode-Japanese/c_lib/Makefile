
PERL=perl
CC=gcc
OPTIMIZE=-g
CFLAGS=-I. $(OPTIMIZE) -Wall -Werror -fPIC
AR=ar
LDFLAGS=-L.
LDLIBS=-lunijp

POD2MAN=pod2man
MLPOD2POD=mlpod2pod

MAPS= \
  ea2u1  \
  ea2u2  \
  ea2u2s \
  ea2u1s \
  ed2u   \
  ei2u1  \
  ei2u2  \
  ej2u1  \
  ej2u2  \
  eu2a1  \
  eu2a2  \
  eu2a2s \
  eu2a1s \
  eu2d   \
  eu2i1  \
  eu2i2  \
  eu2j1  \
  eu2j2  \
  s2u    \
  u2s

TABLE_SRCS=$(MAPS:%=table_%.c)
TABLE_OBJS=$(TABLE_SRCS:%.c=%.o)
UNIJP_OBJS= \
  unijp.o alloc.o charcode.o conv.o xs_compat.o \
  getcode.o getcode_map.o \
  any_to_utf8.o utf8.o utf8_to_any.o \
  sjis.o chk_sjis.o eucjp.o jis.o \
  ucs2.o ucs4.o utf16.o
OBJS=$(TABLE_OBJS) $(UNIJP_OBJS)

DESTDIR=
PREFIX=/usr/local
LIB_DIR=$(PREFIX)/lib
INCLUDE_DIR=$(PREFIX)/include
MANDIR=$(PREFIX)/man
MAN3DIR=$(MANDIR)/man3

all: libunijp.a ujconv ujguess sample libunijp.3 libunijp.en.3

test:
	$(MAKE) -C t test

install: all
	mkdir -p $(DESTDIR)$(LIB_DIR)
	mkdir -p $(DESTDIR)$(INCLUDE_DIR)
	mkdir -p $(DESTDIR)$(MAN3DIR)
	install libunijp.a      $(DESTDIR)$(LIB_DIR)/
	install unijp.h         $(DESTDIR)$(INCLUDE_DIR)/
	install unijp_int.h     $(DESTDIR)$(INCLUDE_DIR)/
	install unijp_types.h   $(DESTDIR)$(INCLUDE_DIR)/
	install unijp_version.h $(DESTDIR)$(INCLUDE_DIR)/
	install libunijp.3      $(DESTDIR)$(MAN3DIR)/
	install libunijp.en.3   $(DESTDIR)$(MAN3DIR)/

clean:
	rm -rf *.o wordsize libunijp.a ujconv ujguess
	rm -f libunijp.3    libunijp.pod
	rm -f libunijp.en.3 libunijp.en.pod


libunijp.a: unijp_version.h unijp_int.h $(OBJS)
	$(AR) r $@ $(OBJS)


ujconv:  ujconv.o  libunijp.a
	$(CC) $(LDFLAGS) ujconv.o  $(LDLIBS) -o $@
ujguess: ujguess.o libunijp.a
	$(CC) $(LDFLAGS) ujguess.o $(LDLIBS) -o $@
sample: sample.o libunijp.a
	$(CC) $(LDFLAGS) sample.o $(LDLIBS) -o $@


libunijp.3: libunijp.pod
	$(POD2MAN) --section 3 libunijp.pod $@
libunijp.pod: libunijp.mlpod
	$(MLPOD2POD) --langs=ja libunijp.mlpod | iconv -f utf-8 -t euc-jp > $@

libunijp.en.3: libunijp.en.pod
	$(POD2MAN) --section 3 libunijp.en.pod $@
libunijp.en.pod: libunijp.mlpod
	$(MLPOD2POD) --langs=en libunijp.mlpod | iconv -f utf-8 -t euc-jp > $@

unijp_version.h unijp_int.h: ../lib/Unicode/Japanese.pm autogen.pl
	$(MAKE) autogen
autogen:
	$(MAKE) wordsize
	$(PERL) autogen.pl
wordsize: ../wordsize.c
	$(CC) $(CFLAGS) ../wordsize.c -o $@


