#!/bin/sh

perl -e '$t=time - 30; print $t, "\n"' > /var/spool/ml/elena/var/event/queue/qmgr_reschedule


ls -l /var/spool/ml/elena/var/event/queue

head /var/spool/ml/elena/var/event/queue/*


