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

echo "Listing services depending on ipfs"
DEPENDENTS=`systemctl list-dependencies --reverse --plain ipfs`

echo "Stopping IPFS"
systemctl stop ipfs

echo "Flattening repo"
sudo -u $IPFS_USER /usr/bin/prlimit --nofile=65536 --rss={{ ipfs_gc_memlimit }} $BADGER flatten --dir {{ ipfs_path }}/badgerds > /dev/null

echo "Starting IPFS"
systemctl start ipfs

echo "Starting dependent services"
systemctl start $DEPENDENTS

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

# Disable trimming too often.
# sleep 5
# echo "Trimming filesystems"
# fstrim -a
