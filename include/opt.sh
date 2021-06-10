#!/bin/bash

# opt.sh - Toolbox commandline parser module
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
	if ! include "log" "array"; then
		return 1
	fi

	declare -xgir __opt_flag_required=1
	declare -xgir __opt_flag_has_value=2

	declare -Axg __opt_short
	declare -Axg __opt_long
	declare -Axg __opt_desc
	declare -Axg __opt_flags
	declare -Axg __opt_value
	declare -Axg __opt_default
	declare -Axg __opt_action
	declare -Axg __opt_map
	declare -xgi __opt_num=0
	declare -xgi __opt_longest=0

	opt_add_arg "h" "help" "" 0 \
		    "Print this text" \
		    opt_print_help

	opt_add_arg "v" "verbose" "" 0 \
		    "Be more verbose" \
		    log_increase_verbosity
	opt_add_arg "q" "quiet" "" 0 \
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
	local num_flags
	local bflags
	local i

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

	num_flags="${#flags}"
	bflags=0

	for (( i = 0; i < num_flags; i++ )); do
		case "${flags:$i:1}" in
			"r")
				((bflags |= __opt_flag_required))
				;;

			"v")
				((bflags |= __opt_flag_has_value))
				;;

			*)
				return 1
				;;
		esac
	done

	optlen="${#long}"

	__opt_short["$long"]="$short"
	__opt_long["$short"]="$long"
	__opt_flags["$long"]="$bflags"
	__opt_desc["$long"]="$desc"
	__opt_default["$long"]="$default"
	__opt_action["$long"]="$action"

	__opt_map["-$short"]="$long"
	__opt_map["--$long"]="$long"

	if (( __opt_longest < optlen )); then
		__opt_longest="$optlen"
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
	local optname
	local err
	local i

	declare -argx __opt_argv=("$@")

	err=0

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

		if (( flags & __opt_flag_has_value )); then
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

		if [[ -n "$action" ]]; then
			local err

			"$action" "$long" "$value"
			err="$?"

			if (( err != 0 )); then
				return "$err"
			fi
		fi
	done

	for optname in "${__opt_long[@]}"; do
		local flags

		flags="${__opt_flags[$optname]}"

		if ! (( flags & __opt_flag_required )); then
			continue
		fi

		if ! array_contains "$optname" "${!__opt_value[@]}"; then
			log_error "Missing required argument: $optname"
			err=1
		fi
	done

	return "$err"
}

opt_get() {
	local long

	long="$1"

	if array_contains "$long" "${!__opt_value[@]}"; then
		echo "${__opt_value[$long]}"
	else
		echo "${__opt_default[$long]}"
	fi

	return 0
}

opt_get_argv() {
	echo "${__opt_argv[@]}"
	return 0
}
