#!/bin/bash

__init() {
	return 0
}

array_contains() {
	local needle
	local haystack

	local cur

	needle="$1"
	haystack=("${@:2}")

	for cur in "${haystack[@]}"; do
		if [[ "$needle" == "$cur" ]]; then
			return 0
		fi
	done

	return 1
}
