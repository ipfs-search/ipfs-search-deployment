#$!/bin/bash
set -e

BADGER="{{ badger_binary }}"
export IPFS_PATH="{{ ipfs_path }}"

echo "Cleaning repo:"
ipfs repo gc -q | wc -l
echo "items deleted"
ipfs repo stat -H
sleep 30
echo "Stat 30s later"
ipfs repo stat -H

echo "Stopping IPFS"
systemctl stop ipfs

echo "Flattening repo"
sudo -u {{ ipfs_user }} bash -c "ulimit -Sn 65536; $BADGER flatten --dir {{ ipfs_path }}/badgerds > /dev/null"

echo "Restarting IPFS"
systemctl start ipfs

echo "Starting dependant services"
systemctl list-dependencies --reverse --plain ipfs | sed -n "s/^  \(\S*\)\.service$/\1/p" | xargs systemctl start

ipfs repo stat -H
sleep 30
echo "Cleaning repo:"
ipfs repo gc -q | wc -l
echo "items deleted"
ipfs repo stat -H
sleep 5
echo "Synching disk buffers"
sync
sleep 5
echo "Trimming filesystems"
fstrim -a
