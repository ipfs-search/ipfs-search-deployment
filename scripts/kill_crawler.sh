#!/bin/sh -e

while true
do
	echo "Press [CTRL+C] to stop.."
	ansible -b -m systemd -a 'name=ipfs state=stopped' 'index:!scale_out'
	ansible -b -m systemd -a 'name=tika-extractor state=stopped' 'index:!scale_out'
	ansible -b -m systemd -a 'name=ipfs-crawler state=stopped' 'index:!scale_out'
	sleep 300
done
