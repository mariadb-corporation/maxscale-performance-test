sysbench  --test=/usr/share/sysbench/oltp_read_write.lua\
         --db-driver=mysql  --mysql-db=test --mysql-user=skysql --mysql-password=skysql \
         --mysql-port=4006 --mysql-host=127.0.0.1  prepare
sysbench  --test=/usr/share/sysbench/oltp_read_write.lua\
         --mysql-host=127.0.0.1 --mysql-port=4006 --mysql-user=skysql --mysql-password=skysql \
         --db-driver=mysql  --mysql-db=test   \
         --threads=32  \
         --max-requests=0  --time=60 run
