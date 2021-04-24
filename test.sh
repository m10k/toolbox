#!/bin/bash

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

	while read -r module; do
		test="test/${module#*include/}"

		if ! [ -f "$test" ]; then
			missing+=("$module")
		else
			tests+=("$test")
		fi
	done < <(find "include" -type f -iname "*.sh")

	if (( ${#missing[@]} > 0 )); then
		echo "There are no tests for these modules:"

		for module in "${missing[@]}"; do
			echo "  $module"
		done

		return 1
	fi

	for test in "${tests[@]}"; do
		if ! "$test"; then
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

{
	main "$@"
	exit "$?"
}
