#!/bin/bash

__init() {
	if ! include "log" "array"; then
		return 1
	fi

	declare -Axg __opt_short=()
	declare -Axg __opt_long=()
	declare -Axg __opt_desc=()
	declare -Axg __opt_flags=()
	declare -Axg __opt_value=()
	declare -Axg __opt_action=()
	declare -Axg __opt_map=()
	declare -xgi __opt_num=0
	declare -xgi __opt_longest=0

	opt_add_arg "h" "help" "no" 0 \
		    "Print this text" \
		    opt_print_help

	opt_add_arg "v" "verbose" "no" 0 \
		    "Be more verbose" \
		    log_increase_verbosity
	opt_add_arg "w" "shush" "no" 0 \
		    "Be less verbose" \
		    log_decrease_verbosity

	return 0
}

opt_add_arg() {
	local short
	local long
	local flags
	local default
	local desc
	local action

	local optlen

	short="$1"
	long="$2"
	flags="$3"
	default="$4"
	desc="$5"
	action="$6"

	if array_contains "$short" "${__opt_short[@]}" ||
	   array_contains "$long" "${__opt_long[@]}"; then
		return 1
	fi

	optlen="${#long}"

	__opt_short["$long"]="$short"
	__opt_long["$short"]="$long"
	__opt_flags["$long"]="$flags"
	__opt_desc["$long"]="$desc"
	__opt_value["$long"]="$default"
	__opt_action["$long"]="$action"

	__opt_map["-$short"]="$long"
	__opt_map["--$long"]="$long"

	if (( __opt_longest < optlen )); then
		__opt_longest=optlen;
	fi

	((__opt_num++))

	return 0
}

opt_print_help() {
	local short
	local shortopts

	shortopts=""

	for short in $(array_sort "${__opt_short[@]}"); do
		shortopts+="$short"
	done

	echo "Usage: $BASH_ARGV0 [-$shortopts]"
	echo ""
	echo "Options"

	for short in $(array_sort "${__opt_short[@]}"); do
		local long
		local desc
		local optlen
		local padding

		long="${__opt_long[$short]}"
		desc="${__opt_desc[$long]}"
		optlen="${#long}"
		padding=$((__opt_longest - optlen))

		printf " -%s  --%s %*s %s\n" \
		       "$short" "$long" "$padding" "" "$desc"
	done

	return 2
}

opt_parse() {
	local opt
	local i

	for (( i = 1; i <= $#; i++ )); do
		local param
		local long
		local flags
		local value
		local action

		param="${!i}"
		long="${__opt_map[$param]}"

		if [[ -z "$long" ]]; then
			log_error "Unrecognized parameter: $param"
			return 1
		fi

		flags="${__opt_flags[$long]}"
		action="${__opt_action[$long]}"

		if [[ "$flags" == "yes" ]]; then
			((i++))

			if (( i > $# )); then
				log_error "Missing argument after $param"
				return 1
			fi

			value="${!i}"
		else
			value="${__opt_value[$long]}"
			((value++))
		fi

		__opt_value["$long"]="$value"

		if ! [[ -z "$action" ]]; then
			local err

			"$action" "$long" "$value"
			err="$?"

			if (( err != 0 )); then
				return "$err"
			fi
		fi
	done

	return 0
}

opt_get() {
	local long

	long="$1"

	if ! array_contains "$long" "${!__opt_value[@]}"; then
		return 1
	fi

	echo "${__opt_value[$long]}"
	return 0
}
