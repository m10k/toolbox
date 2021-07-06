#!/bin/bash

# json.sh - JSON generator functions for Toolbox
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
	if ! include "log"; then
		return 1
	fi

	return 0
}

json_object() {
	local args=("$@")

        local i
        local nvps

        nvps=0

        if (( ${#args[@]} % 2 != 0 )); then
                log_error "Invalid number of arguments"
                return 1
        fi

        printf "{"
        for (( i = 0; i < ${#args[@]}; i++ )); do
                local name
                local value

		local re_number
		local re_object
		local re_array

		re_number='^[0-9]+$'
		re_object='^\{.*\}$'
		re_array='^\[.*\]$'

                name="${args[$i]}"
                ((i++))
                value="${args[$i]}"

                if [ -z "$name" ] || [ -z "$value" ]; then
                        continue
                fi

                if (( nvps > 0 )); then
                        printf ', '
                fi

                if [[ "$value" =~ $re_number ]]; then
                        printf '"%s": %d' "$name" "$value"

		elif [[ "$value" =~ $re_object ]] ||
		     [[ "$value" =~ $re_array ]]; then
                        printf '"%s": %s' "$name" "$value"

                else
                        printf '"%s": "%s"' "$name" "$value"
                fi

                ((nvps++))
        done
        printf "}\n"

        return 0
}

json_object_get() {
	local object="$1"
	local field="$2"

	local value

	value=$(jq -e -r ".$field" <<< "$object")

	if (( $? > 1 )); then
		return 1
	fi

	echo "$value"
	return 0
}

json_array() {
	local args=("$@")

	local arg
	local n

	local re_number
	local re_object
	local re_array

	re_number='^[0-9]+$'
	re_object='^\{.*\}$'
	re_array='^\[.*\]$'

	printf "["
	n=0

	for arg in "${args[@]}"; do
		if [ -z "$arg" ]; then
			continue
		fi

		if (( n > 0 )); then
			printf ", "
		fi

		if [[ "$arg" =~ $re_number ]]; then
			printf '%d' "$arg"

		elif [[ "$arg" =~ $re_object ]] ||
		     [[ "$arg" =~ $re_array ]]; then
			printf '%s' "$arg"

		else
			printf '"%s"' "$arg"
		fi

		((n++))
	done
	printf "]\n"

	return 0
}

json_array_head() {
	local array="$1"

	local head

	head=$(jq -e -r '.[0]' <<< "$array")

	if (( $? > 1 )); then
		return 1
	fi

	echo "$head"
	return 0
}

json_array_tail() {
	local array="$1"

	local tail
	local element
	local new

	tail=()

	while read -r element; do
		tail+=("$element")
	done < <(jq -r '.[1:][]' <<< "$array")

	if ! new=$(json_array "${tail[@]}"); then
		return 1
	fi

	echo "$new"
	return 0
}

json_array_to_lines() {
	local array="$1"

        if ! jq -r '.[]' <<< "$array"; then
		return 1
	fi

	return 0
}
