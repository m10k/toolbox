#!/bin/bash

__init() {
	declare -xgr __acpi_battery_path="/sys/class/power_supply"

	return 0
}

acpi_battery_get_charge_full() {
	local battery

	battery="$1"

	if cat "$__acpi_battery_path/$battery/charge_full" 2>/dev/null; then
		return 0
	fi

	if cat "$__acpi_battery_path/$battery/energy_full" 2>/dev/null; then
		return 0
	fi

	return 1
}

acpi_battery_get_charge_now() {
	local battery

	battery="$1"

	if cat "$__acpi_battery_path/$battery/charge_now" 2>/dev/null; then
		return 0
	fi

	if cat "$__acpi_battery_path/$battery/energy_now" 2>/dev/null; then
		return 0
	fi

	return 1
}

acpi_battery_get_level() {
	local battery

        local full
	local now
	local lvl

	battery="$1"

	if ! full=$(acpi_battery_get_charge_full "$battery"); then
		return 1
	fi

	if ! now=$(acpi_battery_get_charge_now "$battery"); then
		return 1
	fi

	if (( full == 0 )); then
		return 1
	fi

	lvl=$((now * 100 / full))
	echo "$lvl"

	return 0
}
