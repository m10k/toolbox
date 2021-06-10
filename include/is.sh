#!bin/bash

# is.sh - ctype-style functions for Toolbox
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

is_digits() {
	local str

	str="$1"

	if [[ "$str" =~ ^[0-9]+$ ]]; then
		return 0
	fi

	return 1
}

is_hex() {
	local str

	str="$1"

	if [[ "$str" =~ ^[0-9a-fA-F]+$ ]]; then
		return 0
	fi

	return 1
}

is_upper() {
	local str

	str="$1"

	if [[ "$str" =~ ^[A-Z]+$ ]]; then
		return 0
	fi

	return 1
}

is_lower() {
	local str

	str="$1"

	if [[ "$str" =~ ^[a-z]+$ ]]; then
		return 0
	fi

	return 1
}

is_alpha() {
	local str

	str="$1"

	if [[ "$str" =~ ^[a-zA-Z]+$ ]]; then
		return 0
	fi

	return 1
}

is_alnum() {
	local str

	str="$1"

	if [[ "$str" =~ ^[a-zA-Z0-9]+ ]]; then
		return 0
	fi

	return 1
}
