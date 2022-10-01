#!/bin/bash

# ipc-tap.sh - Interceptor for toolbox IPC PubSub messages
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

add_topic() {
	# local name="$1" # not needed
	local value="$2"

	# topics is inherited from main() via opt_parse()
	topics+=("$value")
	return 0
}

signal_handler() {
	signal_received=1
}

tap_topics() {
	local topics=("$@")

	local endpoint
	local topic
	local -i err
	local -ig signal_received

	err=0
	signal_received=0

	if ! endpoint=$(ipc_endpoint_open); then
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

			if message=$(ipc_endpoint_recv "$endpoint" 5); then
				printf '%s\n' "$message"
			fi
		done
	fi

	log_info "Closing endpoint $endpoint"
	ipc_endpoint_close "$endpoint"

	return "$err"
}

main() {
	local topics

	topics=()

	opt_add_arg "t" "topic" "rv" "" "A topic to tap into" "" add_topic

	if ! opt_parse "$@"; then
		return 1
	fi

	if ! tap_topics "${topics[@]}"; then
		return 1
	fi

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
