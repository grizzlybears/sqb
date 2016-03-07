#!/bin/bash

#must be compatible with 'test_run_qemu'
VmName=F23

echo "system_powerdown" | socat STDIN unix:dig_into/qmon_$VmName 


