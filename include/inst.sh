#!/bin/bash

# inst.sh - Toolbox module for daemonized scripts
# Copyright (C) 2021-2022 Matthias Kruk
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
	local name

	name="${0##*/}"

	if [[ -z "$name" ]]; then
		echo "Could not determine script name" 1>&2
		return 1
	fi

	if ! include "opt" "sem"; then
		return 1
	fi

	declare -xgr __inst_name="$name"
	declare -xgr __inst_root="/tmp/$USER/toolbox/inst"
	declare -xgr __inst_path="$__inst_root/$__inst_name"

	if ! mkdir -p "$__inst_path"; then
		return 1
	fi

	opt_add_arg "l" "list" ""  0  "List running instances"  ''         _inst_handle_opt_list
	opt_add_arg "s" "stop" "v" "" "Stop a running instance" '^[0-9]+$' _inst_handle_opt_stop

	return 0
}

_inst_handle_opt_stop() {
	local opt="$1"
	local arg="$2"

	inst_stop "$arg" "$__inst_name"; then
	exit "$?"
}

_inst_handle_opt_list() {
	local opt="$1"
	local arg="$2"

	inst_list "$__inst_name"
	exit "$?"
}

inst_list() {
	local instname="$1"

	local instpath
	local sem

	if [[ -z "$instname" ]]; then
		instname="$__inst_name"
	fi
	instpath="$__inst_root/$instname"

	while read -r sem; do
		local owner
		local semval
		local state
	        local argv
		local status_text
		local status_time
		local timestamp

		owner="${sem##*/}"
		semval=$(sem_peek "$sem")

		if ! readarray -t argv < "$sem.argv" 2> /dev/null; then
			continue
		fi

		if ! status_text=$(inst_get_status_message "$owner" "$instname") ||
		   ! status_time=$(inst_get_status_timestamp "$owner" "$instname"); then
			continue
		fi

		if ! timestamp=$(date --date="@$status_time" +"%Y-%m-%d %H:%M:%S %z"); then
			continue
		fi

		if (( semval > 0 )); then
			state="STOPPING"
		else
			state="RUNNING"
		fi

		echo "$owner $state [$timestamp:$status_text] $instname ${argv[*]}"
	done < <(find "$instpath" -regex ".*/[0-9]+")

	return 0
}

inst_stop() {
	local pid="$1"
	local instname="$2"

	local sem
	local instpath

	if [[ -z "$instname" ]]; then
		instname="$__inst_name"
	fi
	instpath="$__inst_root/$instname"

	sem="$instpath/$pid"

	if ! sem_post "$sem" &> /dev/null; then
		log_error "No such instance"
		return 1
	fi

	return 0
}

inst_running() {
	if ! sem_trywait "$__inst_sem"; then
		return 0
	fi

	# The next invocation of inst_running() will return true if we don't
	# increase the semaphore here, since sem_trywait() decreased it.
	if ! sem_post "$__inst_sem"; then
		log_warn "Could not post semaphore $__inst_sem"
	fi

	return 1
}

_inst_stop_self() {
	if ! inst_stop "$BASHPID"; then
		return 1
	fi

	return 0
}

_inst_run() {
	local cmd="$1"
	local args=("${@:2}")

	local ret

	declare -xgr __inst_sem="$__inst_path/$BASHPID"
	declare -xgr __inst_status="$__inst_path/$BASHPID.status"

	if ! opt_get_argv > "$__inst_path/$BASHPID.argv"; then
		log_error "Could not save args"
		return 1
	fi

	if ! inst_set_status "unset"; then
		return 1
	fi

	if ! sem_init "$__inst_sem" 0; then
		log_error "Could not initialize semaphore $__inst_sem"
		return 1
	fi

	trap _inst_stop_self INT HUP TERM

	if ! "$cmd" "${args[@]}"; then
		ret=1
	else
		ret=0
	fi

	if ! sem_destroy "$__inst_sem"; then
		log_error "Could not destroy semaphore $__inst_sem"
	fi

	exit "$ret"
}

inst_start() {
	_inst_run "$@" </dev/null &>/dev/null &
	disown

	return 0
}

inst_set_status() {
	local status="$1"

	local timestamp

	if ! timestamp=$(date +"%s"); then
		log_error "Couldn't make timestamp"
		return 1
	fi

	if ! echo "$timestamp:$status" > "$__inst_status"; then
		log_error "Could not write to $__inst_status"
		return 1
	fi

	return 0
}

inst_get_status() {
	local pid="$1"
	local instname="$2"

	local status
	local instpath

	if [[ -z "$instname" ]]; then
		instname="$__inst_name"
	fi
	instpath="$__inst_root/$instname"

	if ! status=$(< "$instpath/$pid.status"); then
		log_error "Could not read from $instpath/$pid.status"
		return 1
	fi

	echo "$status"
	return 0
}

inst_get_status_message() {
	local pid="$1"
	local instname="$2"

	if ! status=$(inst_get_status "$pid" "$instname"); then
		return 1
	fi

	echo "${status#*:}"
	return 0
}

inst_get_status_timestamp() {
	local pid="$1"
	local instname="$2"

	local status

	if ! status=$(inst_get_status "$pid" "$instname"); then
		return 1
	fi

	echo "${status%%:*}"
	return 0
}

inst_count() {
	local instname="$1"

        local -i num
	local instpath

	if [[ -z "$instname" ]]; then
		instname="$__inst_name"
	fi
	instpath="$__inst_root/$instname"

        if ! num=$(find "$instpath" -regex ".*/[0-9]+" | wc -l); then
                return 1
        fi

        echo "$num"
        return 0
}

inst_singleton() {
        local args=("$@")

        if (( $(inst_count "$__inst_name") > 0 )); then
                log_error "Another instance is already running"
                return 1
        fi

        if ! inst_start "${args[@]}"; then
                return 1
        fi

        return 0
}
