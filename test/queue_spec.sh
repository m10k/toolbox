#!/bin/bash

# queue_spec.sh - Test cases for the toolbox queue module
# Copyright (C) 2021-2023 Matthias Kruk
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

if ! . toolbox.sh; then
	exit 1
fi

if ! include "array" "queue"; then
	exit 1
fi

Describe "queue_init()"
  It "creates a public queue"
    _test_queue_init_public() {
	    local tmpdir
	    local queue
	    local ret

	    if ! tmpdir=$(mktemp -d); then
		    return 1
	    fi

	    queue="$tmpdir/queue"
	    ret=1

	    if queue_init "$queue" &&
	       [ -d "$queue" ]; then
		    ret=0
	    fi

	    rm -rf "$tmpdir"
	    return "$ret"
    }

    When call _test_queue_init_public
    The status should equal 0
  End

  It "creates a private queue"
    _test_queue_init_private() {
	    local queue
	    local queue_path

	    queue="test$RANDOM"
	    queue_path=$(_queue_get_path "$queue")

	    if [[ "$queue_path" == "/" ]]; then
		    # you never know
		    return 1
	    fi

	    if ! queue_init "$queue"; then
		    return 1
	    fi

	    if ! [ -d "$queue_path" ]; then
		    return 1
	    fi

	    rm -rf "$queue_path"
	    return 0
    }

    When call _test_queue_init_private
    The status should equal 0
  End
End

Describe "queue_destroy()"
  It "destroys a public queue"
    _test_queue_destroy_public() {
	    local tmpdir
	    local queue
	    local ret

	    if ! tmpdir=$(mktemp -d); then
		    return 1
	    fi

	    queue="$tmpdir/queue"
	    ret=1

	    if ! queue_init "$queue" ||
	       ! [ -d "$queue" ]; then
		    return 1
	    fi

	    if queue_destroy "$queue" &&
	       ! [ -d "$queue" ]; then
		    ret=0
	    else
		    rm -rf "$queue"
	    fi

	    return "$ret"
    }

    When call _test_queue_destroy_public
    The status should equal 0
  End

  It "destroys a private queue"
    _test_queue_destroy_private() {
	    local queue
	    local queue_path
	    local ret

	    queue="test$RANDOM"
	    queue_path=$(_queue_get_path "$queue")
	    ret=1

	    if [[ "$queue_path" == "/" ]] ||
	       [[ -z "$queue_path" ]]; then
		    return 1
	    fi

	    if ! queue_init "$queue"; then
		    return 1
	    fi

	    if ! [ -d "$queue_path" ]; then
		    return 1
	    fi

	    if queue_destroy "$queue" &&
	       ! [ -d "$queue_path" ]; then
		    ret=0
	    else
		    rm -rf "$queue_path"
	    fi

	    return "$ret"
    }

    When call _test_queue_destroy_private
    The status should equal 0
  End
End

Describe "queue_put()"
  It "adds an item to the queue"
    _test_queue_put_add() {
	    local tmpdir
	    local queue

	    local items_before
	    local items_after
	    local item_new
	    local item

	    if ! tmpdir=$(mktemp -d); then
		    return 1
	    fi

	    queue="$tmpdir/queue"

	    if ! queue_init "$queue"; then
		    rm -rf "$tmpdir"
		    return 2
	    fi

	    items_before=()
	    while read -r item; do
		    items_before+=("$item")
	    done < <(queue_foreach "$queue" echo)

	    item_new="$RANDOM.item.$RANDOM"

	    if ! queue_put "$queue" "$item_new"; then
		    rm -rf "$tmpdir"
		    return 3
	    fi

	    items_after=()
	    while read -r item; do
		    items_after+=("$item")
	    done < <(queue_foreach "$queue" echo)

	    rm -rf "$tmpdir"

	    items_before+=("$item_new")

	    if ! array_same items_before items_after; then
		    return 4
	    fi

	    return 0
    }

    When call _test_queue_put_add
    The status should equal 0
  End

  It "adds an item to the end of the queue"
    _test_queue_put_append() {
	    local tmpdir
	    local queue

	    local items_before
	    local items_after
	    local item_new
	    local item

	    if ! tmpdir=$(mktemp -d); then
		    return 1
	    fi

	    queue="$tmpdir/queue"

	    if ! queue_init "$queue"; then
		    rm -rf "$tmpdir"
		    return 2
	    fi

	    items_before=()
	    while read -r item; do
		    items_before+=("$item")
	    done < <(queue_foreach "$queue" echo)

	    item_new="$RANDOM.item.$RANDOM"

	    if ! queue_put "$queue" "$item_new"; then
		    rm -rf "$tmpdir"
		    return 3
	    fi

	    items_after=()
	    while read -r item; do
		    items_after+=("$item")
	    done < <(queue_foreach "$queue" echo)

	    rm -rf "$tmpdir"

	    items_before+=("$item_new")

	    if ! array_identical items_before items_after; then
		    return 4
	    fi

	    return 0
    }

    When call _test_queue_put_append
    The status should equal 0
  End
