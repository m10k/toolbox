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

signal_handler() {
	signal_received=1
}

main() {
	local endpoint
	local message
	declare -gi signal_received

	signal_received=0

	if ! opt_parse "$@"; then
		return 1
	fi

	if ! endpoint=$(ipc_endpoint_open); then
		return 1
	fi

	log_info "Using endpoint $endpoint"
	trap signal_handler INT TERM ABRT ALRM USR1 USR2

	while (( signal_received == 0 )) && read -r message; do
		local topic

		if ! topic=$(ipc_msg_get_topic "$message"); then
			log_warn "Dropping message without topic"
			continue
		fi

		if ! ipc_endpoint_publish "$endpoint" "$topic" "$message"; then
			log_error "Could not publish message for $topic on $endpoint"
		fi
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
