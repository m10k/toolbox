#!/bin/bash

# ipc-tap.sh - Interceptor for toolbox IPC PubSub messages
# Copyright (C) 2022-2023 Matthias Kruk
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

add_topic() {
	# local name="$1" # not needed
	local value="$2"

	# topics is inherited from main() via opt_parse()
	topics+=("$value")
	return 0
}

add_hook() {
	# local name="$1" # not needed
	local value="$2"

	local topic
	local hook

	topic="${value%%:*}"
	hook="${value#*:}"

	# hooks is inherited from main() via opt_parse()
	hooks["$topic"]="$hook"
}

signal_handler() {
	signal_received=1
}

output_message() {
	local type="$1"
	local data="$2"

	local message

	if ! message=$(json_object "type" "$type" \
	                           "data" "$data"); then
		return 1
	fi

	if ! base64 -w 0 <<< "$message"; then
		return 1
	fi

	printf '\n'
	return 0
}

invoke_hooks() {
	local topic="$1"
	local message="$2"

	local data
	local hook

	hook="${hooks[$topic]}"

	if [[ -n "$hook" ]] &&
	   data=$("$hook" <<< "$message") &&
	   [[ -n "$data" ]]; then
		output_message "HookData" "$data"
	fi

	return 0
}

tap_topics() {
	local endpoint_name="$1"
	local topics=("${@:2}")

	local endpoint
	local topic
	local -i err
	local -ig signal_received

	err=0
	signal_received=0

	if ! endpoint=$(ipc_endpoint_open "$endpoint_name"); then
		return 1
	fi

	log_info "Using endpoint $endpoint"
	trap signal_handler INT HUP TERM ABRT ALRM USR1 USR2 PIPE

	for topic in "${topics[@]}"; do
		log_info "Subscribing $endpoint to $topic"

		if ! ipc_endpoint_subscribe "$endpoint" "$topic"; then
			log_error "Could not subscribe $endpoint to $topic"
			err=1
			break
		fi
	done

	if (( err == 0 )); then
		log_info "Waiting for messages"

		while (( signal_received == 0 )); do
			local message
			local topic

			if ! message=$(ipc_endpoint_recv "$endpoint" 5); then
				continue
			fi

			if ! topic=$(ipc_msg_get_topic "$message"); then
				log_warn "Dropping message without topic"
				continue
			fi

			invoke_hooks "$topic" "$message"
			output_message "IPCMessage" "$message"
		done
	fi

	log_info "Closing endpoint $endpoint"
	ipc_endpoint_close "$endpoint"

	return "$err"
}

main() {
	local endpoint
	local proto
	local topics
	declare -gA hooks

	topics=()

	opt_add_arg "t" "topic"    "rv" ""         \
	            "A topic to tap into"          \
	            ''                             \
	            add_topic
	opt_add_arg "k" "hook"     "v"  ""         \
	            "Hook to execute upon receipt" \
	            '^[^:]+:.+$'                   \
	            add_hook
	opt_add_arg "p" "proto"    "v"  "ipc"      \
	            "The IPC protocol to tap"      \
	            '^u?ipc$'
	opt_add_arg "e" "endpoint" "v"  ""         \
	            "The IPC endpoint to use"

	if ! opt_parse "$@"; then
		return 1
	fi

	proto=$(opt_get "proto")
	if ! include "$proto"; then
		return 1
	fi

	endpoint=$(opt_get "endpoint")
	if ! tap_topics "$endpoint" "${topics[@]}"; then
		return 1
	fi

	return 0
}

{
	if ! . toolbox.sh; then
		exit 1
	fi

	if ! include "log" "opt" "json"; then
		exit 1
	fi

	main "$@"
	exit "$?"
}
