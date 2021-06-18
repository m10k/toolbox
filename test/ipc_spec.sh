#!/bin/bash

# ipc_spec.sh - Test cases for the toolbox ipc module
# Copyright (C) 2021 Matthias Kruk
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
  setup() {
	  if ! mkdir "/tmp/test.$$"; then
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

	  return 0
  }

  cleanup() {
	  rm -rf "/tmp/test.$$"
  }

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
  setup() {
	  if ! mkdir "/tmp/test.$$"; then
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

	  return 0
  }

  cleanup() {
	  rm -rf "/tmp/test.$$"
  }

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

	    if ! ../spec/validate.py ../spec/ipc_envelope.schema.json <(_ipc_decode "$msg"); then
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

	    if ! ../spec/validate.py ../spec/ipc_message.schema.json \
		 <(_ipc_get "$msg" "message" | _ipc_decode); then
		    return 1
	    fi

	    return 0
    }

    When call _test_ipc_msg_new_json_schema_message
    The status should equal 0
  End

End
