#!/bin/sh

. `dirname $0`/config.sh

exec mysql -h $host -u $user --password="$password" $database
