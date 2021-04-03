#!/bin/bash

__init() {
	return 0
}

clip_get() {
	local sel

	sel="$1"

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
	local sel
	local data

	sel="$1"
	data="$2"

	if (( $# < 2 )); then
		data=$(</dev/stdin)
	fi

	if ! printf "$data" | xclip -selection "$sel" 2>/dev/null; then
		return 1
	fi

	return 0
}

clip_swap() {
	local left
	local right

	local left_data

	left="$1"
	right="$2"

        left_data=$(clip_get "$left")
	clip_get "$right" | clip_set "$left"
	clip_set "$right" <<< "$left_data"

	return 0
}
