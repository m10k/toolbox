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
	local item

	for item in "${array[@]}"; do
		echo "$item"
	done
}

array_sort() {
	local array=("$@")

	array_to_lines "${array[@]}" | sort -V
}
