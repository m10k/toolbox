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
	declare -gxr  __uipc_public="$__uipc_root/pub"
	declare -gxr  __uipc_private="$__uipc_root/priv/$USER"
	declare -gxr  __uipc_group="toolbox_ipc"
	declare -gxr  __uipc_pubsub_root="$__uipc_root/pubsub"

	declare -gxir __uipc_version=1

	if ! mkdir -p "$__uipc_private" ||
	   ! chgrp "$__uipc_group" "$__uipc_private"; then
		log_error "Could not initialize private UIPC directory $__uipc_private"
		return 1
	fi

	return 0
}

_uipc_encode() {
	local decoded="$1"

	if (( $# > 0 )); then
		base64 -w 0 <<< "$decoded"
	else
		base64 -w 0 < /dev/stdin
	fi
}

_uipc_decode() {
	local encoded="$1"

	if (( $# > 0 )); then
		base64 -d <<< "$encoded"
	else
		base64 -d < /dev/stdin
	fi
}


_uipc_msg_get() {
	local msg="$1"
	local field="$2"

	local value

	if ! value=$(_uipc_decode "$msg" | jq -e -r ".$field" 2>/dev/null); then
		return 1
	fi

	echo "$value"
	return 0
}

_uipc_msg_version_supported() {
	local msg="$1"

	local -i version

	if ! version=$(uipc_msg_get_version "$msg"); then
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
	version=$(_uipc_msg_get "$msg" "version")

	if _uipc_msg_version_supported "$msg"; then
		version_ok="yes"
	fi

	cat <<EOF | log_highlight "uipc message"
Message version: $version [supported: $version_ok]

$(_uipc_decode <<< "$msg" | jq .)
EOF

	return 0
}

_uipc_msg_new() {
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

	if ! encoded_data=$(_uipc_encode <<< "$data"); then
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

	elif ! encoded_message=$(_uipc_encode "$message"); then
		log_error "Could not encode message"

	else
		echo "$encoded_message"
		return 0
	fi

	return 1
}

uipc_msg_get_version() {
	local msg="$1"

	local version

	if ! version=$(_uipc_msg_get "$msg" "version"); then
		return 1
	fi

	echo "$version"
	return 0
}

uipc_msg_get_source() {
	local msg="$1"

	local src

	if ! src=$(_uipc_msg_get "$msg" "source"); then
		return 1
	fi

	echo "$src"
	return 0
}

uipc_msg_get_destination() {
	local msg="$1"

	local dst

	if ! dst=$(_uipc_msg_get "$msg" "destination"); then
		return 1
	fi

	echo "$dst"
	return 0
}

uipc_msg_get_user() {
	local msg="$1"

	local user

	if ! user=$(_uipc_msg_get "$msg" "user"); then
		return 1
	fi

	echo "$user"
	return 0
}

uipc_msg_get_timestamp() {
	local msg="$1"

	local timestamp

	if ! timestamp=$(_uipc_msg_get "$msg" "timestamp"); then
		return 1
	fi

	echo "$timestamp"
	return 0
}

uipc_msg_get_data() {
	local msg="$1"

	local data
	local data_raw

	if ! data=$(_uipc_msg_get "$msg" "data"); then
		return 1
	fi

	if ! data_raw=$(_uipc_decode <<< "$data"); then
		return 1
	fi

	echo "$data_raw"
	return 0
}

uipc_msg_get_topic() {
	local msg="$1"

	local topic

	if ! topic=$(_uipc_msg_get "$msg" "topic"); then
		return 1
	fi

	echo "$topic"
	return 0
}

uipc_endpoint_open() {
	local name="$1"

	local endpoint

	if [[ -z "$name" ]]; then
		local self

		self="${0##*/}"
		name="priv/$USER/$self.$$.$(date +"%s").$RANDOM"
	fi

	endpoint="$__uipc_root/$name"

	if ! [ -d "$endpoint" ]; then
		if ! mkdir -p "$endpoint/subscriptions"; then
			return 1
		fi

		if ! queue_init "$endpoint/queue" ||
		   ! echo "$USER" > "$endpoint/owner" ||
		   ! chmod -R g+rwxs "$endpoint"; then
			if ! rm -rf "$endpoint"; then
				log_error "Could not clean up $endpoint"
			fi

			return 1
		fi
	fi

	echo "$name"
	return 0
}

uipc_endpoint_close() {
	local name="$1"

	local endpoint
	local subscription

	endpoint="$__uipc_root/$name"

	if ! queue_destroy "$endpoint/queue"; then
		return 1
	fi

	while read -r subscription; do
		if ! rm "$subscription/${name//\//_}"; then
			log_error "Could not unsubscribe $name from $subscription"
		fi
	done < <(find "$endpoint/subscriptions" -mindepth 1 -maxdepth 1 -type l)

	if ! rm -rf "$endpoint"; then
		return 1
	fi

	return 0
}

_uipc_endpoint_put() {
	local endpoint="$1"
	local msg="$2"

	local queue

	queue="$__uipc_root/$endpoint/queue"

	if ! queue_put "$queue" "$msg"; then
		return 1
	fi

	return 0
}

_uipc_endpoint_get() {
	local endpoint="$1"
	local -i timeout="$2"

	local queue
	local msg

	queue="$__uipc_root/$endpoint/queue"

	if ! msg=$(queue_get "$queue" "$timeout"); then
		return 1
	fi

	echo "$msg"
	return 0
}

uipc_endpoint_send() {
	local source="$1"
	local destination="$2"
	local data="$3"
	local topic="$4"

	local msg

	if ! msg=$(_uipc_msg_new "$source" "$destination" "$data" "$topic"); then
		return 1
	fi

	if ! _uipc_endpoint_put "$destination" "$msg"; then
		return 1
	fi

	return 0
}

uipc_endpoint_recv() {
	local endpoint="$1"
	local -i timeout="$2"

	local -i start

	if (( $# < 2 )); then
		timeout=-1
	fi

	if ! start=$(date +"%s"); then
		return 2
	fi

	while true; do
		local msg
		local -i elapsed
		local -i remaining

		remaining="$timeout"

		if (( timeout > 0 )); then
			local now

			if ! now=$(date +"%s"); then
				return 2
			fi

			elapsed=$((now - start))
			remaining=$((timeout - elapsed))

			# Remaining must not be negative because _uipc_endpoint_get() takes
			# that to mean "block (possibly forever) until a message arrives"
			if (( remaining < 0 )); then
				remaining=0
			fi
		fi

		if msg=$(_uipc_endpoint_get "$endpoint" "$remaining"); then
			echo "$msg"
			return 0
		fi

		if (( remaining == 0 )); then
			break
		fi
	done

	return 1
}

_uipc_endpoint_topic_create() {
	local topic="$1"

	if ! mkdir -p "$__uipc_pubsub_root/$topic"; then
		return 1
	fi

	return 0
}

_uipc_endpoint_topic_subscribe() {
	local endpoint="$1"
	local topic="$2"

	local topicdir
	local subscription

	topicdir="$__uipc_pubsub_root/$topic"
	subscription="$topicdir/${endpoint//\//_}"

	if ! ln -sf "$endpoint" "$subscription"; then
		return 1
	fi

	if ! ln -sfn "$topicdir" "$__uipc_root/$endpoint/subscriptions/$topic"; then
		rm -f "$subscription"
		return 1
	fi

	return 0
}

_uipc_endpoint_topic_get_subscribers() {
	local topic="$1"

	local subscription

	while read -r subscription; do
		local subscriber

		if ! subscriber=$(readlink "$subscription"); then
			continue
		fi

		echo "$subscriber"
	done < <(find "$__uipc_pubsub_root/$topic" -mindepth 1 -maxdepth 1 -type l)

	return 0
}

uipc_endpoint_subscribe() {
	local endpoint="$1"
	local topic="$2"

	if ! _uipc_endpoint_topic_create "$topic"; then
		return 1
	fi

	if ! _uipc_endpoint_topic_subscribe "$endpoint" "$topic"; then
		return 1
	fi

	return 0
}

uipc_endpoint_publish() {
	local endpoint="$1"
	local topic="$2"
	local message="$3"

	local subscriber

	if ! _uipc_endpoint_topic_create "$topic"; then
		return 1
	fi

	while read -r subscriber; do
		uipc_endpoint_send "$endpoint" "$subscriber" "$message" "$topic"
	done < <(_uipc_endpoint_topic_get_subscribers "$topic")

	return 0
}

_uipc_endpoint_foreach_message_helper() {
	local msg="$1"
	local endpoint="$2"
	local func="$3"
	local args=("${@:4}")

	"$func" "$endpoint" "$msg" "${args[@]}"
	return "$?"
}

uipc_endpoint_foreach_message() {
	local endpoint="$1"
	local func="$2"
	local args=("${@:3}")

	local queue

	queue="$__uipc_root/$endpoint/queue"

	if ! queue_foreach "$queue" _uipc_endpoint_foreach_message_helper \
	                   "$endpoint" "$func" "${args[@]}"; then
		return 1
	fi

	return 0
}
