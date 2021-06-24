#!/bin/bash

# clip.sh - Toolbox module for X11 clipboard manipulation
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

clip_get() {
	local sel="$1"

	if ! xclip -selection "$sel" -o 2>/dev/null; then
		return 1
	fi

	return 0
}

clip_get_any() {
	if clip_get "primary"; then
		return 0
	fi

	if clip_get "clipboard"; then
		return 0
	fi

	if clip_get "secondary"; then
		return 0
	fi

	return 1
}

clip_set() {
	local sel="$1"
	local data="$2"

	if (( $# < 2 )); then
		data=$(</dev/stdin)
	fi

	if ! printf "$data" | xclip -selection "$sel" 2>/dev/null; then
		return 1
	fi

	return 0
}

clip_swap() {
	local left="$1"
	local right="$2"

	local left_data

        left_data=$(clip_get "$left")
	clip_get "$right" | clip_set "$left"
	clip_set "$right" <<< "$left_data"

	return 0
}
