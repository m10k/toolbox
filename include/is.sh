#!bin/bash

__init() {
	return 0
}

is_digits() {
	local str

	str="$1"

	if [[ "$str" =~ ^[0-9]+$ ]]; then
		return 0
	fi

	return 1
}

is_hex() {
	local str

	str="$1"

	if [[ "$str" =~ ^[0-9a-fA-F]+$ ]]; then
		return 0
	fi

	return 1
}

is_upper() {
	local str

	str="$1"

	if [[ "$str" =~ ^[A-Z]+$ ]]; then
		return 0
	fi

	return 1
}

is_lower() {
	local str

	str="$1"

	if [[ "$str" =~ ^[a-z]+$ ]]; then
		return 0
	fi

	return 1
}

is_alpha() {
	local str

	str="$1"

	if is_upper "$str" || is_lower "$str"; then
		return 0
	fi

	return 1
}

is_alnum() {
	local str

	str="$1"

	if is_alpha "$str" || is_digits "$str"; then
		return 0
	fi

	return 1
}