End

Describe "queue_get()"
  It "gets an item from a queue"
    _test_queue_get_simple() {
	    local tmpdir
	    local queue
	    local data_enqueued
	    local data_dequeued
	    local err

	    if ! tmpdir=$(mktemp -d); then
		    return 1
	    fi

	    queue="$tmpdir/queue"
	    data_enqueued="$RANDOM.data.$RANDOM"
	    err=0

	    if ! queue_init "$queue"; then
		    err=2

	    elif ! queue_put "$queue" "$data_enqueued"; then
		    err=3

	    elif ! data_dequeued=$(queue_get "$queue" 0); then
		    err=4

	    elif [[ "$data_enqueued" != "$data_dequeued" ]]; then
		    err=5
	    fi

	    rm -rf "$tmpdir"
	    return "$err"
    }

    When call _test_queue_get_simple
    The status should equal 0
  End

  It "preserves the order of items"
    _test_queue_get_order() {
	    local tmpdir
	    local queue
	    local data_enqueued
	    local data_dequeued
	    local err

	    if ! tmpdir=$(mktemp -d); then
		    return 1
	    fi

	    queue="$tmpdir/queue"
	    data_enqueued=(1 2 3)
	    err=0

	    if ! queue_init "$queue"; then
		    err=2

	    elif ! queue_put "$queue" "${data_enqueued[0]}" ||
		 ! queue_put "$queue" "${data_enqueued[1]}" ||
		 ! queue_put "$queue" "${data_enqueued[2]}"; then
		    err=3

	    elif ! data_dequeued+=("$(queue_get "$queue")") ||
		 ! data_dequeued+=("$(queue_get "$queue")") ||
		 ! data_dequeued+=("$(queue_get "$queue")"); then
		    err=4

	    elif ! array_identical data_enqueued data_dequeued; then
		    err=5
	    fi

	    rm -rf "$tmpdir"
	    return "$err"
    }

    When call _test_queue_get_order
    The status should equal 0
  End

  It "blocks for specified amount of seconds if timeout > 0"
    _test_queue_get_timeout_n() {
	    local timeout
	    local tmpdir
	    local queue
	    local err

	    if ! tmpdir=$(mktemp -d); then
		    return 1
	    fi

	    queue="$tmpdir/queue"
	    timeout=5
	    err=0

	    if ! queue_init "$queue"; then
		    err=2
	    else
		    local time_before
		    local time_after
		    local time_waited

		    time_before=$(date +"%s")
		    queue_get "$queue" "$timeout"
		    time_after=$(date +"%s")

		    time_waited=$((time_after - time_before))
		    if (( time_waited > (timeout + 1) )); then
			    err=3
		    elif (( time_waited < timeout )); then
			    err=4
		    fi
	    fi

	    rm -rf "$tmpdir"
	    return "$err"
    }

    When call _test_queue_get_timeout_n
    The status should equal 0
  End

  It "does not block if timeout == 0"
    _test_queue_get_timeout_zero() {
	    local tmpdir
	    local queue
	    local err

	    if ! tmpdir=$(mktemp -d); then
		    return 1
	    fi

	    queue="$tmpdir/queue"
	    err=0

	    if ! queue_init "$queue"; then
		    err=2

	    else
		    local time_before
		    local time_after

		    time_before=$(date +"%s")
		    queue_get "$queue" 0
		    time_after=$(date +"%s")

		    if (( (time_after - time_before) > 0 )); then
			    err=3
		    fi
	    fi

	    rm -rf "$tmpdir"
	    return "$err"
    }

    When call _test_queue_get_timeout_zero
    The status should equal 0
  End

  It "blocks until a message arrives if timeout == -1"
    _test_queue_get_timeout_negative() {
	    local tmpdir
	    local queue
	    local err

	    if ! tmpdir=$(mktemp -d); then
		    return 1
	    fi

	    queue="$tmpdir/queue"
	    err=0

	    if ! queue_init "$queue"; then
		    err=2

	    else
		    local delay

		    for (( delay = 0; delay < 5; delay++ )); do
			    local time_before
			    local time_after
			    local time_waited

			    ( sleep "$delay"; queue_put "$queue" "hello world" ) &

			    time_before=$(date +"%s")
			    queue_get "$queue" -1 &> /dev/null
			    time_after=$(date +"%s")

			    time_waited=$((time_after - time_before))

			    if (( time_waited < delay )); then
				    err=3
				    break
			    fi

			    # queue_put() and queue_get() may incur a delay of 1s each,
			    # add bad scheduler timing and we need 3 seconds tolerance
			    if (( (time_waited - delay) > 3 )); then
				    err=4
				    break
			    fi
		    done
	    fi

	    rm -rf "$tmpdir"
	    return "$err"
    }

    When call _test_queue_get_timeout_negative
    The status should equal 0
  End

  It "blocks until a message arrives if timeout is omitted"
    _test_queue_get_timeout_omitted() {
	    local tmpdir
	    local queue
	    local err

	    if ! tmpdir=$(mktemp -d); then
		    return 1
	    fi

	    queue="$tmpdir/queue"
	    err=0

	    if ! queue_init "$queue"; then
		    err=2

	    else
		    local delay

		    for (( delay = 0; delay < 5; delay++ )); do
			    local time_before
			    local time_after
			    local time_waited

			    ( sleep "$delay"; queue_put "$queue" "hello world" ) &

			    time_before=$(date +"%s")
			    queue_get "$queue" &> /dev/null
			    time_after=$(date +"%s")

			    time_waited=$((time_after - time_before))

			    if (( time_waited < delay )); then
				    err=3
				    break
			    fi

			    if (( (time_waited - delay) > 3 )); then
				    err=4
				    break
			    fi
		    done
	    fi

	    rm -rf "$tmpdir"
	    return "$err"
    }

    When call _test_queue_get_timeout_omitted
    The status should equal 0
  End
