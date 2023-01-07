#!/bin/bash

. toolbox.sh
include "wmutex"

Describe "wmutex_trylock()"
  It "returns success if the lock was created"
    _test_wmutex_trylock_success() {
	    local mutex
	    local -i err

	    err=0

	    if ! mutex=$(mktemp --dry-run); then
		    return 1
	    elif ! wmutex_trylock "$mutex"; then
		    return 2
	    elif ! [ -L "$mutex" ]; then
		    err=3
	    elif ! wmutex_unlock "$mutex"; then
		    err=4
	    fi

	    if [ -L "$mutex" ]; then
		    rm -f "$mutex"
	    fi

	    return "$err"
    }
    When call _test_wmutex_trylock_success
    The status should equal 0
  End

  It "returns failure if the lock was not created"
    _test_wmutex_trylock_failure() {
	    local mutex

	    if ! mutex=$(mktemp --directory --dry-run); then
		    return 1
	    fi

	    mutex+="/$RANDOM/$RANDOM/$RANDOM/$RANDOM"

	    if wmutex_trylock "$mutex"; then
		    wmutex_unlock "$mutex"
		    return 2
	    elif [ -L "$mutex" ]; then
		    return 3
	    fi

	    return 0
    }
    When call _test_wmutex_trylock_failure
    The status should equal 0
  End
End

Describe "wmutex_lock()"
  It "returns success if the lock was created"
    _test_wmutex_lock_success() {
	    local mutex
	    local -i err

	    err=0

	    if ! mutex=$(mktemp --dry-run); then
		    return 1
	    elif ! wmutex_lock "$mutex" 1; then
		    return 2
	    elif ! [ -L "$mutex" ]; then
		    err=3
	    elif ! wmutex_unlock "$mutex"; then
		    err=4
	    fi

	    if [ -L "$mutex" ]; then
		    rm -f "$mutex"
	    fi

	    return "$err"
    }
    When call _test_wmutex_lock_success
    The status should equal 0
  End

  It "returns failure if the lock was not created"
    _test_wmutex_lock_failure() {
	    local mutex

	    if ! mutex=$(mktemp --directory --dry-run); then
		    return 1
	    fi

	    mutex+="/$RANDOM/$RANDOM/$RANDOM/$RANDOM"

	    if wmutex_lock "$mutex" 1; then
		    wmutex_unlock "$mutex"
		    return 2
	    elif [ -L "$mutex" ]; then
		    return 3
	    fi

	    return 0
    }
    When call _test_wmutex_lock_failure
    The status should equal 0
  End
End

Describe "wmutex_unlock()"
  It "returns success if the lock was removed"
    _test_wmutex_unlock_success() {
	    local mutex

	    if ! mutex=$(mktemp --dry-run); then
		    return 1
	    elif ! wmutex_lock "$mutex" 1; then
		    return 2
	    elif ! wmutex_unlock "$mutex"; then
		    return 3
	    elif [ -L "$mutex" ]; then
		    return 4
	    fi

	    return 0
    }

    When call _test_wmutex_unlock_success
    The status should equal 0
  End

  It "returns failure if the lock was not removed"
    _test_wmutex_unlock_failure() {
	    local mutex

	    if ! mutex=$(mktemp --dry-run); then
		    return 1
	    elif [ -L "$mutex" ]; then
		    return 2
	    elif wmutex_unlock "$mutex"; then
		    return 3
	    fi

	    return 0
    }

    When call _test_wmutex_unlock_failure
    The status should equal 0
  End

  It "returns success if the mutex belongs to a different process"
    _test_wmutex_unlock_foreign() {
	    local mutex
	    local -i err

	    err=0

	    if ! mutex=$(mktemp --dry-run); then
		    return 1
	    elif ! wmutex_lock "$mutex" 1; then
		    return 2
	    elif ! [ -L "$mutex" ]; then
		    return 3
	    fi

	    if ! bash -c ". toolbox.sh; include wmutex; wmutex_unlock \"$mutex\""; then
		    err=4
	    elif [ -L "$mutex" ]; then
		    err=5
	    fi

	    if [ -L "$mutex" ]; then
		    rm -f "$mutex"
	    fi

	    return "$err"
    }

    When call _test_wmutex_unlock_foreign
    The status should equal 0
  End
End
