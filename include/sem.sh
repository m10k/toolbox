#!/bin/bash

# sem.sh - Toolbox module for POSIX-like semaphores
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
	if ! include "is" "mutex" "wmutex" "log"; then
		return 1
	fi

	declare -xgr __sem_path="$TOOLBOX_HOME/sem"

	if ! mkdir -p "$__sem_path"; then
		return 1
	fi

	return 0
}

_sem_get_path() {
	local sem="$1"

	if [[ "$sem" == *"/"* ]]; then
		echo "$sem"
	else
		echo "$__sem_path/$sem"
	fi
}

_sem_get_waitlock() {
	local sem="$1"

	echo "$(_sem_get_path "$sem")/waitlock"
}

_sem_get_countlock() {
	local sem="$1"

	echo "$(_sem_get_path "$sem")/countlock"
}

_sem_get_owner() {
	local sem="$1"

	echo "$(_sem_get_path "$sem")/owner"
}

_sem_get_counter() {
	local sem="$1"

	echo "$(_sem_get_path "$sem")/counter"
}

_sem_counter_inc() {
	local sem="$1"

	local value

	if ! value=$(< "$sem"); then
		return 1
	fi

	((++value))

	if ! echo "$value" > "$sem"; then
		return 1
	fi

	return 0
}

_sem_counter_dec() {
	local sem="$1"

	local value

	if ! value=$(< "$sem"); then
		return 1
	fi

	if (( --value < 0 )); then
		return 1
	fi

	if ! echo "$value" > "$sem"; then
		return 1
	fi

	return 0
}

sem_init() {
	local name="$1"
	local value="$2"

	local sem
	local waitlock
	local countlock
	local counter
	local owner
	local err

	err=1

	sem=$(_sem_get_path "$name")
	waitlock=$(_sem_get_waitlock "$name")
	countlock=$(_sem_get_countlock "$name")
	counter=$(_sem_get_counter "$name")
	owner=$(_sem_get_owner "$name")

	if ! is_digits "$value"; then
		log_debug "Initial value must be numeric"
		return 1
	fi

	if ! mkdir "$sem"; then
		log_error "Semaphore $sem exists"
		return 1
	fi

	if ! mutex_trylock "$countlock"; then
		log_error "Could not acquire $countlock"
	else
		# If value is greater than zero, the next call to sem_wait() does
		# not have to wait for a sem_post() to happen. Hence the waitlock
		# does not need to be locked.

		if ! mutex_trylock "$owner"; then
			log_error "Could not acquire mutex $owner"
		elif (( value == 0 )) && ! wmutex_trylock "$waitlock"; then
			log_error "Could not acquire wmutex $waitlock"
		elif ! echo "$value" > "$counter"; then
			log_error "Could not write counter $counter"
		else
			err=0
		fi

		mutex_unlock "$countlock"
	fi

	if (( err != 0 )); then
		if ! rm -rf "$sem"; then
			log_error "Could not remove $sem"
		fi
	fi

	return "$err"
}

sem_destroy() {
	local name="$1"

	local sem
	local owner

	sem=$(_sem_get_path "$name")
	owner=$(_sem_get_owner "$name")

	if ! mutex_unlock "$owner"; then
		log_debug "Could not unlock $owner"
		return 1
	fi

	if ! rm -rf "$sem"; then
		log_error "Could not remove $sem"
		return 1
	fi

	return 0
}

sem_wait() {
	local name="$1"
	local -i timeout="$2"

	local waitlock
	local countlock
	local counter
	local err

	if (( $# < 2 )); then
		timeout=-1
	fi

	waitlock=$(_sem_get_waitlock "$name")
	countlock=$(_sem_get_countlock "$name")
	counter=$(_sem_get_counter "$name")
	err=1

	if ! wmutex_lock "$waitlock" "$timeout"; then
		return 1
	fi

	if mutex_lock "$countlock"; then
		local count

		_sem_counter_dec "$counter"

		# if count was greater than 1, we need to unlock the waitlock
		# because there won't be anyone calling sem_post()

		count=$(<"$counter")
		if (( count > 0 )); then
			wmutex_unlock "$waitlock"
		fi

		mutex_unlock "$countlock"
		err=0
	fi

	return "$err"
}

sem_trywait() {
	local name="$1"

	sem_wait "$name" 0
	return "$?"
}

sem_post() {
	local name="$1"

	local waitlock
	local countlock
	local counter
	local err

	waitlock=$(_sem_get_waitlock "$name")
	countlock=$(_sem_get_countlock "$name")
	counter=$(_sem_get_counter "$name")
	err=1

	if mutex_lock "$countlock"; then
		_sem_counter_inc "$counter"
		mutex_unlock "$countlock"

		if [ -L "$waitlock" ]; then
			wmutex_unlock "$waitlock"
		fi

		err=0
	fi

	return "$err"
}

sem_peek() {
	local name="$1"

	local countlock
	local counter
	local value
	local err

        countlock=$(_sem_get_countlock "$name")
	counter=$(_sem_get_counter "$name")
	err=1

	if mutex_lock "$countlock"; then
		if value=$(<"$counter"); then
			err=0
		fi

		mutex_unlock "$countlock"
	fi

	if (( err == 0 )); then
		echo "$value"
	fi

	return "$err"
}
