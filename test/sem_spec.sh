#!/bin/bash

export PATH="$PWD/..:$PATH"

. toolbox.sh
include "sem"

Describe "sem_init()"
  It "creates a private semaphore"
    _test_sem_init_create_private() {
	    local name
	    local path

	    name="$FUNCNAME.$RANDOM"
	    path=$(_sem_get_path "$name")

	    if [ -d "$path" ]; then
		    return 1
	    elif ! sem_init "$name" 0; then
		    return 2
	    elif ! [ -d "$path" ]; then
		    return 3
	    fi

	    rm -rf "$path"
	    return 0
    }

    When call _test_sem_init_create_private
    The status should equal 0
  End

  It "creates a public semaphore"
    _test_sem_init_create_public() {
	    local name

	    if ! name=$(mktemp --dry-run); then
		    return 1
	    fi

	    if ! sem_init "$name" 0; then
		    return 1
	    elif ! [ -d "$name" ]; then
		    return 2
	    fi

	    rm -rf "$name"
	    return 0
    }

    When call _test_sem_init_create_public
    The status should equal 0
  End

  It "locks the waitlock if the counter is 0"
    _test_sem_init_lock_waitlock() {
	    local name
	    local lock
	    local -i err

	    if ! name=$(mktemp --dry-run); then
		    return 1
	    fi
	    lock=$(_sem_get_waitlock "$name")
	    err=0

	    if ! sem_init "$name" 0; then
		    return 1
	    elif ! [ -L "$lock" ]; then
		    err=2
	    fi

	    rm -rf "$name"
	    return "$err"
    }

    When call _test_sem_init_lock_waitlock
    The status should equal 0
  End

  It "does not lock the waitlock if the counter is larger than 0"
    _test_sem_init_unlock_waitlock() {
	    local name
	    local lock
	    local -i err

	    if ! name=$(mktemp --dry-run); then
		    return 1
	    fi
	    lock=$(_sem_get_waitlock "$name")
	    err=0

	    if ! sem_init "$name" 1; then
		    return 1
	    elif [ -L "$lock" ]; then
		    err=2
	    fi

	    rm -rf "$name"
	    return "$err"
    }

    When call _test_sem_init_unlock_waitlock
    The status should equal 0
  End

  It "sets the semaphore's counter"
    _test_sem_init_set_counter() {
	    local path
	    local -i i
	    local -i err

	    if ! path=$(mktemp --directory); then
		    return 1
	    fi
	    err=0

	    for (( i = 0; i < 8; i++ )); do
		    local name
		    local counter
		    local value

		    name="$path/sem$i"
		    counter=$(_sem_get_counter "$name")

		    if ! sem_init "$name" "$i"; then
			    (( err++ ))
			    continue
		    fi

		    value=$(< "$counter")
		    if (( value != i )); then
			    (( err++ ))
		    fi
	    done

	    rm -rf "$path"
	    return "$err"
    }

    When call _test_sem_init_set_counter
    The status should equal 0
  End

  It "sets the ownerlock"
    _test_sem_init_set_ownerlock() {
	    local sem
	    local lock

	    local -i err

	    if ! sem=$(mktemp --dry-run); then
		    return 1
	    elif ! sem_init "$sem" 0; then
		    return 2
	    fi

	    err=0
	    lock=$(_sem_get_owner "$sem")

	    if ! [ -L "$lock" ]; then
		    err=1
	    fi

	    rm -rf "$sem"
	    return "$err"
    }

    When call _test_sem_init_set_ownerlock
    The status should equal 0
  End

  It "makes the current process the owner of the semaphore"
    _test_sem_init_owner_curproc() {
	    local sem
	    local lock
	    local -i owner
	    local -i err

	    if ! sem=$(mktemp --dry-run); then
		    return 1
	    elif ! sem_init "$sem" 0; then
		    return 2
	    fi

	    err=0
	    lock=$(_sem_get_owner "$sem")

	    if ! owner=$(readlink "$lock"); then
		    err=3
	    elif (( owner != $$ )); then
		    err=4
	    fi

	    rm -rf "$sem"
	    return "$err"
    }

    When call _test_sem_init_owner_curproc
    The status should equal 0
  End

  It "fails if the counter value was not passed"
    When call sem_init "/tmp/dontcare.$RANDOM"
    The status should not equal 0
  End

  It "fails if the counter value is negative"
    When call sem_init "/tmp/dontcare.$RANDOM" -1
    The status should not equal 0
  End

  It "fails if the counter value is not numeric"
    When call sem_init "/tmp/dontcare.$RANDOM" "test"
    The status should not equal 0
  End

  It "does not allocate a semaphore if the function failed"
    When call sem_init "/tmp/dontcare"
    The status should not equal 0
    The path "/tmp/dontcare" should not exist
  End
End

