#!/bin/bash

# gpg/key.sh - Toolbox module for GnuPG key handling
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
	if ! include "log"; then
		return 1
	fi

	return 0
}

gpg_key_sign() {
	local gpghome="$1"
	local signer="$2"
	local signee="$3"

	local -a args
	local err

	args=(
		--homedir "$gpghome"
		--local-user "$signer"
		--quick-sign-key "$signee"
	)

	if ! err=$(gpg "${args[@]}"); then
		log_highlight "gpg --quick-sign-key error" <<< "$err" | log_error
		return 1
	fi

	return 0
}

gpg_key_import() {
	local gpghome="$1"
	local pubkey="$2"

	local err

	if [ -f "$pubkey" ]; then
		if ! err=$(gpg --homedir "$gpghome" --import "$pubkey"); then
			log_highlight "gpg --import error" <<< "$err" | log_error
			return 1
		fi
	else
		if ! err=$(gpg --homedir "$gpghome" --import <<< "$pubkey"); then
			log_highlight "gpg --import error" <<< "$err" | log_error
			return 1
		fi
	fi

	return 0
}

gpg_key_export() {
	local gpghome="$1"
	local identity="$2"

	if ! gpg --homedir "$gpghome" --export "$identity"; then
		return 1
	fi

	return 0
}

gpg_key_export_ascii() {
	local gpghome="$1"
	local identity="$2"

	if ! gpg --homedir "$gpghome" --export "$identity" --armor; then
		return 1
	fi

	return 0
}

gpg_key_upload() {
	local gpghome="$1"
	local identity="$2"
	local server="$3"

	local err
	local -a args

	args=(
		--homedir   "$gpghome"
		--keyserver "$server"
		--send-keys "$identity"
	)

	if ! err=$(gpg "${args[@]}"); then
		log_highlight "gpg --send-keys error" <<< "$err" | log_error
		return 1
	fi

	return 0
}

gpg_key_new() {
	local gpghome="$1"
	local name="$2"
	local email="$3"
	local comment="$4"
	local expiry="${5-0}"
	local -i keylen="${6-4096}"

	local config
	local err

	config="
%no-protection
Key-Type: RSA
Key-Length: $keylen
Key-Usage: sign,auth,cert
Subkey-Type: RSA
Subkey-Length: $keylen
Subkey-Usage: encrypt
Name-Real: $name
Name-Email: $email
Name-Comment: $comment
Expire-Date: $expiry
"

	if ! err=$(gpg --homedir "$gpghome" --batch --generate-key <(echo "$config") 2>&1); then
		log_highlight "gpg --generate-key error" <<< "$err" | log_error
		return 1
	fi

	if ! [[ "$err" =~ ([0-9a-fA-F]{40,}) ]]; then
		log_error "Could not find fingerprint in output"
		log_highlight "gpg --generate-key output" <<< "$err" | log_error
		return 1
	fi

	printf '%s\n' "${BASH_REMATCH[1]}"
	return 0
}

gpg_key_get_expiration_date() {
	local gpghome="$1"
	local key="$2"

	local keyinfo
	local details
	local -a fields
	local -i expiration

	if ! keyinfo=$(gpg --homedir "$gpghome" --armor --export "$key" 2>&1); then
		log_error "Could not get details about key $key"
		return 1
	fi

	if ! details=$(gpg --show-keys --with-colons --fixed-list-mode <<< "$keyinfo" 2>&1); then
		log_error "Could not get details about key $key"
		return 1
	fi

	if ! IFS=':' read -r -a fields <<< "$details"; then
		log_error "Could not parse GPG output"
		log_highlight "GPG output" <<< "$details" | log_error
		return 1
	fi

	# The field will be empty if the key does not expire. In this case, we want
	# the output to be 0, but we don't want to get a warning from printf.
	expiration="${fields[6]}"

	printf '%d\n' "$expiration"
	return 0
}
