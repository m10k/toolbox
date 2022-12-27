#!/bin/bash

# uipc_spec.sh - Test cases for the toolbox uipc module
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

export PATH="$PWD/..:$PATH"

. toolbox.sh
include "uipc"

setup() {
	return 0
}

cleanup() {
	return 0
}

Describe "Encoding"
  It "_uipc_encode() outputs base64"
    _test_encoding() {
        local data

	data=$(dd if=/dev/urandom bs=1024 count=1024 2>/dev/null |
		       _uipc_encode)

	if ! is_base64 "$data"; then
		return 1
	fi

	return 0
    }

    When call _test_encoding
    The status should equal 0
  End

  It "_uipc_encode() output has correct length"
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
	                _uipc_encode | wc -c)

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

  It "_uipc_encode() output does not contain newlines"
    _test_encoding_newlines() {
	    local lines

	    lines=$(dd if=/dev/urandom bs=1024 count=1024 2>/dev/null |
			    _uipc_encode | wc -l)

	    if (( lines != 0 )); then
		    return 1
	    fi

	    return 0
    }

    When call _test_encoding_newlines
    The status should equal 0
  End

  It "_uipc_decode() reverses _ipc_encode()"
    _test_encode_decode() {
	    local data_before
	    local data_encoded
	    local data_after

	    data_before=$(dd if=/dev/urandom bs=1024 count=1024 2>/dev/null | base64 -w 0)
	    data_encoded=$(_uipc_encode <<< "$data_before")
	    data_after=$(_uipc_decode <<< "$data_encoded")

	    if [[ "$data_before" != "$data_after" ]]; then
		    return 1
	    fi

	    return 0
    }

    When call _test_encode_decode
    The status should equal 0
  End
End

Describe "Message"
  BeforeAll 'setup'
  AfterAll 'cleanup'

  It "_uipc_msg_new() outputs base64 encoded data"
    _test_uipc_msg_new_is_base64() {
	    local msg

	    if ! msg=$(_uipc_msg_new "from" "to" "data"); then
		    return 1
	    fi

	    if ! is_base64 "$msg"; then
		    return 1
	    fi

	    return 0
    }

    When call _test_uipc_msg_new_is_base64
    The status should equal 0
  End

  It "_uipc_msg_new() outputs an encoded JSON object"
    _test_uipc_msg_new_is_json() {
	    local msg

	    if ! msg=$(_uipc_msg_new "from" "to" "data"); then
		    return 1
	    fi

	    if ! _uipc_decode <<< "$msg" | jq -r -e . ; then
		    return 1
	    fi

	    return 0
    }

    When call _test_uipc_msg_new_is_json
    The status should equal 0
    The stdout should match pattern '{*}'
    The stderr should not start with "parse error"
  End

  It "_uipc_msg_new() generates valid toolbox.ipc.message objects"
    _test_uipc_msg_new_json_schema_envelope() {
	    local msg

	    if ! msg=$(_uipc_msg_new "from" "to" "data"); then
		    return 1
	    fi

	    if ! ../spec/validate.py ../spec/ipc_message.schema.json <(_uipc_decode "$msg"); then
		    return 1
	    fi

	    return 0
    }

    When call _test_uipc_msg_new_json_schema_envelope
    The status should equal 0
  End

  It "_uipc_msg_new()/uipc_msg_get_version() sets/gets the correct version"
    _test_uipc_msg_new_version() {
	    local msg

	    if ! msg=$(_uipc_msg_new "from" "to" "data"); then
		    return 1
	    fi

	    uipc_msg_get_version "$msg"
    }

    When call _test_uipc_msg_new_version
    The status should equal 0
    The stdout should equal "$__uipc_version"
  End

  It "_uipc_msg_new()/uipc_msg_get_user() sets/gets the correct user"

    _test_uipc_msg_new_user() {
	    local msg

	    msg=$(_uipc_msg_new "from" "to" "data")

	    uipc_msg_get_user "$msg"
    }

    When call _test_uipc_msg_new_user
    The status should equal 0
    The stdout should equal "$USER"
  End

  It "_uipc_msg_new()/uipc_msg_get_timestamp() sets/gets the correct timestamp"
    _test_uipc_msg_new_timestamp() {
	    local before
	    local after
	    local msg
	    local timestamp

	    before=$(date +"%s")
	    msg=$(_uipc_msg_new "from" "to" "data")
	    after=$(date +"%s")

	    timestamp=$(uipc_msg_get_timestamp "$msg")

	    if (( timestamp < before )) ||
	       (( timestamp > after )); then
		    return 1
	    fi

	    return 0
    }

    When call _test_uipc_msg_new_timestamp
    The status should equal 0
  End

  It "_uipc_msg_new()/uipc_msg_get_source() sets/gets the correct source"
    _test_uipc_msg_new_source() {
	    local msg

	    if ! msg=$(_uipc_msg_new "from" "to" "data"); then
		    return 1
	    fi

	    uipc_msg_get_source "$msg"
    }

    When call _test_uipc_msg_new_source
    The status should equal 0
    The stdout should equal "from"
  End

  It "_uipc_msg_new()/uipc_msg_get_destination() sets/gets the correct destination"
    _test_uipc_msg_new_destination() {
	    local msg

	    if ! msg=$(_uipc_msg_new "from" "to" "data"); then
		    return 1
	    fi

	    uipc_msg_get_destination "$msg"
    }

    When call _test_uipc_msg_new_destination
    The status should equal 0
    The stdout should equal "to"
  End

  It "_uipc_msg_new()/uipc_msg_get_data() sets/gets the correct data"
    _test_uipc_msg_new_data() {
	    local msg

	    if ! msg=$(_uipc_msg_new "from" "to" "data"); then
		    return 1
	    fi

	    uipc_msg_get_data "$msg"
    }

    When call _test_uipc_msg_new_data
    The status should equal 0
    The stdout should equal "data"
  End
