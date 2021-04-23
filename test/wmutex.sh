#!/usr/bin/env bats

. toolbox.sh
include "wmutex"

setup() {
	delete=()

	return 0
}


teardown() {
	if (( ${#delete[@]} > 0 )); then
		echo "${delete[*]}" >> /tmp/teardown.bats
		rm -f "${delete[@]}"
	fi

	return 0
}

@test "wmutex_trylock() returns success if the lock was created" {
	local name

	name="test_$RANDOM"

	wmutex_trylock "$name"
	[ -L "$name" ]

	delete+=("$name")
}

@test "wmutex_trylock() returns failure if the lock was not created" {
	local name

	name="/$RANDOM/$RANDOM/$RANDOM/$RANDOM"

	! [ -d "${name%/*}" ]
	! wmutex_trylock "$name"
}

@test "wmutex_lock() returns success if the lock was created" {
	local name

	name="test_$RANDOM"

	wmutex_lock "$name"
	[ -L "$name" ]

	delete+=("$name")
}

@test "wmutex_lock() returns failure if the lock was not created" {
	local name

	# Unlikely to exist path
	name="/$RANDOM/$RANDOM/RANDOM/$RANDOM"

	! [ -d "${name%/*}" ]
	! wmutex_lock "$name"
	! [ -L "$name" ]
}

@test "wmutex_unlock() returns success if the lock was removed" {
	local name

	name="test_$RANDOM"

	wmutex_lock "$name"
	wmutex_unlock "$name"
	! [ -e "$name" ]
}

@test "wmutex_unlock() returns failure if the lock was not removed" {
	local name

	# Unlikely to exist path
	name="/$RANDOM/$RANDOM/$RANDOM/$RANDOM"

	! [ -d "${name%/*}" ]
	! wmutex_unlock "$name"
}

@test "wmutex_unlock() returns success if wmutex belongs to a different process" {
	local name

	name="test_$RANDOM"

	wmutex_lock "$name"
	delete+=("$name")

	[ -L "$name" ]
	( wmutex_unlock "$name" )
	! [ -L "$name" ]
}
