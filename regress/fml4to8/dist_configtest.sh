#!/bin/sh
#
# $FML$
#

dist_base_dir=`mktemp -d /tmp/configtest.XXXX`

cd `dirname $0`/../.. || exit 1

tar --exclude=CVS -cf - fml/lib/FML/Merge fml/etc/compat |\
tar -C $dist_base_dir -xpvf -

cp regress/fml4to8/configtest.pl $dist_base_dir
chmod 755 $dist_base_dir/configtest.pl

cd $dist_base_dir || exit 1
cd .. || exit 1

date=`date +%Y%m%d`
mv $dist_base_dir fml4to8test-$date
tar cvf fml4to8test-$date.tar fml4to8test-$date
gzip -9 -v fml4to8test-$date.tar

exit 0
