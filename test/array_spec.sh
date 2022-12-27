#!/bin/bash

# array_spec.sh - Test cases for the toolbox array module
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

export PATH="$PWD/..:$PATH"

if ! . toolbox.sh; then
	exit 1
fi

if ! include "array"; then
	exit 1
fi

Describe "array_contains()"
  It "succeeds if the element is at the beginning of the array"
    When call array_contains "0" "0" "1" "2" "3" "4"
    The status should equal 0
  End

  It "succeeds if the element is in the middle of the array"
    When call array_contains "2" "0" "1" "2" "3" "4"
    The status should equal 0
  End

  It "succeeds if the element is at the end of the array"
    When call array_contains "4" "0" "1" "2" "3" "4"
    The status should equal 0
  End

  It "fails if the element is not in the array"
    When call array_contains "-1" "0" "1" "2" "3" "4"
    The status should equal 1
  End
End

Describe "array_to_lines()"
  It "returns no lines for an empty array"
    When call array_to_lines
    The status should equal 0
  End

  It "returns one line for a one-element array"
    When call array_to_lines "0"
    The status should equal 0
    The first line of stdout should equal "0"
  End

  It "returns two lines for a two-element array"
    When call array_to_lines "0" "1"
    The status should equal 0
    The first line of stdout should equal "0"
    The second line of stdout should equal "1"
  End

  It "returns three lines for a three-element array"
    When call array_to_lines "0" "1" "2"
    The status should equal 0
    The first line of stdout should equal "0"
    The second line of stdout should equal "1"
    The third line of stdout should equal "2"
  End

  It "returns n lines for an n-element array"
    _test_array_to_lines_n() {
	    local array
	    local n
	    local i

	    array=()
	    n="$RANDOM"

	    for (( i = 0; i < n; i++ )); do
		    array+=("$i")
	    done

	    i=$(array_to_lines "${array[@]}" | wc -l)

	    if (( n != i )); then
		    return 1
	    fi

	    return 0
    }

    When call _test_array_to_lines_n
    The status should equal 0
  End

  It "returns the lines in the correct order"
    _test_array_to_lines_order() {
	    local array
	    local n
	    local i
	    local line

	    array=()
	    n="$RANDOM"

	    for (( i = 0; i < n; i++ )); do
		    array+=("$i")
	    done

	    i=0

	    while read -r line; do
		    if (( line != i++ )); then
			    return 1
		    fi
	    done < <(array_to_lines "${array[@]}")

	    return 0
    }

    When call _test_array_to_lines_order
    The status should equal 0
  End
End

Describe "array_sort()"
  It "prints nothing if the array is empty"
    When call array_sort
    The status should equal 0
  End

  It "returns the same number of lines as the input has elements"
    _test_array_sort_num_elements() {
	    local array
	    local n
	    local i

	    array=()
	    n="$RANDOM"

	    for (( i = 0; i < n; i++ )); do
		    array+=("$i")
	    done

	    i=$(array_sort "${array[@]}" | wc -l)

	    if (( i != ${#array[@]} )); then
		    return 1
	    fi

	    return 0
    }

    When call _test_array_sort_num_elements
    The status should equal 0
  End

  It "returns elements in the same order as 'sort -V'"
    _test_array_sort_order() {
	    local array
	    local n
	    local i
	    local expectation
	    local reality

	    array=()
	    n=$((RANDOM % 1000))

	    for (( i = 0; i < n; i++ )); do
		    array+=("$RANDOM")
	    done

	    expectation=$(array_to_lines "${array[@]}" | sort -V)
	    reality=$(array_sort "${array[@]}")

	    if [[ "$expectation" != "$reality" ]]; then
		    return 1
	    fi

	    return 0
    }

    When call _test_array_sort_order
    The status should equal 0
  End
End

Describe "array_same()"
  It "returns success if the arrays are permutations"
    _test_array_same_permutation() {
	    local left
	    local right
	    local i
	    local n

	    left=()
	    right=()
	    n=$((RANDOM % 1000))

	    for (( i = 0; i <= n; i++ )); do
		    left+=("$i")
		    right+=("$((n - i))")
	    done

	    if ! array_same left right; then
		    return 1
	    fi

	    return 0
    }

    When call _test_array_same_permutation
    The status should equal 0
  End

  It "fails if the arrays contain different elements"
    _test_array_same_not_permutations() {
	    local left
	    local right
	    local n

	    left=()
	    right=()
	    n="$RANDOM"

	    left+=("0")
	    for (( i = 1; i < n; i++ )); do
		    left+=("$i")
		    right+=("$i")
	    done
	    right+=("$n")

	    if array_same left right; then
		    return 1
	    fi

	    return 0
    }

    When call _test_array_same_not_permutations
    The status should equal 0
  End
End

Describe "array_identical()"
  It "returns success if the arrays are identical"
    _test_array_identical_identical() {
	    local left
	    local right
	    local i
	    local n

	    left=()
	    right=()
	    n=$((RANDOM % 1000))

	    for (( i = 0; i < n; i++ )); do
		    left+=("$i")
		    right+=("$i")
	    done

	    if ! array_identical left right; then
		    return 1
	    fi

	    return 0
    }

    When call _test_array_identical_identical
    The status should equal 0
  End

  It "fails if the arrays are permutations"
    _test_array_identical_permutation() {
	    local left
	    local right
	    local i
	    local n

	    left=()
	    right=()
	    n=$((RANDOM % 1000))

	    for (( i = 0; i <= n; i++ )); do
		    left+=("$i")
		    right+=("$((n - i))")
	    done

	    if array_identical left right; then
		    return 1
	    fi

	    return 0
    }

    When call _test_array_identical_permutation
    The status should equal 0
  End

  It "fails if the arrays contain different elements"
    _test_array_identical_not_permutations() {
	    local left
	    local right
	    local n

	    left=()
	    right=()
	    n="$RANDOM"

	    left+=("0")
	    for (( i = 1; i < n; i++ )); do
		    left+=("$i")
		    right+=("$i")
	    done
	    right+=("$n")

	    if array_identical left right; then
		    return 1
	    fi

	    return 0
    }

    When call _test_array_identical_not_permutations
    The status should equal 0
  End
End
