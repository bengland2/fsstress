#!/bin/bash -x
# sort_by_op_type.sh - separates out each operation type in response time logs
# and generates stats for just that operation type
# input parameters:
#   target_dir - directory containing results of an fs-drift run
#   interval - time granularity for response-time-over-time table

target_dir=$1
interval=$2
NOTOK=1
rsptime_pctiles=./rsptime_stats.py
if [ -z "$interval" ] ; then
    echo "usage: sort_by_op_type.sh target-dir interval"
    exit $NOTOK
fi
if [ ! -f $target_dir/counters.json ] ; then
    echo "$target_dir is probably not an fs-drift directory"
    exit $NOTOK
fi
cd $target_dir
awk -F, '{ print $1 }' host-*_thrd-*_rsptimes.csv | sort -u > op.list
for op in `cat op.list` ; do mkdir -p rsptimes/op_$op ; done
for f in host-*_thrd-*_rsptimes.csv ; do 
    for op in `cat op.list` ; do
        # weed out any records whose op type has $op as suffix
        # example: random_read has read as suffix
        grep "$op," $f | grep -v "_$op," > rsptimes/op_$op/$f
    done
done
for op in `cat op.list` ; do
     $rsptime_pctiles --time-interval $interval rsptimes/op_$op
done

