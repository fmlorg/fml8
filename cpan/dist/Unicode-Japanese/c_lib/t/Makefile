
TEST_FILES_BIN= \
 00_load   \
 01_new    \
 02_utf8   \
 03_sjis   \
 04_eucjp  \
 05_jis    \
 06_ucs2   \
 07_utf16
TEST_FILES=$(TEST_FILES_BIN:%=%.t)

CFLAGS=-I.. -Wall -Werror
LDFLAGS=-L..
LDLIBS=-lunijp

all: $(TEST_FILES_BIN)
$(TEST_FILES_BIN): ../libunijp.a

clean:
	rm $(TEST_FILES_BIN)

../libunijp.a:
	$(MAKE) -C ..

test: all
	prove *.t
#set -x; for f in $(TEST_FILES); do $(MAKE) $$f || break; eval "./$$f" || break; done

