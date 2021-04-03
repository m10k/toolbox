#!/bin/bash

__init() {
	return 0
}

net_iface_exists() {
	local iface

	iface="$1"

	if grep -F "$iface" < /proc/net/dev &> /dev/null; then
		return 0
	fi

	return 1
}

net_iface_get_state() {
	local iface
	local state

	iface="$1"

	if ! state=$(ip link show "$iface" 2>/dev/null); then
		return 1
	fi

	if ! state=$(echo "$state" | grep -oP 'state[ ]+\K[^ ]+'); then
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

net_iface_set_state() {
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

net_iface_get_address() {
	local iface
	local proto

        local addr_all

        iface="$1"
        proto="$2"

        if ! addr_all=$(ip address show dev "$iface"); then
                return 1
        fi

        if ! echo "$addr_all" | grep -oP "${proto}[ \\t]+\\K[^ ]+"; then
                return 1
        fi

        return 0
}

net_iface_get_essid() {
        local iface
        local addr_all

        iface="$1"

        if ! addr_all=$(/sbin/iwconfig 2>&1); then
                return 1
        fi

        if ! echo "$addr_all" | grep -oP "$iface.*ESSID:\"\\K[^\"]+"; then
                return 1
        fi

        return 0
}

_net_iface_parse_iwlist() {
	local regex_ssid='Cell [0-9]+ - Address: ([0-9A-Fa-f:]+)'
	local regex_signal='Quality=([0-9/]+)'
	local regex_essid='ESSID:"(.*)"'

        local line
        local ssid
        local essid
        local strength

        while read -r line; do
                if [[ "$line" =~ $regex_ssid ]]; then
                        #start of a new network
                        ssid="${BASH_REMATCH[1]}"
                        essid=""
                        strength=""
                elif [[ "$line" =~ $regex_signal ]]; then
                        strength="${BASH_REMATCH[1]}"
                elif [[ "$line" =~ $regex_essid ]]; then
                        essid="${BASH_REMATCH[1]}"
                fi

                if [ -n "$ssid" ] && [ -n "$essid" ] && [ -n "$strength" ]; then
                        echo "$ssid $strength $essid"
			ssid=""
                fi
        done
}

net_iface_scan() {
	local iface
	local raw

	iface="$1"

	if ! raw=$(iwlist "$iface" scan 2>&1); then
		return 1
	fi

	echo "$raw" | _iface_parse_iwlist
	return 0
}
