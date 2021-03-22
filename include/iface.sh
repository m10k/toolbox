#!/bin/bash

__init() {
	return 0
}

iface_exists() {
	local iface

	iface="$1"

	if grep -F "$iface" < /proc/net/dev &> /dev/null; then
		return 0
	fi

	return 1
}

iface_get_state() {
	local iface
	local state

	iface="$1"

	if ! state=$(ip link show "$iface" 2>/dev/null); then
		return 1
	fi

	if ! state=$(echo "$state" | grep -oP "state[ ]+\K[^ ]+"); then
		return 1
	fi

	case "$state" in
		"UP")
			echo "1"
			;;

		"DOWN")
			echo "0"
			;;

		*)
			return 1
			;;
	esac

	return 0
}

iface_set_state() {
	local iface
	local state

	iface="$1"
	state="$2"

	case "$state" in
		"0")
			state="down"
			;;

		"1")
			state="up"
			;;

		*)
			return 1
			;;
	esac

	if ! /sbin/ifconfig "$iface" "$state" &>/dev/null; then
		return 1
	fi

	return 0
}

iface_get_address() {
        local iface
        local proto

        local addr_all

        iface="$1"
        proto="$2"

        if ! addr_all=$(ip address show dev "$iface"); then
                return 1
        fi

        if ! echo "$addr_all" | grep -oP "$proto[ \t]+\K[^ ]+"; then
                return 1
        fi

        return 0
}

iface_get_essid() {
        local iface
        local addr_all

        iface="$1"

        if ! addr_all=$(/sbin/iwconfig 2>&1); then
                return 1
        fi

        if ! echo "$addr_all" | grep -oP "$iface.*ESSID:\"\K[^\"]+"; then
                return 1
        fi

        return 0
}
