#!/bin/sh
#
# $FML$
#

file=$1

dir=` dirname $file `
test -d $dir || mkdir -p $dir

class=` echo $file | sed s/.pm// | sed s@/@::@g `

if [ ! -f $file ];then
   sed s/__MODULE_NAME__/$class/g @template.pm > $file
else
   echo "***error: $file is already exists"
fi

exit 0
