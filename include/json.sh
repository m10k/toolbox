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

                name="${!i}"
                ((i++))
                value="${!i}"

                if [ -z "$name" ] || [ -z "$value" ]; then
                        continue
                fi

                if (( nvps > 0 )); then
                        printf ', '
                fi

                if [[ "$value" =~ ^[0-9]+$ ]]; then
                        printf '"%s": %d' "$name" "$value"
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

	printf "["
	n=0

	for arg in "$@"; do
		if [ -z "$arg" ]; then
			continue
		fi

		if (( n > 0 )); then
			printf ", "
		fi

		if [[ "$arg" =~ ^[0-9]+$ ]]; then
			printf '%d' "$arg"
		else
			printf '"%s"' "$arg"
		fi

		((n++))
	done
	printf "]\n"

	return 0
}
