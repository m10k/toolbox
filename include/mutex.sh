#!/bin/bash

#
# mutex - pthreads-like mutex implementation for bash scripts
# Copyright (C) 2021 - Matthias Kruk <m@m10k.eu>
#

__init() {
	return 0
}

mutex_trylock() {
	local lock="$1"

	if ! ln -s "$BASHPID" "$lock" &> /dev/null; then
		return 1
	fi

	return 0
}

mutex_lock() {
	local lock="$1"
	local -i timeout="$2"

	while ! mutex_trylock "$lock"; do
		# We can't inotifywait on symlinks. Which is
		# fine because when the symlink is removed, the
		# containing directory is changed. Hence, we can
		# watch the containing directory instead.

		if ! inotifywait -qq "${lock%/*}" -t "$timeout"; then
			return 1
		fi
	done

	return 0
}

mutex_unlock() {
	local lock="$1"

	local owner

	if ! owner=$(readlink "$lock" 2> /dev/null); then
		return 1
	fi

	if (( owner != BASHPID )); then
		return 2
	fi

	if ! rm "$lock"; then
		return 3
	fi

	return 0
}