Describe "sem_destroy()"
  It "removes a semaphore from the file system"
    _test_sem_destroy_removes_semaphore() {
	    local sem
	    local -i err

	    err=0

	    if ! sem=$(mktemp --dry-run); then
		    return 1
	    elif ! sem_init "$sem" 0; then
		    return 2
	    elif ! sem_destroy "$sem"; then
		    err=3
	    elif [ -e "$sem" ]; then
		    err=4
		    rm -rf "$sem"
	    fi

	    return "$err"
    }
    When call _test_sem_destroy_removes_semaphore
    The status should equal 0
  End

  It "does not destroy another process's semaphore"
    _test_sem_destroy_foreign_semaphore() {
	    local sem
	    local -i err

	    err=0

	    if ! sem=$(mktemp --dry-run); then
		    return 1
	    elif ! bash -c ". toolbox.sh; include sem; sem_init \"$sem\" 0"; then
		    return 2
	    fi

	    if sem_destroy "$sem"; then
		    err=3
	    fi

	    rm -rf "$sem"
	    return "$err"
    }
    When call _test_sem_destroy_foreign_semaphore
    The status should equal 0
  End
End

Describe "sem_post()"
  It "increases the counter by one"
    _test_sem_post_increase() {
	    local sem
	    local counter
	    local -i value
	    local -i err

	    if ! sem=$(mktemp --dry-run); then
		    return 1
	    elif ! sem_init "$sem" 0; then
		    return 2
	    fi

	    err=0
	    counter=$(_sem_get_counter "$sem")

	    if ! sem_post "$sem"; then
		    err=3
	    elif ! value=$(< "$counter"); then
		    err=4
	    elif (( value != 1 )); then
		    err=5
	    fi

	    rm -rf "$sem"
	    return "$err"
    }

    When call _test_sem_post_increase
    The status should equal 0
  End

  It "wakes up a blocked call to sem_wait()"
    _test_sem_post_wake_up_sem_wait() {
	    local sem
	    local -i timeout
	    local -i child_pid
	    local -i err

	    err=0
	    timeout=10

	    if ! sem=$(mktemp --dry-run); then
		    return 1
	    elif ! sem_init "$sem" 0; then
		    return 2
	    fi

	    ( sem_wait "$sem" ) &
	    child_pid="$!"

	    sem_post "$sem"

	    while (( timeout > 0 )) &&
		  kill -0 "$child_pid" &> /dev/null; do
		    sleep 1
		    (( timeout-- ))
	    done

	    if (( timeout == 0 )); then
		    err=3
		    kill "$child_pid"
	    fi

	    rm -rf "$sem"
	    return "$err"
    }

    When call _test_sem_post_wake_up_sem_wait
    The status should equal 0
  End
End

Describe "sem_wait()"
  It "decreases the counter by one"
    _test_sem_wait_decrease() {
	    local sem
	    local counter
	    local -i value
	    local -i err

	    if ! sem=$(mktemp --dry-run); then
		    return 1
	    elif ! sem_init "$sem" 1; then
		    return 2
	    fi

	    err=0
	    counter=$(_sem_get_counter "$sem")

	    if ! sem_wait "$sem"; then
		    err=3
	    elif ! value=$(< "$counter"); then
		    err=4
	    elif (( value != 0 )); then
		    err=5
	    fi

	    rm -rf "$sem"
	    return "$err"
    }

    When call _test_sem_wait_decrease
    The status should equal 0
  End

  It "locks the waitlock if the counter is 1"
    _test_sem_wait_lock_waitlock() {
	    local sem
	    local lock
	    local -i err

	    if ! sem=$(mktemp --dry-run); then
		    return 1
	    elif ! sem_init "$sem" 1; then
		    return 2
	    fi

	    err=0
	    lock=$(_sem_get_waitlock "$sem")

	    if ! sem_wait "$sem"; then
		    err=3
	    elif ! [ -L "$lock" ]; then
		    err=4
	    fi

	    rm -rf "$sem"
	    return "$err"
    }

    When call _test_sem_wait_lock_waitlock
    The status should equal 0
  End

  It "releases the waitlock if the counter is greater than 1"
    _test_sem_wait_unlock_waitlock() {
  	    local sem
	    local lock
	    local -i err

	    if ! sem=$(mktemp --dry-run); then
		    return 1
	    elif ! sem_init "$sem" 2; then
		    return 2
	    fi

	    err=0
	    lock=$(_sem_get_waitlock "$sem")

	    if ! sem_wait "$sem"; then
		    err=3
	    elif [ -L "$lock" ]; then
		    err=4
	    fi

	    rm -rf "$sem"
	    return "$err"
    }

    When call _test_sem_wait_unlock_waitlock
    The status should equal 0
  End
End

Describe "sem_peek()"
  It "returns the counter of a semaphore"
    _test_sem_peek_returns_counter() {
	    local sem
	    local -i i
	    local -i err

	    err=0

	    if ! sem=$(mktemp --dry-run); then
		    return 1
	    elif ! sem_init "$sem" 0; then
		    return 2
	    fi

	    for (( i = 0; i < 16; i++ )); do
		    local -i counter

		    counter=$(sem_peek "$sem")
		    if (( counter != i )); then
			    err=3
		    fi

		    sem_post "$sem"
	    done

	    rm -rf "$sem"
	    return "$err"
    }

    When call _test_sem_peek_returns_counter
    The status should equal 0
  End
End
