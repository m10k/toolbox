#!/bin/bash

#
# wmutex - weak mutex implementation for bash scripts
# Copyright (C) 2021 - Matthias Kruk <m@m10k.eu>
#

__init() {
	return 0
}

wmutex_trylock() {
	local lock="$1"

	if ! ln -s "$BASHPID" "$lock" &> /dev/null; then
		return 1
	fi

	return 0
}

wmutex_lock() {
	local lock="$1"
	local -i timeout="$2"

	local -i remaining

	remaining="$timeout"

	while ! wmutex_trylock "$lock"; do
		if (( timeout != 0 && --remaining < 0 )); then
			return 1
		fi

		sleep 1
	done

	return 0
}

wmutex_unlock() {
	local lock="$1"

	if ! rm "$lock"; then
		return 1
	fi

	return 0
}
