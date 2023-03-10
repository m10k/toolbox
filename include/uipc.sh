#!/bin/bash

# uipc.sh - Toolbox module for unsigned message-based IPC
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

__init() {
	if ! include "json" "queue"; then
		return 1
	fi

	declare -gxr  __uipc_root="/var/lib/toolbox/uipc"
	declare -gxr  __uipc_pubsub_root="$__uipc_root/pubsub"

	declare -gxir __uipc_version=1

	implements "ipc"

	return 0
}

uipc_get_root() {
	echo "$__uipc_root"
}

uipc_msg_get() {
	local msg="$1"
	local field="$2"

	local value

	if ! value=$(ipc_decode "$msg" | jq -e -r ".$field" 2>/dev/null); then
		return 1
	fi

	echo "$value"
	return 0
}

_uipc_msg_version_supported() {
	local msg="$1"

	local -i version

	if ! version=$(ipc_msg_get_version "$msg"); then
		log_error "Could not get version from message"
		return 1
	fi

	if (( version != __uipc_version )); then
		log_error "Unsupported message version"
		return 1
	fi

	return 0
}

uipc_msg_dump() {
	local msg="$1"

	local version
	local version_ok

	version_ok="no"
	version=$(ipc_msg_get_version "$msg" "version")

	if _uipc_msg_version_supported "$msg"; then
		version_ok="yes"
	fi

	cat <<EOF | log_highlight "uipc message"
Message version: $version [supported: $version_ok]

$(ipc_decode <<< "$msg" | jq .)
EOF

	return 0
}

uipc_msg_new() {
	local source="$1"
	local destination="$2"
	local data="$3"
	local topic="$4"

	# For non-pubsub messages, the topic will be unset. This will
	# cause the topic not to show up in the JSON object because
	# json_object() skips empty fields

	local encoded_data
	local timestamp
	local message
	local encoded_message

	if ! encoded_data=$(ipc_encode <<< "$data"); then
		log_error "Could not encode data"

	elif ! timestamp=$(date +"%s"); then
		log_error "Could not make timestamp"

	elif ! message=$(json_object "version"     "$__uipc_version" \
				     "source"      "$source"        \
				     "destination" "$destination"   \
				     "user"        "$USER"          \
				     "timestamp"   "$timestamp"     \
				     "topic"       "$topic"         \
				     "data"        "$encoded_data"); then
		log_error "Could not make message"

	elif ! encoded_message=$(ipc_encode "$message"); then
		log_error "Could not encode message"

	else
		echo "$encoded_message"
		return 0
	fi

	return 1
}
