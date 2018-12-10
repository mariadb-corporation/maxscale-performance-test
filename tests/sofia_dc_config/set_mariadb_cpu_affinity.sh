set -x
echo "Stopping mysqld which was started by package installation script"
sudo service mysql stop

masks=(0x03 0x0C 0x30 0xC0)
pids=`pgrep mysql`
i=0
for pid in $pids
do
    echo "taskset for $pid set to ${masks[i]}"
    sudo taskset -p ${masks[i]} $pid
    ((i++))
done
set +x
