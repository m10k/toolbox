#!/bin/bash

__init() {
	declare -xgr __acpi_ac_path="/sys/class/power_supply"

	return 0
}

acpi_ac_get_state() {
	local psu

	psu="$1"

	if ! cat "$__acpi_ac_path/$psu/online" 2>/dev/null; then
		return 1
	fi

	return 0
}
