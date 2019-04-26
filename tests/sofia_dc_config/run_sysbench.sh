#!/bin/bash

#sysbench  --test=/usr/share/sysbench/oltp_read_write.lua\
#         --db-driver=mysql  --mysql-db=test --mysql-user=skysql --mysql-password=skysql \
#         --mysql-port=4006 --mysql-host=127.0.0.1  prepare
#sysbench  --test=/usr/share/sysbench/oltp_read_write.lua\
#         --threads=${sysbench_threads} \
#         --mysql-host=127.0.0.1 --mysql-port=4006 --mysql-user=skysql --mysql-password=skysql \
#         --db-driver=mysql  --mysql-db=test   \
#         --max-requests=0  --time=1200 run



SYSBENCH=sysbench-mariadb
PS_MODE=disable
LUA=oltp.lua
POINTSEL=1000
CREATEDB=1
WARMUP=1
ENGINE=InnoDB
TABLES=10
TOTAL_ROWS=100000
RUNTIME=${perf_runtime}
REPORT=2
EXTRATIME=0

node_000_network="172.20.3.1"
node_000_whoami="perf"
node_000_keyfile="/home/perf/.ssh/id_rsa"

ROWS=$(($TOTAL_ROWS / $TABLES))
NUMACTL="numactl --interleave=all"

WORKLOAD="--test=/home/perf/lua/oltp_modulo.lua --oltp-read-only=on --write-mask=0 --oltp_point_selects=1000 --oltp_simple_ranges=0 --oltp_sum_ranges=0 --oltp_order_ranges=0 --oltp_distinct_ranges=0"
#WORKLOAD="--test=/home/ubuntu/lua/oltp_modulo.lua --oltp-read-only=on --write-mask=0 --oltp_point_selects=1000 --oltp_simple_ranges=0 --oltp_sum_ranges=0 --oltp_order_ranges=0 --oltp_distinct_ranges=0"


CONNECTION="--mysql-host=127.0.0.1 --mysql-port=4006 --mysql-user=skysql --mysql-password=skysql"
CONNECTION_MYSQL="-h 127.0.0.1 -P 4006 -uskysql -pskysql"
echo "********* conns:"
echo $CONNECTION
echo $CONNECTION_MYSQL

set -x
#scp -i ${node_000_keyfile} ~/.config/performance-test/set_mariadb_cpu_affinity.sh ${node_000_whoami}@${node_000_network}:~/
ssh -i ${node_000_keyfile} ${node_000_whoami}@${node_000_network} ./set_mariadb_cpu_affinity.sh
set +x

echo "create database sbtest" | mysql $CONNECTION_MYSQL
#$NUMACTL 
maxscale_pid=`pgrep maxscale`
sudo taskset -p 0x0f $maxscale_pid
sysbench $WORKLOAD --db-ps-mode=$PS_MODE --oltp_tables_count=$TABLES --oltp-table-size=$ROWS --threads=${sysbench_threads}  $CONNECTION prepare
#sysbench $WORKLOAD --threads=${sysbench_threads}  $CONNECTION prepare

if [ ${use_callgrind} == "yes" ] ; then
    sudo service maxscale stop
    sudo --user=maxscale valgrind -d --log-file=/var/log/maxscale/valgrind.log --trace-children=yes --tool=callgrind --callgrind-out-file=/var/log/maxscale/callgrind.log /usr/bin/maxscale
fi
#echo taskset 0xf0 sysbench $WORKLOAD --db-ps-mode=$PS_MODE --oltp_tables_count=$TABLES --oltp-table-size=$ROWS --threads=${sysbench_threads} --report-interval=$REPORT --max-time=$RUNTIME --max-requests=0 $CONNECTION run 
taskset 0xf0 sysbench $WORKLOAD --db-ps-mode=$PS_MODE --oltp_tables_count=$TABLES --oltp-table-size=$ROWS --threads=${sysbench_threads} --report-interval=$REPORT --max-time=$RUNTIME --max-requests=0 --mysql-host=127.0.0.1 --mysql-port=${perf_port} --mysql-user=skysql --mysql-password=skysql run 
#sysbench $WORKLOAD --threads=${sysbench_threads} --report-interval=$REPORT --max-time=$RUNTIME --max-requests=0 $CONNECTION run 
if [ ${use_callgrind} == "yes" ] ; then
    sudo kill $(pidof valgrind)
fi

