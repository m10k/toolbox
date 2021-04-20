#!/usr/bin/env bats

. toolbox.sh

include "is"

alpha_upper="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
alpha_lower="abcdefghijklmnopqrstuvwxyz"
digits="1234567890"
hex_upper="ABCDEF"
hex_lower="abcdef"

generate_ascii_complement() {
	local complement_of="$1"

	local i

	for (( i = 0; i <= 255; i++ )); do
		local str

		str=$(printf "\\$(printf "%03d" "$i")")

		if [[ "$complement_of" = *"$str"* ]]; then
			continue
		fi

		echo "$str"
	done
}

@test "is_digits() accepts digits" {
	local i

	for (( i = 0 ; i < 100; i++ )); do
		is_digits "$i"
	done
}

@test "is_digits() does not accept characters other than digits" {
	local input

	while read -r input; do
		! is_digits "$input"
	done < <(generate_ascii_complement "$digits")
}

@test "is_digits() does not accept non-digit prefixes" {
	! is_digits "hoge123"
}

@test "is_digits() does not accept non-digit suffixes" {
	! is_digits "123hoge"
}

@test "is_hex() accepts lower-case hex" {
	is_hex "$hex_lower"
}

@test "is_hex() accepts upper-case hex" {
	is_hex "$hex_upper"
}

@test "is_hex() accepts digits" {
	is_hex "$digits"
}

@test "is_hex() does not accept characters other than hex" {
	local input

	while read -r input; do
		! is_hex "$input"
	done < <(generate_ascii_complement "$hex_lower$hex_upper$digits")
}

@test "is_upper() accepts upper-case ascii" {
	is_upper "$alpha_upper"
}

@test "is_upper does not accept characters other than upper-case ascii" {
	local input

	while read -r input; do
		! is_upper "$input"
	done < <(generate_ascii_complement "$alpha_upper")
}

@test "is_lower accepts lower-case ascii" {
	is_lower "$alpha_lower"
}

@test "is_lower() does not accept characters other than lower-case ascii" {
	local input

	while read -r input; do
		! is_lower "$input"
	done < <(generate_ascii_complement "$alpha_lower")
}

@test "is_alpha() accepts ascii alphabet characters" {
	is_alpha "$alpha_lower$alpha_upper"
}

@test "is_alpha() does not accept characters other than ascii alphabet characters" {
	local input

	while read -r input; do
		! is_alpha "$input"
	done < <(generate_ascii_complement "$alpha_lower$alpha_upper")
}

@test "is_alnum() accepts ascii alphanumeric characters" {
	is_alnum "$alpha_lower$alpha_upper$digits"
}

@test "is_alnum() does not accept characters other than ascii alphanumeric characters" {
	local input

	while read -r input; do
		! is_alnum "$input"
	done < <(generate_ascii_complement "$alpha_lower$alpha_upper$digits")
}
