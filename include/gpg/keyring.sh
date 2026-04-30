#!/bin/bash

# gpg/keyring.sh - Toolbox module for GnuPG keyring handling
# Copyright (C) 2021-2026 Matthias Kruk
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
	local root

	if ! include "log" "gpg/key"; then
		return 1
	fi

	if ! root=$(gpg_get_root); then
		log_error "Cannot determine GPG root directory"
		return 1
	fi

	declare -gxr __gpg_keyring_root="$root/keyrings"

	return 0
}

gpg_keyring_open() {
	local keyring="$1"

	gpghome="$__gpg_keyring_root/$keyring"

	if ! mkdir -p "$gpghome/keys" ||
	   ! chmod 700 "$gpghome"; then
		return 1
	fi

	return 0
}

gpg_keyring_get_path() {
	local keyring="$1"

	echo "$__gpg_keyring_root/$keyring"
	return 0
}

gpg_keyring_get_key() {
	local keyring="$1"
	local key="$2"

	local keypath
	local fingerprint

	keypath="$__gpg_keyring_root/$keyring/keys/$key"

	if ! fingerprint=$(cat "$keypath" 2>/dev/null); then
		return 1
	fi

	printf '%s\n' "$fingerprint"
	return 0
}

gpg_keyring_set_key() {
	local keyring="$1"
	local key="$2"
	local fingerprint="$3"

	if ! echo "$fingerprint" > "$__gpg_keyring_root/$keyring/keys/$key"; then
		return 1
	fi

	return 0
}

gpg_keyring_export_key() {
	local keyring="$1"
	local key="$2"

	local fingerprint

	if ! fingerprint=$(gpg_keyring_get_key "$keyring" "$key"); then
		fingerprint="$key"
	fi

	gpg_key_export "$__gpg_keyring_root/$keyring" "$fingerprint"
}

gpg_keyring_export_key_ascii() {
	local keyring="$1"
	local key="$2"

	local fingerprint

	if ! fingerprint=$(gpg_keyring_get_key "$keyring" "$key"); then
		fingerprint="$key"
	fi

	gpg_key_export_ascii "$__gpg_keyring_root/$keyring" "$fingerprint"
}

gpg_keyring_generate_key() {
	local keyring="$1"
	local key="$2"
	local name="$3"
	local email="$4"
	local comment="$5"
	local keylength="${6-4096}"
	local expiry="${7-0}"

	local gpghome
	local fingerprint
	local name
	local email

	gpghome="$__gpg_keyring_root/$keyring"

	if ! fingerprint=$(gpg_key_new "$gpghome" "$name" "$email" \
	                               "$comment" "$expiry" "$keylength"); then
		return 1
	fi

	if ! gpg_keyring_set_key "$keyring" "$key" "$fingerprint"; then
		return 1
	fi

	echo "$fingerprint"
	return 0
}

gpg_keyring_get_key_expiration_date() {
	local keyring="$1"
	local key="$2"

	local fingerprint

	if ! fingerprint=$(gpg_keyring_get_key "$keyring" "$key"); then
		fingerprint="$key"
	fi

	gpg_key_get_expiration_date "$__gpg_keyring_root/$keyring" "$fingerprint"
}

gpg_keyring_get_key_expiration() {
	local keyring="$1"
	local key="$2"

	local -i expiration
	local -i remaining

	if ! expiration=$(gpg_keyring_get_key_expiration_date "$keyring" "$key"); then
		log_error "Could not determine expiration of key $key in keyring $keyring"
		return 1
	fi

	if (( expiration == 0 )); then
		remaining=0
	else
		remaining=$((expiration - EPOCHSECONDS))

		# Do not return 0 because it means forever valid
		if (( remaining == 0 )); then
			remaining=-1
		fi
	fi

	echo "$remaining"
	return 0
}
