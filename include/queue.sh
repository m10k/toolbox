#!/bin/bash

# queue.sh - Toolbox module for "thread"-safe queues
# Copyright (C) 2021-2022 Matthias Kruk
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

#
# This implementation defines a queue as a directory containing
# a set of objects for synchronization, and a list that contains
# the elements in the queue.
# The objects used for synchronization are a lock and a semaphore,
# as described by the following petri net.
#
#                 .-----.
#  .------------->| c00 |---------------.
#  |              '-----'               |
#  |                                    |
#  '---|   .-----.   |    .-----.   |<--'
#      |<--| c02 |<--|<---| c01 |<--|
#  .---|   '-----'   |<-. '-----'   |<--.
#  |                    |               |
#  |       .-----.      |            .-----.
#  '------>| mtx |------'            | sem |
#          |  1  |                   |  0  |
#  .-------|     |<------.           |     |
#  |       '-----'       |           '-----'
#  |                     |              ^
#  '-->|   .-----.    |--' .-----.   |--'
#      |-->| p01 |--->|--->| p02 |-->|
#  .-->|   '-----'    |    '-----'   |--.
#  |                                    |
#  |               .-----.              |
#  '---------------| p00 |<-------------'
#                  '-----'
#
# The states have the following meaning:
#
#  c00: Consumer wait on semaphore (start position)
#  c01: Consumer wait on mutex
#  c02: Consumer dequeue element, release mutex
#  p00: Producer wait on mutex (start position)
#  p01: Producer enqueue element, release mutex
#  p02: Producer post semaphore
#  mtx: The mutex (start value 1 / unlocked)
#  sem: The semaphore (start value 0)
#
# The queue is implemented as a directory like this:
#
#  queue/
#   |- mutex
#   |- sem
#   '- data
#
# Lock and sem may not actually be one filesystem object each
# (hint: they're not), but the queue implementation must not
# make any assumptions about this.
#
# In a nutshell, the queue can be used like this:
#
# if ! queue_init "myq"; then
#         # ERROR
# fi
#
# if ! queue_put "myq" "$data"; then
#         # ERROR
# fi
#
# if ! data=$(queue_get "myq"); then
#         # ERROR
# fi
#
# if ! queue_destroy "myq"; then
#         # ERROR
# fi
#

__init() {
	if ! include "log" "mutex" "sem"; then
		return 1
	fi

	declare -xgr __queue_path="$TOOLBOX_HOME/queue"

	if ! mkdir -p "$__queue_path"; then
		return 1
	fi

	return 0
}

_queue_get_path() {
	local queue="$1"

	if [[ "$queue" == *"/"* ]]; then
		echo "$queue"
	else
		echo "$__queue_path/$queue"
	fi
}

_queue_get_sem() {
	local queue="$1"

	local path

	path=$(_queue_get_path "$queue")
	echo "$path/sem"
}

_queue_get_mutex() {
	local queue="$1"

	local path

	path=$(_queue_get_path "$queue")
	echo "$path/mutex"
}

_queue_get_data() {
	local queue="$1"

	local path

	path=$(_queue_get_path "$queue")
	echo "$path/data"
}

queue_init() {
	local queue="$1"

	local path
	local sem

        path=$(_queue_get_path "$queue")
	sem=$(_queue_get_sem "$queue")

	if ! mkdir "$path" &> /dev/null; then
		return 1
	fi

	if ! sem_init "$sem" 0; then
		rmdir "$path" &> /dev/null
		return 1
	fi

	return 0
}

queue_destroy() {
	local queue="$1"

	local path
	local mutex
	local sem

	path=$(_queue_get_path "$queue")
	sem=$(_queue_get_sem "$queue")

	if ! sem_destroy "$sem"; then
		return 1
	fi

	if ! rm -rf "$path"; then
		return 1
	fi

	return 0
}

queue_put() {
	local queue="$1"
	local item="$2"

	local mutex
	local sem
	local data
	local err

	mutex=$(_queue_get_mutex "$queue")
	sem=$(_queue_get_sem "$queue")
	data=$(_queue_get_data "$queue")
	err=0

	mutex_lock "$mutex"

	if ! echo "$item" >> "$data"; then
		err=1
	fi

	mutex_unlock "$mutex"

	if (( err == 0 )); then
		if ! sem_post "$sem"; then
			err=1
		fi
	fi

	return "$err"
}

queue_get() {
	local queue="$1"
	local -i timeout="$2"

	local sem
	local mutex
	local data
	local item
	local err

	if (( $# < 2 )); then
		timeout=-1
	fi

	sem=$(_queue_get_sem "$queue")
	mutex=$(_queue_get_mutex "$queue")
	data=$(_queue_get_data "$queue")

	err=false

	if ! sem_wait "$sem" "$timeout"; then
		return 1
	fi

	mutex_lock "$mutex"

	if ! item=$(head -n 1 "$data" 2>/dev/null); then
		err=true
	else
		if ! sed -i '1d' "$data" &>/dev/null; then
			err=true
		fi
	fi

	mutex_unlock "$mutex"

	if "$err"; then
		return 1
	fi

	echo "$item"
	return 0
}

queue_foreach() {
	local name="$1"
	local func="$2"
	local args=("${@:3}")

	local data
	local mutex
	local item
	local err

	data=$(_queue_get_data "$name")
	mutex=$(_queue_get_mutex "$name")
	err=0

	if ! mutex_lock "$mutex"; then
		return 1
	fi

	if [ -f "$data" ]; then
		while read -r item; do
			if ! "$func" "$item" "${args[@]}"; then
				err=1
				break
			fi
		done < "$data"
	fi

	mutex_unlock "$mutex"

	return "$err"
}
