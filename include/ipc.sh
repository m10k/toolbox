#!/bin/bash

__init() {
	if ! include "json" "queue"; then
		return 1
	fi

	declare -gxr  __ipc_root="/var/lib/toolbox/ipc"
	declare -gxr  __ipc_public="$__ipc_root/pub"
	declare -gxr  __ipc_private="$__ipc_root/priv/$USER"
	declare -gxr  __ipc_group="toolbox_ipc"

	declare -gxi  __ipc_authentication=1
	declare -gxir __ipc_version=1

	if ! mkdir -p "$__ipc_private" ||
	   ! chgrp "$__ipc_group" "$__ipc_private"; then
		log_error "Could not initialize private IPC directory $__ipc_private"
		return 1
	fi

	return 0
}

_ipc_msg_encode() {
	local decoded="$1"

	if (( $# > 0 )); then
		base64 -w 0 <<< "$decoded"
	else
		base64 -w 0 < /dev/stdin
	fi
}

_ipc_msg_decode() {
	local encoded="$1"

	if (( $# > 0 )); then
		base64 -d <<< "$encoded"
	else
		base64 -d < /dev/stdin
	fi
}

ipc_authentication_enable() {
	log_info "MESSAGE AUTHENTICATION ENABLED"
	__ipc_authentication=1
	return 0
}

ipc_authentication_disable() {
	log_error "MESSAGE AUTHENTICATION DISABLED"
	__ipc_authentication=0
	return 0
}

_ipc_msg_get() {
	local msg="$1"
	local field="$2"

	local value

	if ! value=$(_ipc_msg_decode "$msg" | jq -e -r ".$field" 2>/dev/null); then
		return 1
	fi

	echo "$value"
	return 0
}

_ipc_msg_get_signature() {
	local msg="$1"

	local data
	local signature
	local output

	data=$(_ipc_msg_get "$msg" "data")
	signature=$(_ipc_msg_get "$msg" "signature")

	if ! gpg --verify <(base64 -d <<< "$signature") <(echo "$data") 2>&1; then
		return 1
	fi

	return 0
}

_ipc_msg_verify() {
	local msg="$1"

	local error

	if ! error=$(_ipc_msg_get_signature "$msg"); then
		log_error "Invalid signature on message"
		log_highlight "GPG output" <<< "$error" | log_error
		return 1
	fi

	return 0
}

_ipc_msg_version_supported() {
	local msg="$1"

	local -i version

	if ! version=$(_ipc_msg_get "$msg" "version"); then
		log_error "Could not get version from message"
		return 1
	fi

	if (( version != __ipc_version )); then
		log_error "Unsupported message version"
		return 1
	fi

	return 0
}

ipc_msg_validate() {
	local msg="$1"

	if (( __ipc_authentication == 1 )) &&
	   ! _ipc_msg_verify "$msg"; then
		return 1
	fi

	if ! _ipc_msg_version_supported "$msg"; then
		return 2
	fi

	return 0
}

ipc_msg_get_signature_info() {
	local msg="$1"

	local signature

	local sig_nameregex
	local sig_keyregex

	local sig_valid
	local sig_name
	local sig_email
	local sig_key

	sig_nameregex='"(.*) <([^>]*)>"'
	sig_keyregex='([0-9a-fA-F]{32,})'

	sig_valid="bad"
	sig_name="(unknown)"
	sig_email="(unknown)"
	sig_key="(unknown)"

	if signature=$(_ipc_msg_get_signature "$msg"); then
		sig_valid="good"
	fi

	if [[ "$signature" =~ $sig_nameregex ]]; then
		sig_name="${BASH_REMATCH[1]}"
		sig_email="${BASH_REMATCH[2]}"
	fi

	if [[ "$signature" =~ $sig_keyregex ]]; then
		sig_key="${BASH_REMATCH[1]}"
	fi

	echo "$sig_valid $sig_key $sig_email $sig_name"
	return 0
}

ipc_msg_get_signing_key() {
	local msg="$1"

	local signature
	local keyregex

	keyregex='([0-9a-fA-F]{32,})'

	if ! signature=$(_ipc_msg_get_signature "$msg"); then
		return 1
	fi

	if [[ "$signature" =~ $keyregex ]]; then
		echo "${BASH_REMATCH[1]}"
		return 0
	fi

	return 1
}

ipc_msg_dump() {
	local msg="$1"

	local version
	local data
	local signature

	local version_ok
	local signature_ok
	local validation_status

	version=$(_ipc_msg_get "$msg" "version")
	data=$(_ipc_msg_get "$msg" "data")
	signature=$(_ipc_msg_get "$msg" "signature")

	version_ok="no"
	signature_ok="no"
	validation_status="disabled"

	if _ipc_msg_version_supported "$msg"; then
		version_ok="yes"
	fi

	if _ipc_msg_verify "$msg"; then
		signature_ok="yes"
	fi

	if (( __ipc_authentication == 1 )); then
		validation_status="enabled"
	fi

	cat <<EOF | log_highlight "ipc message"
Message version: $version [supported: $version_ok]
Signature valid: $signature_ok [validation: $validation_status]
$(ipc_msg_get_signature_info "$msg")
$(_ipc_msg_decode <<< "$msg" | jq .)
EOF
	return 0
}

ipc_msg_new() {
	local source="$1"
	local destination="$2"
	local data_raw="$3"

	local message
	local signature
	local encoded
	local data
	local timestamp

	if ! data=$(_ipc_msg_encode <<< "$data_raw"); then
		log_error "Could not encode message data"
		return 1
	fi

	if ! timestamp=$(date +"%s"); then
		log_error "Could not make timestamp"
		return 1
	fi

	if (( __ipc_authentication == 1 )); then
		if ! signature=$(gpg --output - --detach-sig <(echo "$data") |
					 _ipc_msg_encode); then
			log_error "Could not make signature"
			return 1
		fi
	else
		signature="-"
	fi

	if ! message=$(json_object "version"     "$__ipc_version" \
				   "source"      "$source"        \
				   "destination" "$destination"   \
				   "user"        "$USER"          \
				   "timestamp"   "$timestamp"     \
				   "data"        "$data"          \
				   "signature" "$signature"); then
		log_error "Could not make JSON object"
		return 1
	fi

	if ! encoded=$(_ipc_msg_encode "$message"); then
		log_error "Could not encode message"
		return 1
	fi

	echo "$encoded"
	return 0
}

ipc_msg_get_source() {
	local msg="$1"

	local src

	if ! src=$(_ipc_msg_get "$msg" "source"); then
		return 1
	fi

	echo "$src"
	return 0
}

ipc_msg_get_destination() {
	local msg="$1"

	local dst

	if ! dst=$(_ipc_msg_get "$msg" "destination"); then
		return 1
	fi

	echo "$dst"
	return 0
}

ipc_msg_get_data() {
	local msg="$1"

	local data
	local data_raw

	if ! data=$(_ipc_msg_get "$msg" "data"); then
		return 1
	fi

	if ! data_raw=$(_ipc_msg_decode <<< "$data"); then
		return 1
	fi

	echo "$data_raw"
	return 0
}

ipc_msg_get_user() {
	local msg="$1"

	local user

	if ! user=$(_ipc_msg_get "$msg" "user"); then
		return 1
	fi

	echo "$user"
	return 0
}

ipc_msg_get_timestamp() {
	local msg="$1"

	local timestamp

	if ! timestamp=$(_ipc_msg_get "$msg" "timestamp"); then
		return 1
	fi

	echo "$timestamp"
	return 0
}

ipc_endpoint_new() {
	local name="$1"

	local endpoint

	if [[ -z "$name" ]]; then
		local self

		self="${0##*/}"
		name="priv/$USER/$self.$$.$(date +"%s").$RANDOM"
	fi

	endpoint="$__ipc_root/$name"

	if ! [ -d "$endpoint" ]; then
		if ! mkdir -p "$endpoint"; then
			return 1
		fi

		if ! queue_init "$endpoint/queue" ||
		   ! echo "$USER" > "$endpoint/owner"; then
			if ! rm -rf "$endpoint"; then
				log_error "Could not clean up $endpoint"
			fi

			return 1
		fi
	fi

	echo "$name"
	return 0
}

ipc_endpoint_close() {
	local name="$1"

	local endpoint

	endpoint="$__ipc_root/$name"

	if ! queue_destroy "$endpoint/queue"; then
		return 1
	fi

	if ! rm -rf "$endpoint"; then
		return 1
	fi

	return 0
}

_ipc_endpoint_put() {
	local endpoint="$1"
	local msg="$2"

	local queue

	queue="$__ipc_root/$endpoint/queue"

	if ! queue_put "$queue" "$msg"; then
		return 1
	fi

	return 0
}

_ipc_endpoint_get() {
	local endpoint="$1"
	local -i timeout="$2"

	local queue
	local msg

	queue="$__ipc_root/$endpoint/queue"

	if ! msg=$(queue_get "$queue" "$timeout"); then
		return 1
	fi

	echo "$msg"
	return 0
}

ipc_endpoint_send() {
	local endpoint="$1"
	local msg="$2"

	if ! _ipc_endpoint_put "$endpoint" "$msg"; then
		return 1
	fi

	return 0
}

ipc_endpoint_recv() {
	local endpoint="$1"
	local -i timeout="$2"

	local msg

	if ! msg=$(_ipc_endpoint_get "$endpoint" "$timeout"); then
		return 1
	fi

	echo "$msg"
	return 0
}
