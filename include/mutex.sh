#!/bin/bash

#
# mutex - pthreads-like mutex implementation for bash scripts
# Copyright (C) 2021 - Matthias Kruk <m@m10k.eu>
#

__init() {
	return 0
}

mutex_trylock() {
	local lock

	lock="$1"

	if ! ln -s "$$" "$lock" &> /dev/null; then
		return 1
	fi

	return 0
}

mutex_lock() {
	local lock

	lock="$1"

	while ! mutex_trylock "$lock"; do
		if ! inotifywait -qq "${lock%/*}"; then
			return 1
		fi
	done

	return 0
}

mutex_unlock() {
	local lock
	local owner

	lock="$1"

	if ! owner=$(readlink "$lock" 2> /dev/null); then
		return 1
	fi

	if [ "$owner" -ne "$$" ]; then
		return 2
	fi

	if ! rm -f "$lock"; then
		return 3
	fi

	return 0
}
