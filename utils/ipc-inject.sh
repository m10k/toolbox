#!/bin/bash

# ipc-inject.sh - Injector for toolbox IPC PubSub messages
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

add_hook() {
	# local name="$1" # not used
	local value="$2"

	local tag
	local handler

	tag="${value%%:*}"
	handler="${value#*:}"

	hooks["$tag"]="$handler"
	return 0
}

signal_handler() {
	signal_received=1
}

handle_hook_data() {
	local endpoint="$1"
	local hook_data="$2"

	local tag
	local data
	local handler

	if ! tag=$(json_object_get "$hook_data" "tag"); then
		log_warn "Dropping message without tag"
		return 1
	fi

	handler="${hooks[$tag]}"

	if [[ -z "$handler" ]]; then
		log_warn "No handler for tag $tag"
		return 0
	fi

	if ! data=$(json_object_get "$hook_data" "data"); then
		log_warn "Dropping message without data"
		return 1
	fi

	if ! "$handler" <<< "$data"; then
		return 1
	fi

	return 0
}

handle_ipc_message() {
	local endpoint="$1"
	local message="$2"

	local topic
	local data

	if ! topic=$(ipc_msg_get_topic "$message"); then
		log_warn "Dropping message without topic"
		return 1
	fi

	if ! data=$(ipc_msg_get_data "$message"); then
		log_warn "Dropping message without data"
		return 1
	fi

	if ! ipc_endpoint_publish "$endpoint" "$topic" "$data"; then
		log_error "Could not publish message for $topic on $endpoint"
		return 1
	fi

	return 0
}

handle_message() {
	local endpoint="$1"
	local message="$2"

	local decoded
	local type
	local data
	local handler

	if ! decoded=$(base64 -d <<< "$message"); then
		log_warn "Could not decode message"
		return 1
	fi

	if ! type=$(json_object_get "$decoded" "type") ||
	   ! data=$(json_object_get "$decoded" "data"); then
		log_warn "Could not parse message"
		return 1
	fi

	handler="${message_handler[$type]}"

	if [[ -n "$handler" ]]; then
		"$handler" "$endpoint" "$data"
	fi

	return 0
}

main() {
	local endpoint
	local message
	declare -gA hooks
	declare -gi signal_received
	declare -gA message_handler

	message_handler["HookData"]=handle_hook_data
	message_handler["IPCMessage"]=handle_ipc_message

	signal_received=0

	opt_add_arg "k" "hook" "v" ""                \
	            "Command for handling hook data" \
	            '^[^:]+:.*$'                     \
	            add_hook

	if ! opt_parse "$@"; then
		return 1
	fi

	if ! endpoint=$(ipc_endpoint_open); then
		return 1
	fi

	log_info "Using endpoint $endpoint"
	trap signal_handler INT TERM ABRT ALRM USR1 USR2

	while (( signal_received == 0 )) && read -r message; do
		handle_message "$endpoint" "$message"
	done

	log_info "Closing endpoint $endpoint"
	ipc_endpoint_close "$endpoint"

	return 0
}

{
	if ! . toolbox.sh; then
		exit 1
	fi

	if ! include "log" "opt" "ipc"; then
		exit 1
	fi

	main "$@"
	exit "$?"
}
