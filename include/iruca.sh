#!/bin/bash

# iruca.sh - Iruca module for Toolbox
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

__init() {
	if ! include "array" "json"; then
		return 1
	fi

	declare -xgr __iruca_state_present="在席"
	declare -xgr __iruca_state_absent="退社"
	declare -xgr __iruca_state_awayfromkeyboard="離席"
	declare -xgr __iruca_state_outside="外出"
	declare -xgr __iruca_state_dayoff="休暇"
	declare -xgr __iruca_state_workfromhome="テレワーク"

	declare -xgr __iruca_url="https://iruca.co/api"

	return 0
}

_iruca_get() {
	local token
	local url

	token="$1"
	url="$2"

	if ! curl --silent --location \
	     --header "X-Iruca-Token: $token" \
	     "$url"; then
		return 1
	fi

	return 0
}

_iruca_put() {
	local token
	local url
	local data

	token="$1"
	url="$2"
	data="$3"

	if ! curl --silent --location -X PUT \
	     --header "X-Iruca-Token: $token" \
	     --header "Content-Type: application/json" \
	     --data "$data" "$url"; then
		return 1
	fi

	return 0
}

iruca_list_members() {
	local token
	local room

	local url

	token="$1"
	room="$2"

	url="$__iruca_url/rooms/$room/members"

	if ! _iruca_get "$token" "$url"; then
		return 1
	fi

	return 0
}

iruca_get_status() {
	local token
	local room
	local member

	local url

	token="$1"
	room="$2"
	member="$3"

	url="$__iruca_url/rooms/$room/members/$member"

	if ! _iruca_get "$token" "$url"; then
		return 1
	fi

	return 0
}

_iruca_status_is_valid() {
	local status

	local valid_states

	status="$1"

	valid_states=(
		"$__iruca_state_present"
		"$__iruca_state_absent"
		"$__iruca_state_awayfromkeyboard"
		"$__iruca_state_outside"
		"$__iruca_state_dayoff"
		"$__iruca_state_workfromhome"
	)

	if array_contains "$status" "${valid_states[@]}"; then
		return 0
	fi

	return 1
}

iruca_set_status() {
	local token
	local room
	local member
	local status
	local message

	local url
	local data

	token="$1"
	room="$2"
	member="$3"
	status="$4"
	message="$5"

	if ! _iruca_status_is_valid "$status"; then
		return 1
	fi

	data=$(json_object "status" "$status" \
			   "message" "$message")

	url="$__iruca_url/rooms/$room/members/$member"

	if ! _iruca_put "$token" "$url" "$data" > /dev/null; then
		return 1
	fi

	return 0
}
