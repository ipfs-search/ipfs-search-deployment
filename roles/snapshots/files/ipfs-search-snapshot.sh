#!/bin/sh

curl -s -XPUT http://127.0.0.1:9200/_snapshot/ipfs/snapshot_`date +'%y%m%d-%H%M'` | jq -e '.accepted' > /dev/null
