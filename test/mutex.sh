#!/usr/bin/env bats

. toolbox.sh
include "mutex"

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

@test "mutex_trylock() returns success if the lock was created" {
	local name

	name="test_$RANDOM"

	mutex_trylock "$name"
	[ -L "$name" ]

	delete+=("$name")
}

@test "mutex_trylock() returns failure if the lock was not created" {
	local name

	name="/$RANDOM/$RANDOM/$RANDOM/$RANDOM"

	! [ -d "${name%/*}" ]
	! mutex_trylock "$name"
}

@test "mutex_lock() returns success if the lock was created" {
	local name

	name="test_$RANDOM"

	mutex_lock "$name"
	[ -L "$name" ]

	delete+=("$name")
}

@test "mutex_lock() returns failure if the lock was not created" {
	local name

	# Unlikely to exist path
	name="/$RANDOM/$RANDOM/RANDOM/$RANDOM"

	! [ -d "${name%/*}" ]
	! mutex_lock "$name"
	! [ -L "$name" ]
}

@test "mutex_unlock() returns success if the lock was removed" {
	local name

	name="test_$RANDOM"

	mutex_lock "$name"
	mutex_unlock "$name"
	! [ -e "$name" ]
}

@test "mutex_unlock() returns failure if the lock was not removed" {
	local name

	# Unlikely to exist path
	name="/$RANDOM/$RANDOM/$RANDOM/$RANDOM"

	! [ -d "${name%/*}" ]
	! mutex_unlock "$name"
}

@test "mutex_unlock() returns failure if mutex belongs to a different process" {
	local name

	name="test_$RANDOM"

	mutex_lock "$name"
	delete+=("$name")

	( ! mutex_unlock "$name" )
}
