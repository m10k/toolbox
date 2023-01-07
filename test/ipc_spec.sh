#!/bin/bash

# ipc_spec.sh - Test cases for the toolbox ipc module
# Copyright (C) 2021-2023 Matthias Kruk
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

. toolbox.sh
include "ipc"

setup() {
	local keyfp

	if ! mkdir -p "/tmp/test.$$"; then
		return 1
	fi

	if ! chmod 700 "/tmp/test.$$"; then
		rmdir "/tmp/test.$$"
		return 1
	fi

	export GNUPGHOME="/tmp/test.$$"

	cat <<EOF > "/tmp/test.$$/batch.gpgscript"
%no-protection
Key-Type: RSA
Key-Length: 4096
Key-Usage: sign,auth
Subkey-Type: RSA
Subkey-Length: 4096A
Name-Real: Toolbox Test
Name-Comment: Test
Name-Email: test@m10k.eu
Expire-Date: 1d
EOF

	if ! gpg --batch --homedir "/tmp/test.$$" \
	     --generate-key "/tmp/test.$$/batch.gpgscript" 2>/dev/null; then
		return 1
	fi

	if ! keypf=$(gpg -K 2>/dev/null | grep -m 1 -oP '[0-9a-fA-F]{40}'); then
		return 2
	fi

	if ! printf 'default-key %s\nquiet\n' "$keypf" > "/tmp/test.$$/gpg.conf"; then
		return 3
	fi

	return 0
}

cleanup() {
	rm -rf "/tmp/test.$$"
}

Describe "Encoding"
  It "_ipc_encode() outputs base64"
    _test_encoding() {
        local data

	data=$(dd if=/dev/urandom bs=1024 count=1024 2>/dev/null |
		       _ipc_encode)

	if ! [[ "$data" =~ ^[a-zA-Z0-9+/]+[=]*$ ]]; then
		return 1
	fi

	return 0
    }

    When call _test_encoding
    The status should equal 0
  End

  It "_ipc_encode() output has correct length"
    _test_encoding_length() {
        local data
        local block_size
        local block_num
        local input_bytes
        local input_bits
        local expected_length
        local actual_length

        block_size=1024
        block_num=1024
        input_bytes=$((block_size * block_num))
        input_bits=$((input_bytes * 8))

        actual_length=$(dd if=/dev/urandom bs="$block_size" count="$block_num" 2>/dev/null |
	                _ipc_encode | wc -c)

        if (( input_bits % 24 > 0 )); then
		# data is padded
		(( input_bits += 24 - (input_bits % 24) ))
	fi
	expected_length=$((input_bits / 6))

        if (( expected_length != actual_length )); then
		return 1
	fi

	return 0
    }

    When call _test_encoding_length
    The status should equal 0
  End

  It "_ipc_encode() output does not contain newlines"
    _test_encoding_newlines() {
	    local lines

	    lines=$(dd if=/dev/urandom bs=1024 count=1024 2>/dev/null |
			    _ipc_encode | wc -l)

	    if (( lines != 0 )); then
		    return 1
	    fi

	    return 0
    }

    When call _test_encoding_newlines
    The status should equal 0
  End


  It "_ipc_decode() reverses _ipc_encode()"
    _test_encode_decode() {
	    local data_before
	    local data_encoded
	    local data_after

	    data_before=$(dd if=/dev/urandom bs=1024 count=1024 2>/dev/null | base64 -w 0)
	    data_encoded=$(_ipc_encode <<< "$data_before")
	    data_after=$(_ipc_decode <<< "$data_encoded")

	    if [[ "$data_before" != "$data_after" ]]; then
		    return 1
	    fi

	    return 0
    }

    When call _test_encode_decode
    The status should equal 0
  End
End

