#!/bin/sh
#
# $FML$
#

user=${FML_EMUL_USER:-fml}
group=${FML_EMUL_GROUP:-fml}
browser=${FML_EMUL_BROWSER:-w3m}
domain=${FML_EMUL_DOMAIN:-simulation.fml.org}

sudo chown -R $user:$group $HOME/public_html

$browser http://localhost/~$USER/cgi-bin/fml/$domain/admin/menu.cgi

exit 0
