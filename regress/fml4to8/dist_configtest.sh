#!/bin/sh
#
# $FML: dist_configtest.sh,v 1.2 2004/12/29 04:33:10 fukachan Exp $
#

dist_base_dir=`mktemp -d /tmp/configtest.XXXX`

cd `dirname $0`/../.. || exit 1

# prepare sources to distribute.
tar --exclude=CVS -cf - fml/lib/FML/Merge fml/etc/compat |\
tar -C $dist_base_dir -xpvf -

cp regress/fml4to8/configtest.pl $dist_base_dir
chmod 755 $dist_base_dir/configtest.pl
mv $dist_base_dir/configtest.pl $dist_base_dir/test

# install documents.
cp regress/fml4to8/00_TEST.jp    $dist_base_dir/00_README.jp

# generate tarball.
cd $dist_base_dir || exit 1
cd .. || exit 1

date=`date +%Y%m%d`
suffix=$date.$$
test -d fml4to8test-$date && mv fml4to8test-$date fml4to8test-$date.$suffix
mv $dist_base_dir fml4to8test-$date
tar cvf fml4to8test-$date.tar fml4to8test-$date
gzip -9 -v -f fml4to8test-$date.tar

exit 0