End

Describe "queue_foreach()"
  It "does not print anything on an empty queue"
    _test_queue_foreach_empty() {
	    local tmpdir
	    local queue
	    local err

	    if ! tmpdir=$(mktemp -d); then
		    return 1
	    fi

	    err=2
	    queue="$tmpdir/queue"

	    if ! queue_init "$queue"; then
		    err=3

	    elif ! queue_foreach "$queue" echo "anything"; then
		    err=4

	    else
		    err=0
	    fi

	    rm -rf "$tmpdir"
	    return "$err"
    }

    When call _test_queue_foreach_empty
    The status should equal 0
  End

  It "calls the callback for each element"
    _test_queue_foreach_call_foreach() {
	    local tmpdir
	    local queue
	    local err
	    local items
	    local item
	    local contents

	    if ! tmpdir=$(mktemp -d); then
		    return 1
	    fi

	    err=2
	    queue="$tmpdir/queue"
	    items=("hello" "world" "foobar")
	    contents=()

	    if ! queue_init "$queue"; then
		    rm -rf "$tmpdir"
		    return 3
	    fi

	    for item in "${items[@]}"; do
		    if ! queue_put "$queue" "$item"; then
			    rm -rf "$tmpdir"
			    return 4
		    fi
	    done

	    while read -r item; do
		    contents+=("$item")
	    done < <(queue_foreach "$queue" echo)

	    rm -rf "$tmpdir"

	    if ! array_same items contents; then
		    return 1
	    fi

	    return 0
    }

    When call _test_queue_foreach_call_foreach
    The status should equal 0
  End

  It "preserves the order of elements"
    _test_queue_foreach_call_order() {
	    local tmpdir
	    local queue
	    local err
	    local items
	    local item
	    local contents

	    if ! tmpdir=$(mktemp -d); then
		    return 1
	    fi

	    err=2
	    queue="$tmpdir/queue"
	    items=("hello" "world" "foobar")
	    contents=()

	    if ! queue_init "$queue"; then
		    rm -rf "$tmpdir"
		    return 3
	    fi

	    for item in "${items[@]}"; do
		    if ! queue_put "$queue" "$item"; then
			    rm -rf "$tmpdir"
			    return 4
		    fi
	    done

	    while read -r item; do
		    contents+=("$item")
	    done < <(queue_foreach "$queue" echo)

	    rm -rf "$tmpdir"

	    if ! array_identical items contents; then
		    return 1
	    fi

	    return 0
    }

    When call _test_queue_foreach_call_order
    The status should equal 0
  End
End
