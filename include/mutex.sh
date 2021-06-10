#!/bin/bash

# mutex.sh - Toolbox module for pthreads-like mutexes
# Copyright (C) 2021 Matthias Kruk
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

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

	local -i remaining

	remaining="$timeout"

	while ! mutex_trylock "$lock"; do
		if (( timeout != 0 && --remaining < 0 )); then
			return 1
		fi

		sleep 1
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
