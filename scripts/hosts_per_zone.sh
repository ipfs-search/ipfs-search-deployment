#!/bin/sh

ansible-inventory --list | jq -r '._meta.hostvars | to_entries[] | select(.value.hrobot_product == "AX61-NVMe") | [.key, .value.zone_id] | @csv'
