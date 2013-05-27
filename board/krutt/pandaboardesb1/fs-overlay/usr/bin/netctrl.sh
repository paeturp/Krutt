#!/bin/sh
#
#
#
ip link set eth0 up

udhcpc -a -q -n -i eth0


