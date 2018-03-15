#!/bin/bash

set +x
  eval "cat <<EOF
$(</home/vagrant/maxscale-performance-test/maxscale.cnf.template)
" 2> /dev/null > maxscale.cnf


export scpopt_node="-i ${node_000_keyfile} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ConnectTimeout=120 "
export sshopt_node="$scpopt ${node_000_whoami}@${node_000_network}"

echo "stop slave; change master to MASTER_HOST='${node_000_network}', MASTER_PORT=3301, MASTER_USER='repl', MASTER_PASSWORD='repl', MASTER_USE_GTID=slave_pos; start slave;"| mysql -uskysql -pskysql -h ${node_000_network} -P 3302

export scpopt="-i ${maxscale_keyfile} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ConnectTimeout=120 "
export sshopt="$scpopt ${maxscale_whoami}@${maxscale_network}"

scp $scpopt maxscale.cnf ${maxscale_whoami}@${maxscale_network}:~/

scp $scpopt /home/vagrant/maxscale-performance-test/run_sysbench.sh ${maxscale_whoami}@${maxscale_network}:~/
ssh $sshopt "sudo cp /home/${maxscale_whoami}/maxscale.cnf /etc/"

ssh $sshopt "sudo service maxscale start"

echo "drop database test;" | mysql -uskysql -pskysql -h $maxscale_network -P 4006
echo "create database test;" | mysql -uskysql -pskysql -h $maxscale_network -P 4006

ssh $sshopt "chmod a+x ./run_sysbench.sh"
ssh $sshopt "./run_sysbench.sh"

