#!/bin/bash

# ipc-sshtunnel.sh - Tunnel toolbox PubSub IPC messages over SSH
# Copyright (C) 2022 Matthias Kruk
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

_array_add() {
	local name="$1"
	local value="$2"

	declare -A map

	# input_topics is inherited from main() via opt_parse()
	# output_topics is inherited from main() via opt_parse()
	# tap_hooks is inherited from main() via opt_parse()
	# inject_hooks is inherited from main() via opt_parse()
	map["input-topic"]=input_topics
	map["output-topic"]=output_topics
	map["tap-hook"]=tap_hooks
	map["inject-hook"]=inject_hooks

	if array_contains "$name" "${!map[@]}"; then
		declare -n target_array="${map[$name]}"
		target_array+=("$value")
	else
		log_error "Invalid option name: $name"
		return 1
	fi

	return 0
}

establish_ipc_tunnel() {
	local direction="$1"
	local remote="$2"
	local -n ref_topics="$3"
	local -n ref_tap_hooks="$4"
	local -n ref_inject_hooks="$5"

	local topic
	local hook
	local tap_args
	local inject_args

	for topic in "${ref_topics[@]}"; do
		tap_args+=(--topic "$topic")
	done

	for hook in "${ref_tap_hooks[@]}"; do
		tap_args+=(--hook "$hook")
	done

	for hook in "${ref_inject_hooks[@]}"; do
		inject_args+=(--hook "$hook")
	done

	case "$direction" in
		"in")
			( ssh -n "$remote" ipc-tap "${tap_args[@]}" | ipc-inject "${inject_args[@]}" ) &
			;;
		"out")
			( ipc-tap "${tap_args[@]}" | ssh "$remote" ipc-inject "${inject_args[@]}" ) &
			;;
		*)
			log_error "Invalid direction: $direction"
			return 1
			;;
	esac

	echo "$!"
	return 0
}

process_is_running() {
	local -i pid="$1"

	kill -0 "$pid" &>/dev/null
	return "$?"
}

spawn_tunnel() {
	local direction="$1"
	local remote="$2"
	local ref_topics="$3"
	local ref_tap_hooks="$4"
	local ref_inject_hooks="$5"

	local -i tunnel

	if tunnel=$(establish_ipc_tunnel "$direction" "$remote" "$ref_topics" "$ref_tap_hooks" "$ref_inject_hooks"); then
		while inst_running && process_is_running "$tunnel"; do
			sleep 5
		done

		kill "$tunnel" &>/dev/null
	else
		return 1
	fi

	return 0
}

main() {
	declare -gxa input_topics
	declare -gxa output_topics
	declare -gxa tap_hooks
	declare -gxa inject_hooks
	local remote

	input_topics=()
	output_topics=()
	tap_hooks=()
	inject_hooks=()

	opt_add_arg "i" "input-topic"  "v"  "" "Topic to relay from the remote side (may be used more than once)" \
	            "" _array_add
	opt_add_arg "o" "output-topic" "v"  "" "Topic to relay to the remote side (may be used more than once)"   \
	            "" _array_add
	opt_add_arg "T" "tap-hook"     "v"  "" "Hook to pass to ipc-tap"                                          \
	            "" _array_add
	opt_add_arg "I" "inject-hook"  "v"  "" "Hook to pass to ipc-inject"                                       \
	            "" _array_add
	opt_add_arg "r" "remote"       "rv" "" "Address of the remote side"

	if ! opt_parse "$@"; then
		return 1
	fi

	remote=$(opt_get "remote")

	if ! inst_start spawn_tunnel "in"  "$remote" input_topics  tap_hooks inject_hooks ||
	   ! inst_start spawn_tunnel "out" "$remote" output_topics tap_hooks inject_hooks; then
		return 1
	fi

	return 0
}

{
	if ! . toolbox.sh; then
		exit 1
	fi

	if ! include "log" "opt" "inst" "ipc"; then
		exit 1
	fi

	main "$@"
	exit "$?"
}