End

Describe "uipc_endpoint_open"
  It "opens a public endpoint when the endpoint name is specified"
    _test_uipc_endpoint_open_public() {
	    local endpoint_name
	    local endpoint
	    local res

	    endpoint_name="pub/test$RANDOM"
	    res=1

	    if endpoint=$(uipc_endpoint_open "$endpoint_name"); then
		    if [[ "$endpoint" != "priv/"* ]]; then
			    res=0
		    fi

		    uipc_endpoint_close "$endpoint"
	    fi

	    return "$res"
    }

    When call _test_uipc_endpoint_open_public
    The status should equal 0
  End

  It "opens a private endpoint when no endpoint name is specified"
    _test_uipc_endpoint_open_private() {
	    local endpoint
	    local res

	    res=1

	    if endpoint=$(uipc_endpoint_open); then
		    if [[ "$endpoint" == "priv/"* ]]; then
			    res=0
		    fi

		    uipc_endpoint_close "$endpoint"
	    fi

	    return "$res"
    }

    When call _test_uipc_endpoint_open_private
    The status should equal 0
  End
End

Describe "uipc_endpoint_close"
  It "closes a public endpoint"
    _test_uipc_endpoint_close_public() {
	    local endpoint

	    if ! endpoint=$(uipc_endpoint_open "pub/test$RANDOM"); then
		    return 1
	    fi

	    if ! uipc_endpoint_close "$endpoint"; then
		    return 1
	    fi

	    return 0
    }

    When call _test_uipc_endpoint_close_public
    The status should equal 0
  End

  It "closes a private endpoint"
    _test_uipc_endpoint_close_private() {
	    local endpoint

	    if ! endpoint=$(uipc_endpoint_open); then
		    return 1
	    fi

	    if ! uipc_endpoint_close "$endpoint"; then
		    return 1
	    fi

	    return 0
    }

    When call _test_uipc_endpoint_close_private
    The status should equal 0
  End
End

Describe "uipc_endpoint_send"
  BeforeAll 'setup'
  AfterAll 'cleanup'

  It "sends a message to a public endpoint"
    _test_uipc_endpoint_send_public() {
	    local endpoint
	    local res

	    if ! endpoint=$(uipc_endpoint_open "pub/test$RANDOM"); then
		    return 1
	    fi

	    if uipc_endpoint_send "-" "$endpoint" "data"; then
		    res=0
	    else
		    res=1
	    fi

	    uipc_endpoint_close "$endpoint"

	    return "$res"
    }

    When call _test_uipc_endpoint_send_public
    The status should equal 0
  End

  It "sends a message to a private endpoint"
    _test_uipc_endpoint_send_private() {
	    local endpoint
	    local res

	    if ! endpoint=$(uipc_endpoint_open); then
		    return 1
	    fi

	    if uipc_endpoint_send "-" "$endpoint" "data"; then
		    res=0
	    else
		    res=1
	    fi

	    uipc_endpoint_close "$endpoint"

	    return "$res"
    }

    When call _test_uipc_endpoint_send_private
    The status should equal 0
  End
End

Describe "uipc_endpoint_recv"
  BeforeAll 'setup'
  AfterAll 'cleanup'

  It "receives messages on a public endpoint"
    _test_uipc_endpoint_recv_public() {
	    local endpoint
	    local res
	    local txdata
	    local rxdata
	    local msg

	    txdata="data$RANDOM"
	    res=1

	    if endpoint=$(uipc_endpoint_open "pub/test$RANDOM"); then
		    if ! uipc_endpoint_send "-" "$endpoint" "$txdata"; then
			    res=2

		    elif ! msg=$(uipc_endpoint_recv "$endpoint" 10); then
			    res=3

		    elif ! rxdata=$(uipc_msg_get_data "$msg"); then
			    res=4

		    elif [[ "$rxdata" != "$txdata" ]]; then
			    res=5

		    else
			    res=0
		    fi

		    uipc_endpoint_close "$endpoint"
	    fi

	    return "$res"
    }

    When call _test_uipc_endpoint_recv_public
    The status should equal 0
  End

  It "receives messages on a private endpoint"
    _test_uipc_endpoint_recv_private() {
	    local endpoint
	    local res
	    local txdata
	    local rxdata
	    local msg

	    res=1
	    txdata="data$RANDOM"

	    if endpoint=$(uipc_endpoint_open); then
		    if ! uipc_endpoint_send "-" "$endpoint" "$txdata"; then
			    res=2

		    elif ! msg=$(uipc_endpoint_recv "$endpoint"); then
			    res=3

		    elif ! rxdata=$(uipc_msg_get_data "$msg"); then
			    res=4

		    elif [[ "$rxdata" != "$txdata" ]]; then
			    res=5

		    else
			    res=0
		    fi

		    uipc_endpoint_close "$endpoint"
	    fi

	    return "$res"
    }

    When call _test_uipc_endpoint_recv_private
    The status should equal 0
  End
End
