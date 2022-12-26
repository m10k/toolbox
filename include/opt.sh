#!/bin/bash

# opt.sh - Toolbox commandline parser module
# Copyright (C) 2021-2022 Matthias Kruk
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
	declare -xgir __opt_flag_is_array=6 # is_array implies has_value

	declare -xgAr __opt_flags_map=(
		["r"]="$__opt_flag_required"
		["v"]="$__opt_flag_has_value"
		["a"]="$__opt_flag_is_array"
	)

	declare -Axg __opt_short
	declare -Axg __opt_desc
	declare -Axg __opt_flags
	declare -Axg __opt_value
	declare -Axg __opt_default
	declare -Axg __opt_regex
	declare -Axg __opt_action
	declare -Axg __opt_map
	declare -Axg __opt_required

	opt_add_arg "h" "help" "" 0           \
		    "Print this text"         \
		    '' opt_print_help

	opt_add_arg "v" "verbose" "" 0        \
		    "Be more verbose"         \
		    '' log_increase_verbosity
	opt_add_arg "q" "quiet" "" 0          \
		    "Be less verbose"         \
		    '' log_decrease_verbosity

	return 0
}

_opt_is_defined() {
	local options=("$@")

	local option

	for option in "${options[@]}"; do
		if [[ -n "${__opt_map[$option]}" ]]; then
			log_error "Option \"$option\" was already declared"
			return 0
		fi
	done

	return 1
}

_opt_parse_flags() {
	local flags="$1"

	local -i parsed_flags
	local -i i

	for (( i = 0, parsed_flags = 0; i < ${#flags}; i++ )); do
		local flag_name
		local flag_value

		flag_name="${flags:$i:1}"
		flag_value="${__opt_flags_map[$flag_name]}"

		if (( flag_value == 0 )); then
			log_error "Invalid flag: $flag_name"
			return 1
		fi

		(( parsed_flags |= flag_value ))
	done

	echo "$parsed_flags"
	return 0
}

opt_add_arg() {
	local short="$1"
	local long="$2"
	local flags="$3"
	local default="$4"
	local desc="$5"
	local regex="${6-.*}"
	local action="${7-true}"

	local -i parsed_flags

	if _opt_is_defined "-$short" "--$long" ||
	   ! parsed_flags=$(_opt_parse_flags "$flags"); then
		return 1
	fi

	if (( ( parsed_flags & __opt_flag_is_array ) == __opt_flag_is_array )) &&
	   ! declare -p "$default" &>/dev/null; then
		log_error "Default value of array options must be the name of an array"
		return 1
	fi

	__opt_short["$long"]="$short"
	__opt_flags["$long"]="$parsed_flags"
	__opt_desc["$long"]="$desc"
	__opt_regex["$long"]="$regex"
	__opt_action["$long"]="$action"
	__opt_map["-$short"]="$long"
	__opt_map["--$long"]="$long"

	if [[ -n "$default" ]]; then
		__opt_default["$long"]="$default"
	fi

	if (( parsed_flags & __opt_flag_required )); then
		__opt_required["$long"]="$long"
	fi

	if ! (( parsed_flags & __opt_flag_has_value )); then
		__opt_value["$long"]=0
	fi

	return 0
}

opt_print_help() {
	local short

	echo "Usage: ${0##*/} [OPTIONS]"
	echo ""
	echo "Options"

	for short in $(array_sort "${__opt_short[@]}"); do
		local long
		local -i flags

		long="${__opt_map[-$short]}"
		flags="${__opt_flags[$long]}"

		printf "\t-%s\t--%s\t%s\n" \
		       "$short" "$long" "${__opt_desc[$long]}"
		if (( flags & __opt_flag_has_value )) &&
		   array_contains "$long" "${!__opt_default[@]}"; then
			if (( ( flags & __opt_flag_is_array ) == __opt_flag_is_array )); then
				local -n __opt_print_help_array="${__opt_default[$long]}"

				if (( ${#__opt_print_help_array[@]} > 0 )); then
					printf '\t\t\t(Default:\n'
					printf '\t\t\t     %s\n' "${__opt_print_help_array[@]}"
					printf '\t\t\t)\n'
				fi
			else
				printf '\t\t\t(Default: %s)\n' "${__opt_default[$long]}"
			fi
		fi
	done | column -s $'\t' -t

	return 2
}

_opt_have_required() {
	local option
	local -i err

	err=0

	for option in "${!__opt_required[@]}"; do
		log_error "Missing required option: --$option"
		err=1
	done

	return "$err"
}

opt_parse() {
	local argv=("$@")

	local -i err
	local -i i

	declare -argx __opt_argv=("${argv[@]}")

	err=0

	for (( i = 0; i < ${#argv[@]}; i++ )); do
		local param
		local long
		local flags
		local value
		local action

		param="${argv[$i]}"
		long="${__opt_map[$param]}"

		if [[ -z "$long" ]]; then
			log_error "Unrecognized parameter: $param"
			return 1
		fi

		flags="${__opt_flags[$long]}"
		action="${__opt_action[$long]}"

		if [[ -n "${__opt_required[$long]}" ]]; then
			unset __opt_required["$long"]
		fi

		if (( flags & __opt_flag_has_value )); then
			local regex

			if (( ++i >= ${#argv[@]} )); then
				log_error "Missing argument after $param"
				return 1
			fi

			value="${argv[$i]}"
			regex="${__opt_regex[$long]}"

			if ! [[ "$value" =~ $regex ]]; then
				log_error "Value \"$value\" doesn't match \"$regex\""
				return 1
			fi

			if (( ( flags & __opt_flag_is_array ) == __opt_flag_is_array )); then
				local -n __opt_parse_array="${__opt_default[$long]}"
				__opt_parse_array+=("$value")
			fi
		else
			value=$(( __opt_value[$long] + 1 ))
		fi

		__opt_value["$long"]="$value"

		"$action" "$long" "$value"
		err="$?"

		if (( err != 0 )); then
			return "$err"
		fi
	done

	if ! _opt_have_required; then
		return 1
	fi

	return "$err"
}

opt_get() {
	local long="$1"

	if array_contains "$long" "${!__opt_value[@]}"; then
		echo "${__opt_value[$long]}"
	elif array_contains "$long" "${!__opt_default[@]}"; then
		echo "${__opt_default[$long]}"
	elif [[ -n "${__opt_map[--$long]}" ]]; then
		return 2
	else
		return 1
	fi

	return 0
}

opt_get_argv() {
	if ! array_to_lines "${__opt_argv[@]}"; then
		return 1
	fi

	return 0
}
