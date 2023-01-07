#!/bin/bash

# is_spec.sh - Test cases for the toolbox is module
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
include "is"

digits="1234567890"
hex_lower="abcdef"
hex_upper="ABCDEF"
alpha_upper="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
alpha_lower="abcdefghijklmnopqrstuvwxyz"

# the length needs to be a multiple of four and the padding
# must be correct for is_base64() to accept the input
base64="$alpha_lower$alpha_upper$digits++//=="

generate_ascii_complement() {
        local complement_of="$1"

        local i

        for (( i = 1; i <= 127; i++ )); do
                local str

                str=$(printf "\\$(printf "%03o" "$i")")

                if [[ "$complement_of" == *"$str"* ]]; then
                        continue
                fi

                echo "$str"
        done
}

Describe "is_digits()"
  It "accepts digits"
    _test_is_digits_accepts_digits() {
	    local i

	    for (( i = 0; i < 100; i++ )); do
		    if ! is_digits "$i"; then
			    return 1
		    fi
	    done

	    return 0
    }

    When call _test_is_digits_accepts_digits
    The status should equal 0
  End

  It "does not accept characters other than digits"
    _test_is_digits_accepts_only_digits() {
	    local input

	    while read -r input; do
		    if is_digits "$input"; then
			    return 1
		    fi
	    done < <(generate_ascii_complement "$digits")

	    return 0
    }

    When call _test_is_digits_accepts_only_digits
    The status should equal 0
  End

  It "does not accept non-digit prefixes"
    When call is_digits "hoge123"
    The status should equal 1
  End

  It "does not accept non-digit suffixes"
    When call is_digits "123hoge"
    The status should equal 1
  End
End

Describe "is_hex()"
  It "accepts lower-case hex"
    When call is_hex "$hex_lower"
    The status should equal 0
  End

  It "accepts upper-case hex"
    When call is_hex "$hex_upper"
    The status should equal 0
  End

  It "accepts digits"
    When call is_hex "$digits"
    The status should equal 0
  End

  It "does not accept charactes other than hex"
    _test_is_hex_only_hex() {
	    local input

	    while read -r input; do
		    if is_hex "$input"; then
			    return 1
		    fi
	    done < <(generate_ascii_complement "$hex_lower$hex_upper$digits")

	    return 0
    }

    When call _test_is_hex_only_hex
    The status should equal 0
  End
End

Describe "is_upper()"
  It "accepts upper-case alpha"
    When call is_upper "$alpha_upper"
    The status should equal 0
  End

  It "does not accept characters other than upper-case alpha"
    _test_is_upper_non_alpha() {
            local input

            while read -r input; do
                    if is_upper "$input"; then
			    return 1
		    fi
            done < <(generate_ascii_complement "$alpha_upper")

	    return 0
    }

    When call _test_is_upper_non_alpha
    The status should equal 0
  End
End

Describe "is_lower()"
  It "accepts lower-case alpha"
    When call is_lower "$alpha_lower"
    The status should equal 0
  End

  It "does not accept characters other than lower-case alpha"
    _test_is_lower_non_alpha() {
	    local input

	    while read -r input; do
		    if is_lower "$input"; then
			    return 1
		    fi
	    done < <(generate_ascii_complement "$alpha_lower")

	    return 0
    }

    When call _test_is_lower_non_alpha
    The status should equal 0
  End
End

Describe "is_alpha()"
  It "accepts ascii alphabet characters"
    When call is_alpha "$alpha_lower$alpha_upper"
    The status should equal 0
  End

  It "does not accept characters other than alphabet characters"
    _test_is_alpha_non_alpha() {
	    local input

	    while read -r input; do
		    if is_alpha "$input"; then
			    return 1
		    fi
	    done < <(generate_ascii_complement "$alpha_lower$alpha_upper")

	    return 0
    }

    When call _test_is_alpha_non_alpha
    The status should equal 0
  End
End

Describe "is_alnum()"
  It "accepts alphanumeric characters"
    When call is_alnum "$alpha_lower$alpha_upper$digits"
    The status should equal 0
  End

  It "does not accept characters other than alphanumeric characters"
    _test_is_alnum_non_alnum() {
	    local input

	    while read -r input; do
		    if is_alnum "$input"; then
			    return 1
		    fi
	    done < <(generate_ascii_complement "$alpha_lower$alpha_upper$digits")

	    return 0
    }

    When call _test_is_alnum_non_alnum
    The status should equal 0
  End
End

Describe "is_base64"

  It "accepts base64 characters"
    When call is_base64 "$base64"
    The status should equal 0
  End

  It "does not accept characters other than base64"
    _test_is_base64_non_base64() {
	    local input

	    while read -r input; do
		    if is_base64 "$input"; then
			    return 1
		    fi
	    done < <(generate_ascii_complement "$base64")

	    return 0
    }

    When call _test_is_base64_non_base64
    The status should equal 0
  End
End
