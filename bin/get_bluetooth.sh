#!/bin/bash
# Exit 0 if the machine has a bluetooth adapter, 1 otherwise.

compgen -G "/sys/class/bluetooth/hci*" > /dev/null
