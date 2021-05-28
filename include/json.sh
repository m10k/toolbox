#!/bin/bash

__init() {
	if ! include "log"; then
		return 1
	fi

	return 0
}

json_object() {
        local argc
        local i
        local nvps

        argc="$#"
        nvps=0

        if (( argc % 2 != 0 )); then
                log_error "Invalid number of arguments"
                return 1
        fi

        printf "{"
        for (( i = 1; i <= argc; i++ )); do
                local name
                local value

		local re_number
		local re_object
		local re_array

		re_number='^[0-9]+$'
		re_object='^\{.*\}$'
		re_array='^\[.*\]$'

                name="${!i}"
                ((i++))
                value="${!i}"

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

json_array() {
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

	for arg in "$@"; do
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

	if ! head=$(jq -e -r '.[0]' <<< "$array"); then
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
