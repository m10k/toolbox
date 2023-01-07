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
	if ! include "log" "is" "array"; then
		return 1
	fi

	declare -gxir __json_type_integer=0
	declare -gxir __json_type_string=1
	declare -gxir __json_type_bool=2
	declare -gxir __json_type_float=3
	declare -gxir __json_type_object=4
	declare -gxir __json_type_array=5

	return 0
}

_json_guess_type() {
	local input="$1"

	local re_number
	local re_float
	local re_object
	local re_array

	re_number='^[-+]{,1}[0-9]+$'
	re_float='^[-+]{,1}([0-9]*\.[0-9]+|[0-9]+\.[0-9]*)$'
	re_object='^\{.*\}$'
	re_array='^\[.*\]$'

	if [[ "$input" =~ $re_number ]]; then
		echo "$__json_type_integer"

	elif [[ "$input" =~ $re_object ]]; then
	        echo "$__json_type_object"

	elif [[ "$input" =~ $re_array ]]; then
	        echo "$__json_type_array"

	elif [[ "$input" =~ $re_float ]]; then
	        echo "$__json_type_float"

	elif [[ "$input" == "true" ]] ||
	     [[ "$input" == "false" ]]; then
	        echo "$__json_type_bool"

	else
	        echo "$__json_type_string"
	fi

	return 0
}

_json_get_type() {
	local input="$1"

	declare -A type_map
	local type_prefix
	local type
	local output

	type_map["s:"]="$__json_type_string"
	type_map["i:"]="$__json_type_integer"
	type_map["b:"]="$__json_type_bool"
	type_map["f:"]="$__json_type_float"
	type_map["o:"]="$__json_type_object"
	type_map["a:"]="$__json_type_array"

	type_prefix="${input:0:2}"

	if array_contains "$type_prefix" "${!type_map[@]}"; then
		type="${type_map[$type_prefix]}"
		output="${input:2}"
	else
		type=$(_json_guess_type "$input")
	        output="$input"
	fi

	echo "$output"
	return "$type"
}

_json_print_value() {
	local value="$1"

	local value_raw
	local output

	value_raw=$(_json_get_type "$value")
	case "$?" in
		"$__json_type_integer")
			if ! output=$(printf '%d' "$value_raw"); then
				return 1
			fi
			;;

		"$__json_type_float")
			if ! output=$(printf '%f' "$value_raw"); then
				return 1
			fi
			;;

		"$__json_type_bool"|"$__json_type_object"|"$__json_type_array")
			if ! output=$(printf '%s' "$value_raw"); then
				return 1
			fi
			;;

		"$__json_type_string")
			if ! output=$(printf '"%s"' "$value_raw"); then
				return 1
			fi
			;;

		*)
			return 1
			;;
        esac

	echo "$output"
	return 0
}

json_object() {
	local args=("$@")

	local i
	local nvps
	local output

	nvps=0
	output="{"

	if (( ${#args[@]} % 2 != 0 )); then
		log_error "Invalid number of arguments"
		return 1
	fi

	for (( i = 0; i < ${#args[@]}; i++ )); do
		local name
		local value
		local value_raw

		name="${args[$i]}"
		((i++))
		value="${args[$i]}"

		if [ -z "$name" ] || [ -z "$value" ]; then
			continue
		fi

		if (( nvps > 0 )); then
			output+=", "
		fi

		if ! value_raw=$(_json_print_value "$value"); then
			return 1
		fi

		if ! output+=$(printf '"%s": %s' "$name" "$value_raw"); then
			return 1
		fi

		((nvps++))
	done
	output+="}"

	printf "%s\n" "$output"
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

	local output
	local arg
	local n

	output="["
	n=0

	for arg in "${args[@]}"; do
		if [ -z "$arg" ]; then
			continue
		fi

		if (( n > 0 )); then
			output+=", "
		fi

		if ! output+=$(_json_print_value "$arg"); then
			return 1
		fi

		((n++))
	done
	output+="]"

	printf "%s\n" "$output"

	return 0
}

json_array_head() {
	local array="$1"

	local head
	local string_re

	string_re='^"(.*)"$'

	if ! head=$(jq '.[0]' <<< "$array") ||
	   [[ "$head" == "null" ]]; then
		return 1
	fi

	if [[ "$head" =~ $string_re ]]; then
		echo "${BASH_REMATCH[1]}"
	else
		echo "$head"
	fi

	return 0
}

json_array_tail() {
	local array="$1"

	local tail
	local element
	local new
	local string_re

	string_re='^"(.*)"$'
	tail=()

	while read -r element; do
		if [[ "$element" =~ $string_re ]]; then
			tail+=("${BASH_REMATCH[1]}")
		else
			tail+=("$element")
		fi
	done < <(jq -c '.[1:][]' <<< "$array")

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
