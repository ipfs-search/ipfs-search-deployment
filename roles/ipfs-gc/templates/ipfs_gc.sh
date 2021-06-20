#$!/bin/bash
set -e

BADGER="{{ badger_binary }}"
IPFS_USER="{{ ipfs_user }}"
IPFS="sudo -u $IPFS_USER -E ipfs"
export IPFS_PATH="{{ ipfs_path }}"

echo "Repo stat:"
$IPFS repo stat -H

echo "Garbage-collecting repo:"
DELETED=`$IPFS repo gc -q | wc -l`
echo "$DELETED items deleted"

echo "Repo stat:"
$IPFS repo stat -H

echo "Stopping IPFS"
systemctl stop ipfs

echo "Flattening repo"
sudo -u $IPFS_USER bash -c "ulimit -Sn 65536; $BADGER flatten --dir {{ ipfs_path }}/badgerds > /dev/null"

echo "Starting IPFS"
systemctl start ipfs

echo "Starting dependant services"
systemctl list-dependencies --reverse --plain ipfs | sed -n "s/^  \(\S*\)\.service$/\1/p" | xargs systemctl start

echo "Repo stat:"
$IPFS repo stat -H

echo "Garbage-collecting repo:"
DELETED=`$IPFS repo gc -q | wc -l`
echo "$DELETED items deleted"

sleep 30

echo "Repo stat:"
$IPFS repo stat -H

sleep 5
echo "Synching disk buffers"
sync
sleep 5
echo "Trimming filesystems"
fstrim -a
