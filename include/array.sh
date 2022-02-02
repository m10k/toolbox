#!/bin/bash

# array.sh - Array functions for toolbox
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
	return 0
}

array_contains() {
	local needle="$1"
	local haystack=("${@:2}")

	local cur

	for cur in "${haystack[@]}"; do
		if [[ "$needle" == "$cur" ]]; then
			return 0
		fi
	done

	return 1
}

array_to_lines() {
	local array=("$@")

	# Don't print an empty line if array is empty
	if (( ${#array[@]} > 0 )); then
		printf "%s\n" "${array[@]}"
	fi
}

array_sort() {
	local array=("$@")

	array_to_lines "${array[@]}" | sort -V
}

array_same() {
	local -n _array_same_left="$1"
	local -n _array_same_right="$2"

	local element

	if (( ${#_array_same_left[@]} != ${#_array_same_right[@]} )); then
		return 1
	fi

	for element in "${_array_same_left[@]}"; do
		if ! array_contains "$element" "${_array_same_right[@]}"; then
			return 1
		fi
	done

	for element in "${_array_same_right[@]}"; do
		if ! array_contains "$element" "${_array_same_left[@]}"; then
			return 1
		fi
	done

	return 0
}

array_identical() {
	local -n _array_identical_left="$1"
	local -n _array_identical_right="$2"

	local i

	if (( ${#_array_identical_left[@]} != ${#_array_identical_right[@]} )); then
		return 1
	fi

	for (( i = 0; i < ${#_array_identical_left[@]}; i++ )); do
		if [[ "${_array_identical_left[$i]}" != "${_array_identical_right[$i]}" ]]; then
			return 1
		fi
	done

	return 0
}