Describe "Authentication"
  BeforeAll 'setup'
  AfterAll 'cleanup'

  It "_ipc_sign() creates a signature with correct length"
    _test_ipc_sign_length() {
	    local data

	    data=$(dd if=/dev/urandom bs=1024 count=1024 2>/dev/null | _ipc_encode)

	    if ! signature=$(_ipc_sign <<< "$data"); then
		    return 1
	    fi

	    if (( ${#signature} != 756 )); then
		    return 1
	    fi

	    return 0
    }

    When call _test_ipc_sign_length
    The status should equal 0
  End

  It "_ipc_verify() can verify signatures"
    _test_ipc_verify() {
	    local data
	    local signature

	    data=$(dd if=/dev/urandom bs=1024 count=1024 2>/dev/null | _ipc_encode)

	    if ! signature=$(_ipc_sign "$data"); then
		    return 1
	    fi

	    if ! _ipc_verify "$data" "$signature"; then
		    return 1
	    fi

	    return 0
    }

    When call _test_ipc_verify
    The status should equal 0
    The output should start with "gpg: "
  End

  It "_ipc_verify() does not verify tampered data"
    _test_ipc_verify_invalid_data() {
	    local data
	    local signature

	    data=$(dd if=/dev/urandom bs=1024 count=1024 2>/dev/null | _ipc_encode)

	    if ! signature=$(_ipc_sign "$data"); then
		    return 1
	    fi

	    if _ipc_verify "invalid$data" "$signature"; then
		    return 1
	    fi

	    return 0
    }

    When call _test_ipc_verify_invalid_data
    The status should equal 0
    The output should start with "gpg: "
  End
End

Describe "Message"
  BeforeAll 'setup'
  AfterAll 'cleanup'

  It "_ipc_msg_new() outputs base64 encoded data"
    _test_ipc_msg_new_is_base64() {
	    local msg

	    if ! msg=$(_ipc_msg_new "from" "to" "data"); then
		    return 1
	    fi

	    if ! is_base64 "$msg"; then
		    return 1
	    fi

	    return 0
    }

    When call _test_ipc_msg_new_is_base64
    The status should equal 0
  End

  It "_ipc_msg_new() outputs an encoded JSON object"
    _test_ipc_msg_new_is_json() {
	    local msg

	    if ! msg=$(_ipc_msg_new "from" "to" "data"); then
		    return 1
	    fi

	    if ! _ipc_decode <<< "$msg" | jq -r -e . ; then
		    return 1
	    fi

	    return 0
    }

    When call _test_ipc_msg_new_is_json
    The status should equal 0
    The stdout should match pattern '{*"message": "*",*"signature": "*"*}'
    The stderr should not start with "parse error"
  End

  It "_ipc_msg_new() generates valid toolbox.ipc.envelope objects"
    _test_ipc_msg_new_json_schema_envelope() {
	    local msg

	    if ! msg=$(_ipc_msg_new "from" "to" "data"); then
		    return 1
	    fi

	    if ! spec/validate.py spec/ipc_envelope.schema.json <(_ipc_decode "$msg"); then
		    return 1
	    fi

	    return 0
    }

    When call _test_ipc_msg_new_json_schema_envelope
    The status should equal 0
  End

  It "_ipc_msg_new() messages contain valid toolbox.ipc.message objects"
    _test_ipc_msg_new_json_schema_message() {
	    local msg

	    if ! msg=$(_ipc_msg_new "from" "to" "data"); then
		    return 1
	    fi

	    if ! spec/validate.py spec/ipc_message.schema.json \
		 <(_ipc_get "$msg" "message" | _ipc_decode); then
		    return 1
	    fi

	    return 0
    }

    When call _test_ipc_msg_new_json_schema_message
    The status should equal 0
  End

  It "_ipc_msg_new()/ipc_msg_get_version() sets/gets the correct version"
    _test_ipc_msg_new_version() {
	    local msg

	    if ! msg=$(_ipc_msg_new "from" "to" "data"); then
		    return 1
	    fi

	    ipc_msg_get_version "$msg"
    }

    When call _test_ipc_msg_new_version
    The status should equal 0
    The stdout should equal "$__ipc_version"
  End

  It "_ipc_msg_new()/ipc_msg_get_user() sets/gets the correct user"

    _test_ipc_msg_new_user() {
	    local msg

	    msg=$(_ipc_msg_new "from" "to" "data")

	    ipc_msg_get_user "$msg"
    }

    When call _test_ipc_msg_new_user
    The status should equal 0
    The stdout should equal "$USER"
  End

  It "_ipc_msg_new()/ipc_msg_get_timestamp() sets/gets the correct timestamp"
    _test_ipc_msg_new_timestamp() {
	    local before
	    local after
	    local msg
	    local timestamp

	    before=$(date +"%s")
	    msg=$(_ipc_msg_new "from" "to" "data")
	    after=$(date +"%s")

	    timestamp=$(ipc_msg_get_timestamp "$msg")

	    if ! (( before <= timestamp )); then
		    return 1
	    fi

	    if ! (( after >= timestamp )); then
		    return 1
	    fi

	    return 0
    }

    When call _test_ipc_msg_new_timestamp
    The status should equal 0
  End

  It "_ipc_msg_new()/ipc_msg_get_source() sets/gets the correct source"
    _test_ipc_msg_new_source() {
	    local msg

	    if ! msg=$(_ipc_msg_new "from" "to" "data"); then
		    return 1
	    fi

	    ipc_msg_get_source "$msg"
    }

    When call _test_ipc_msg_new_source
    The status should equal 0
    The stdout should equal "from"
  End

  It "_ipc_msg_new()/ipc_msg_get_destination() sets/gets the correct destination"
    _test_ipc_msg_new_destination() {
	    local msg

	    if ! msg=$(_ipc_msg_new "from" "to" "data"); then
		    return 1
	    fi

	    ipc_msg_get_destination "$msg"
    }

    When call _test_ipc_msg_new_destination
    The status should equal 0
    The stdout should equal "to"
  End

  It "_ipc_msg_new()/ipc_msg_get_data() sets/gets the correct data"
    _test_ipc_msg_new_data() {
	    local msg

	    if ! msg=$(_ipc_msg_new "from" "to" "data"); then
		    return 1
	    fi

	    ipc_msg_get_data "$msg"
    }

    When call _test_ipc_msg_new_data
    The status should equal 0
    The stdout should equal "data"
  End

  It "ipc_msg_get_signer_name() returns the correct name"
    _test_ipc_msg_get_signer_name() {
	    local msg

	    if ! msg=$(_ipc_msg_new "from" "to" "data"); then
		    return 1
	    fi

	    ipc_msg_get_signer_name "$msg"
    }

    When call _test_ipc_msg_get_signer_name
    The status should equal 0
    The stdout should equal "Toolbox Test (Test)"
  End

  It "ipc_msg_get_signer_email() returns the correct email"
    _test_ipc_msg_get_signer_email() {
	    local msg

	    if ! msg=$(_ipc_msg_new "from" "to" "data"); then
		    return 1
	    fi

	    ipc_msg_get_signer_email "$msg"
    }

    When call _test_ipc_msg_get_signer_email
    The status should equal 0
    The stdout should equal "test@m10k.eu"
  End

  It "ipc_msg_get_signer_key() returns the correct key"
    _test_ipc_msg_get_signer_key() {
	    local msg
	    local key

	    if ! msg=$(_ipc_msg_new "from" "to" "data"); then
		    return 1
	    fi

	    if ! key=$(ipc_msg_get_signer_key "$msg"); then
		    return 1
	    fi

	    gpg --armor --export --local-user "$key"
    }

    When call _test_ipc_msg_get_signer_key
    The status should equal 0
    The stdout should start with "-----BEGIN PGP PUBLIC KEY BLOCK-----"
  End
End

Describe "ipc_endpoint_open"
  It "opens a public endpoint when the endpoint name is specified"
    _test_ipc_endpoint_open_public() {
	    local endpoint
	    local res

	    res=1

	    if endpoint=$(ipc_endpoint_open "pub/test$RANDOM"); then
		    ipc_endpoint_close "$endpoint"
		    res=0
	    fi

	    return "$res"
    }

    When call _test_ipc_endpoint_open_public
    The status should equal 0
  End

  It "opens a private endpoint when no endpoint name is specified"
    _test_ipc_endpoint_open_private() {
	    local endpoint
	    local res

	    if ! endpoint=$(ipc_endpoint_open); then
		    return 1
	    fi

	    res=1

	    if [[ "$endpoint" == "priv/"* ]]; then
		    res=0
	    fi

	    ipc_endpoint_close "$endpoint"
	    return "$res"
    }

    When call _test_ipc_endpoint_open_private
    The status should equal 0
  End
End

Describe "ipc_endpoint_close"
  It "closes a public endpoint"
    _test_ipc_endpoint_close_public() {
	    local endpoint

	    if ! endpoint=$(ipc_endpoint_open "pub/test$RANDOM"); then
		    return 1
	    fi

	    if ! ipc_endpoint_close "$endpoint"; then
		    return 1
	    fi

	    return 0
    }

    When call _test_ipc_endpoint_close_public
    The status should equal 0
  End

  It "closes a private endpoint"
    _test_ipc_endpoint_close_private() {
	    local endpoint

	    if ! endpoint=$(ipc_endpoint_open); then
		    return 1
	    fi

	    if ! ipc_endpoint_close "$endpoint"; then
		    return 1
	    fi

	    return 0
    }

    When call _test_ipc_endpoint_close_private
    The status should equal 0
  End
End

Describe "ipc_endpoint_send"
  BeforeAll 'setup'
  AfterAll 'cleanup'

  It "sends a message to a public endpoint"
    _test_ipc_endpoint_send_public() {
	    local endpoint
	    local res

	    if ! endpoint=$(ipc_endpoint_open "pub/test$RANDOM"); then
		    return 1
	    fi

	    if ipc_endpoint_send "-" "$endpoint" "data"; then
		    res=0
	    else
		    res=1
	    fi

	    ipc_endpoint_close "$endpoint"

	    return "$res"
    }

    When call _test_ipc_endpoint_send_public
    The status should equal 0
  End

  It "sends a message to a private endpoint"
    _test_ipc_endpoint_send_private() {
	    local endpoint
	    local res

	    if ! endpoint=$(ipc_endpoint_open); then
		    return 1
	    fi

	    if ipc_endpoint_send "-" "$endpoint" "data"; then
		    res=0
	    else
		    res=1
	    fi

	    ipc_endpoint_close "$endpoint"

	    return "$res"
    }

    When call _test_ipc_endpoint_send_private
    The status should equal 0
  End
End

Describe "ipc_endpoint_recv"
  BeforeAll 'setup'
  AfterAll 'cleanup'

  It "receives messages on a public endpoint"
    _test_ipc_endpoint_recv_public() {
	    local endpoint
	    local res
	    local data
	    local msg

	    if ! endpoint=$(ipc_endpoint_open "pub/test$RANDOM"); then
		    return 1
	    fi

	    data="data$RANDOM"
	    res=1

	    if ipc_endpoint_send "-" "$endpoint" "$data" &&
	       msg=$(ipc_endpoint_recv "$endpoint") &&
	       msg=$(ipc_msg_get_data "$msg") &&
	       [[ "$msg" == "$data" ]]; then
		    res=0
	    fi

	    ipc_endpoint_close "$endpoint"

	    return "$res"
    }

    When call _test_ipc_endpoint_recv_public
    The status should equal 0
  End

  It "receives messages on a private endpoint"
    _test_ipc_endpoint_recv_private() {
	    local endpoint
	    local res
	    local data
	    local msg

	    if ! endpoint=$(ipc_endpoint_open); then
		    return 1
	    fi

	    data="data$RANDOM"
	    res=1

	    if ipc_endpoint_send "-" "$endpoint" "$data" &&
	       msg=$(ipc_endpoint_recv "$endpoint") &&
	       msg=$(ipc_msg_get_data "$msg") &&
	       [[ "$msg" == "$data" ]]; then
		    res=0
	    fi

	    ipc_endpoint_close "$endpoint"

	    return "$res"
    }

    When call _test_ipc_endpoint_recv_private
    The status should equal 0
  End
End
