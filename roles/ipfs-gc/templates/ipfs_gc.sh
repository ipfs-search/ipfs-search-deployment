#$!/bin/bash
set -x -e

BADGER="{{ badger_binary }}"
export IPFS_PATH="{{ ipfs_path }}"
systemctl stop ipfs {{ ipfs_dependant_services }}
sudo -u {{ ipfs_user }} bash -c "ulimit -Sn 65536; $BADGER flatten --dir {{ ipfs_path }}/badgerds"
systemctl start ipfs {{ ipfs_dependant_services }}
sleep 30
echo "Cleaning repo:"
ipfs repo gc -q | wc -l
echo "items deleted"
ipfs repo stat -H
sleep 30
echo "Cleaning repo again:"
ipfs repo gc -q | wc -l
echo "items deleted"
ipfs repo stat -H
sleep 5
sync
sleep 5
fstrim -a
