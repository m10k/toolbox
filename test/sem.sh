#!/usr/bin/env bats

. toolbox.sh
include "sem"

setup() {
	delete=()
	return 0
}

teardown() {
	if (( ${#delete[@]} > 0 )); then
		rm -rf "${delete[@]}"
	fi

	return 0
}

@test "sem00: _sem_get_path() returns the path of a private semaphore if name does not contain slashes" {
	local name
	local expectation
	local reality

	name="hoge"
	expectation="$__sem_path/$name"
	reality=$(_sem_get_path "$name")

	[[ "$expectation" == "$reality" ]]
}

@test "sem01: _sem_get_path() returns the path of a public semaphore if name contains a slash" {
	local name
	local expectation
	local reality

	name="hoge/hoge"
	expectation="$name"
	reality=$(_sem_get_path "$name")

	[[ "$expectation" == "$reality" ]]
}

@test "sem02: _sem_get_waitlock() returns the path of a private semaphore's waitlock" {
	local name
	local expectation
	local reality

	name="hoge"
	expectation="$__sem_path/$name/waitlock"
	reality=$(_sem_get_waitlock "$name")

	[[ "$expectation" == "$reality" ]]
}

@test "sem03: _sem_get_waitlock() returns the path of a public semaphore's waitlock" {
	local name
	local expectation
	local reality

	name="hoge/hoge"
	expectation="$name/waitlock"
	reality=$(_sem_get_waitlock "$name")

	[[ "$expectation" == "$reality" ]]
}

@test "sem04: _sem_get_countlock() returns the path of a private semaphore's countlock" {
	local name
	local expectation
	local reality

	name="hoge"
	expectation="$__sem_path/$name/countlock"
	reality=$(_sem_get_countlock "$name")

	[[ "$expectation" == "$reality" ]]
}

@test "sem05: _sem_get_countlock() returns the path of a public semaphore's countlock" {
	local name
	local expectation
	local reality

	name="hoge/hoge"
	expectation="$name/countlock"
	reality=$(_sem_get_countlock "$name")

	[[ "$expectation" == "$reality" ]]
}

@test "sem06: _sem_get_owner() returns the path of a private semaphore's owner mutex" {
	local name
	local expectation
	local reality

	name="hoge"
	expectation="$__sem_path/$name/owner"
	reality=$(_sem_get_owner "$name")

	[[ "$expectation" == "$reality" ]]
}

@test "sem07: _sem_get_owner() returns the path of a public semaphore's owner mutex" {
	local name
	local expectation
	local reality

	name="hoge/hoge"
	expectation="$name/owner"
	reality=$(_sem_get_owner "$name")

	[[ "$expectation" == "$reality" ]]
}

@test "sem08: _sem_get_counter() returns path of a private semaphore's counter" {
	local name
	local expectation
	local reality

	name="hoge"
	expectation="$__sem_path/$name/counter"
	reality=$(_sem_get_counter "$name")

	[[ "$expectation" == "$reality" ]]
}

@test "sem09: _sem_get_counter() returns path of a public semaphore's counter" {
	local name
	local expectation
	local reality

	name="hoge/hoge"
	expectation="$name/counter"
	reality=$(_sem_get_counter "$name")

	[[ "$expectation" == "$reality" ]]
}

@test "sem10: _sem_counter_inc() increases the counter" {
	local counter
	local value
	local i

	counter=$(mktemp)
	delete+=("$counter")

	value=0
	echo "$value" > "$counter"

	for (( i = 1; i <= 64; i++ )); do
		_sem_counter_inc "$counter"
		value=$(<"$counter")
		(( value == i ))
	done
}

@test "sem11: _sem_counter_dec() decreases the counter" {
	local counter
	local value
	local i

	counter=$(mktemp)
	delete+=("$counter")

	value=64
	echo "$value" > "$counter"

	for (( i = 63; i >= 0; i-- )); do
		_sem_counter_dec "$counter"
		value=$(<"$counter")
		(( value == i ))
	done
}

@test "sem12: sem_init() creates a private semaphore" {
	local path
	local name

	name="test_sem12_$RANDOM"
	path=$(_sem_get_path "$name")

	! [ -d "$path" ]
	sem_init "$name" 0
	[ -d "$path" ]

	delete+=("$path")
}

@test "sem13: sem_init() creates a public semaphore" {
	local path
	local name

	path=$(mktemp -d)
	delete+=("$path")
	name="$path/test_sem13"

	! [ -d "$name" ]
	sem_init "$name" 0
	[ -d "$name" ]
}

@test "sem14: sem_init() creates a private semaphore" {
	local path
	local name

	name="test_sem14_$RANDOM"
	path=$(_sem_get_path "$name")

	! [ -d "$name" ]
	sem_init "$name" 0
	[ -d "$path" ]

	delete+=("$path")
}

@test "sem15: sem_init() locks the waitlock if value is 0" {
	local path
	local name
	local waitlock

	path=$(mktemp -d)
	delete+=("$path")
	name="$path/test_sem15"

	sem_init "$name" 0

	waitlock=$(_sem_get_waitlock "$name")

	[ -L "$waitlock" ]
}

@test "sem16: sem_init() does not lock the waitlock if value > 0" {
	local path
	local i

	path=$(mktemp -d)
	delete+=("$path")

	for (( i = 1; i <= 8; i++ )); do
		local name
		local waitlock

		name="$path/test_sem16_$i"
		waitlock=$(_sem_get_waitlock "$name")

		sem_init "$name" "$i"

		! [ -L "$waitlock" ]
	done
}

@test "sem17: sem_init() does not lock the countlock" {
	local path
	local i

	path=$(mktemp -d)
	delete+=("$path")

	for (( i = 0; i < 8; i++ )); do
		local name
		local countlock

		name="$path/test_sem17_$i"
		countlock=$(_sem_get_countlock "$name")

		sem_init "$name" "$i"

		! [ -L "$countlock" ]
	done
}

@test "sem18: sem_init() sets the semaphore's counter" {
	local path
	local i

	path=$(mktemp -d)
	delete+=("$path")

	for (( i = 0; i < 8; i++ )); do
		local name
		local counter
		local value

		name="$path/test_sem18_$i"
		counter=$(_sem_get_counter "$name")

		sem_init "$name" "$i"

		value=$(<"$counter")
		(( value == i ))
	done
}

@test "sem19: sem_init() sets the ownerlock" {
	local path
	local name
	local ownerlock

	path=$(mktemp -d)
	delete+=("$path")

	name="$path/test_sem19"
	ownerlock=$(_sem_get_owner "$name")

	sem_init "$name" 0

	[ -L "$ownerlock" ]
}

@test "sem20: sem_init() makes the current process owner of the semaphore" {
	local path
	local name
	local ownerlock

	path=$(mktemp -d)
	delete+=("$path")

	name="$path/test_sem20"
	ownerlock=$(_sem_get_owner "$name")

	sem_init "$name" 0

	owner=$(readlink "$ownerlock")
	(( BASHPID == owner ))
}

@test "sem21: sem_init() makes the subshell owner of the semaphore" {
	local path
	local name

	path=$(mktemp -d)
	delete+=("$path")

	name="$path/test_sem21"

	(
		local ownerlock
		local owner

		sem_init "$name" 0
		ownerlock=$(_sem_get_owner "$name")
		owner=$(readlink "$ownerlock")

		(( owner == BASHPID ))
		(( owner != $$ ))
	)
}

@test "sem22: sem_init() fails if value is missing" {
	local path
	local name

	path=$(mktemp -d)
	delete+=("$path")

	name="$path/test_sem22"

	! sem_init "$name"
}

@test "sem23: sem_init() fails if value is not numeric" {
	local path
	local name

	path=$(mktemp -d)
	delete+=("$path")

	name="$path/test_sem23"

 	! sem_init "$name" "test"
}

@test "sem24: sem_init() fails if value is negative" {
	local path
	local name

	path=$(mktemp -d)
	delete+=("$path")

	name="$path/test_sem24"

	! sem_init "$name" -1
}

@test "sem25: sem_init() does not create a semaphore if the value is missing" {
	local path
	local name

	path=$(mktemp -d)
	delete+=("$path")

	name="$path/test_sem25"

	! sem_init "$name"
	! [ -e "$name" ]
}

@test "sem26: sem_init() does not create a semaphore if the value is not numeric" {
	local path
	local name

	path=$(mktemp -d)
	delete+=("$path")

	name="$path/test_sem26"

	! sem_init "$name" "test"
	! [ -e "$name" ]
}

@test "sem27: sem_init() does not create a semaphore if the value is negative" {
	local path
	local name

	path=$(mktemp -d)
	delete+=("$path")

	name="$path/test_sem27"

	! sem_init "$name" -1
	! [ -e "$name" ]
}

@test "sem28: sem_destroy() destroys semaphore if called by owner" {
       	local path
	local name

	path=$(mktemp -d)
	delete+=("$path")

	name="$path/test_sem28"

	sem_init "$name" 0

	[ -e "$name" ]
	sem_destroy "$name"
	! [ -e "$name" ]
}

@test "sem29: sem_destroy() does not destroy another process's semaphore" {
	local path
	local name

	path=$(mktemp -d)
	delete+=("$path")

	name="$path/test_sem29"

	sem_init "$name" 0
	[ -e "$name" ]
	! ( sem_destroy "$name" )
	[ -e "$name" ]
}

@test "sem30: sem_post() increases the counter by one" {
	local name
	local path
	local counter
	local i

	path=$(mktemp -d)
	delete+=("$path")

	name="$path/test_sem30"
	counter=$(_sem_get_counter "$name")

	sem_init "$name" 0

	for (( i = 1; i <= 16; i++ )); do
		local value

		sem_post "$name"
		value=$(<"$counter")

		(( value == i ))
	done
}

@test "sem31: sem_wait() decreases the counter by one" {
	local name
	local path
	local counter
	local i

	path=$(mktemp -d)
	delete+=("$path")

	name="$path/test_sem31"
	counter=$(_sem_get_counter "$name")

	sem_init "$name" 16

	for (( i = 15; i >= 0; i-- )); do
		local value

		sem_wait "$name"
		value=$(<"$counter")

		(( value == i ))
	done
}

@test "sem32: sem_wait() locks the waitlock if the counter is 1" {
	local name
	local path
	local waitlock

	path=$(mktemp -d)
	delete+=("$path")

	name="$path/test_sem32"
	waitlock=$(_sem_get_waitlock "$name")

	sem_init "$name" 1
	sem_wait "$name"
	[ -L "$waitlock" ]
}

@test "sem33: sem_wait() releases the waitlock if the counter is greater than 1" {
	local name
	local path
	local waitlock

	path=$(mktemp -d)
	delete+=("$path")

	name="$path/test_sem33"
	waitlock=$(_sem_get_waitlock "$name")

	sem_init "$name" 2
	sem_wait "$name"
	! [ -L "$waitlock" ]
}

@test "sem34: sem_peek() returns the counter of a semaphore" {
	local name
	local path
	local i

	path=$(mktemp -d)
	delete+=("$path")

	name="$path/test_sem34"

	sem_init "$name" 0

	for (( i = 1; i <= 16; i++ )); do
		local counter

		sem_post "$name"
		counter=$(sem_peek "$name")
		(( counter == i ))
	done
}

@test "sem35: sem_post() wakes up sem_wait()" {
 	local sem
	local path
	local ppid
	local cpid
	local timeout


	path=$(mktemp -d)
	delete+=("$path")

	sem="$path/test_sem35"

 	sem_init "$sem" 0

	( sem_wait "$sem" ) &
	cpid="$!"
	( sem_post "$sem" ) &

	for (( timeout = 10; timeout > 0; timeout-- )); do
		if ! ps -p "$cpid" &> /dev/null; then
			return 0
		fi

		sleep 1
	done

	kill -9 "$cpid"
	return 1
}

@test "sem36: sem_wait() is woken up by sem_post()" {
	local sem
	local path
	local ppid
	local cpid
	local timeout

	path=$(mktemp -d)
	delete+=("$path")

	timeout=10
	sem="$path/test_sem36"

	sem_init "$sem" 0

	( sem_post "$sem" ) &
	( sem_wait "$sem" ) &
	cpid="$!"

	for (( timeout = 10; timeout > 0; timeout-- )); do
		if ! ps -p "$cpid" &> /dev/null; then
			return 0
		fi

		sleep 1
	done

	kill -9 "$cpid"
	return 1
}
