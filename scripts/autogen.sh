#!/bin/sh

if [ ! -d m4 ]; then
	mkdir m4
fi

aclocal-1.14 -I m4
autoconf
autoheader
libtoolize --copy --force
automake-1.14 --add-missing --copy

exit 0