#!/bin/bash

get_module_names() {
	local path="$1"

	local candidate

	while read -r candidate; do
		local filename

		# No constructor -> no module
		if ! grep "^__init\(\)" < "$candidate" &>/dev/null; then
			continue
		fi

		filename="${candidate#$path/}"
		echo "${filename%.sh}"
	done < <(find "$path" -type f -iname "*.sh")

	return 0
}

get_test_names() {
	local path="$1"

	local candidate

	while read -r candidate; do
		echo "${candidate#$path/}"
	done < <(find "$path" -type f -iname "*_spec.sh")

	return 0
}

main() {
	local tests
	local missing
	local modules
	local failed
	local module
	local test
	local err

	tests=()
	missing=()
	modules=()
	failed=()

	readarray -t modules < <(get_module_names "include")
	readarray -t tests < <(get_test_names "test")

	for module in "${modules[@]}"; do
		if ! array_contains "${module}_spec.sh" "${tests[@]}"; then
			missing+=("$module")
		fi
	done

	if (( ${#missing[@]} > 0 )); then
		echo "There are no tests for these modules:"

		for module in "${missing[@]}"; do
			echo "  $module"
		done

		return 1
	fi

	for test in "${tests[@]}"; do
		if ! shellspec --shell bash --format d "test/$test"; then
			failed+=("$test")
		fi
	done

	if (( ${#failed[@]} > 0 )); then
		echo "The following unit tests failed:"

		for test in "${failed[@]}"; do
			echo "  $test"
		done

		return 1
	fi

	echo "All unit tests passed"
	return 0
}

whereami() {
	local scriptpath

	if ! scriptpath=$(realpath "${BASH_SOURCE[0]}"); then
		return 1
	fi

	echo "${scriptpath%/*}"
	return 0
}

use_this_toolbox() {
	local here

	if ! here=$(whereami); then
		return 1
	fi

	if ! export PATH="$here:$PATH"; then
		return 1
	fi

	return 0
}

{
	if ! use_this_toolbox; then
		exit 1
	fi

	if ! . toolbox.sh; then
		exit 1
	fi

	if ! include "array"; then
		exit 1
	fi

	main "$@"
	exit "$?"
}
