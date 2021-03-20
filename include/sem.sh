#!/bin/bash

#
# sem - POSIX-like semaphores for bash scripts
# Copyright (C) 2021 - Matthias Kruk <m@m10k.eu>
#

__init() {
	if ! include "mutex"; then
		return 1
	fi

	declare -gr __sem_path="$TOOLBOX_HOME/sem"

	return 0
}


_sem_mutexpath() {
	local sem

	sem="$1"

	echo "$__sem_path/$sem.mutex"
}

_sem_ownerpath() {
	local sem

	sem="$1"

	echo "$__sem_path/$sem.owner"
}

_sem_sempath() {
	local sem

	sem="$1"

	echo "$__sem_path/$sem"
}

_sem_inc() {
	local sem
	local value

	sem="$1"

	if ! value=$(cat "$sem"); then
		return 1
	fi

	((value++))

	if ! echo "$value" > "$sem"; then
		return 1
	fi

	return 0
}

_sem_dec() {
	local sem
	local value

	sem="$1"

	if ! value=$(cat "$sem"); then
		return 1
	fi

	if (( value == 0 )); then
		return 1
	fi

	((value--))

	if ! echo "$value" > "$sem"; then
		return 1
	fi

	return 0
}

sem_init() {
	local name
	local value

	local mutex
	local sem
	local owner
	local err

	name="$1"
	value="$2"
	err=0

	mutex=$(_sem_mutexpath "$name")
	sem=$(_sem_sempath "$name")
	owner=$(_sem_ownerpath "$name")

	if ! [[ "$value" =~ ^[0-9]+$ ]]; then
		return 1
	fi

	if ! mkdir -p "$__sem_path"; then
		return 1
	fi

	# If the semaphore is new, locking must succeed,
	# otherwise it was not a new semaphore
	if ! mutex_trylock "$mutex"; then
		error "Could not acquire $mutex"
		return 1
	fi

	if ! mutex_trylock "$owner"; then
		error "Could not acquire $mutex"
		err=1
	elif ! echo "$value" > "$sem"; then
		err=1
	fi

	mutex_unlock "$mutex"
	return "$err"
}

sem_destroy() {
	local name

	local mutex
	local sem
	local owner

	name="$1"

	mutex=$(_sem_mutexpath "$name")
	sem=$(_sem_sempath "$name")
	owner=$(_sem_ownerpath "$name")

	# Make sure only the owner can destroy the semaphore
	if ! mutex_unlock "$owner"; then
		return 1
	fi

	if ! rm -f "$mutex" "$sem"; then
		return 1
	fi

	return 0
}

sem_wait() {
	local name

	local mutex
	local sem
	local passed

	name="$1"

	mutex=$(_sem_mutexpath "$name")
	sem=$(_sem_sempath "$name")
	passed=0

	while (( passed == 0)); do
		mutex_lock "$mutex"

		if _sem_dec "$sem"; then
			passed=1
		fi

		mutex_unlock "$mutex"
	done

	return 0
}

sem_trywait() {
	local name

	local mutex
	local sem
	local res

	name="$1"

	mutex=$(_sem_mutexpath "$name")
	sem=$(_sem_sempath "$name")
	res=1

	mutex_lock "$mutex"

	if _sem_dec "$sem"; then
		res=0
	fi

	mutex_unlock "$mutex"

	return "$res"
}

sem_post() {
	local name

	local mutex
	local sem
	local err
	local value

	name="$1"

	mutex=$(_sem_mutexpath "$name")
	sem=$(_sem_sempath "$name")
	err=0

	mutex_lock "$mutex"

	if ! _sem_inc "$sem"; then
		err=1
	fi

	mutex_unlock "$mutex"

	return "$err"
}
