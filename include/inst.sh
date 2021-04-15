#!/bin/bash

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
	declare -xgr __inst_path="$TOOLBOX_HOME/inst/$__inst_name"

	if ! mkdir -p "$__inst_path"; then
		return 1
	fi

	opt_add_arg "l" "list" "no"  0  "List running instances"  _inst_handle_opt
	opt_add_arg "s" "stop" "yes" "" "Stop a running instance" _inst_handle_opt

	return 0
}

_inst_handle_opt() {
	local opt="$1"
	local arg="$2"

	local ret

	ret=0

	case "$opt" in
		"stop")
			if ! inst_stop "$arg"; then
				ret=1
			fi
			;;

		"list")
			if ! inst_list; then
				ret=1
			fi
			;;

		*)
			ret=1
			;;
	esac

	exit "$ret"
}

inst_list() {
	local sem

	while read -r sem; do
		local owner
		local semval
		local state
		local argv

		owner="${sem##*/}"
		semval=$(sem_peek "$sem")

		if ! argv=$(<"$sem.argv") 2> /dev/null; then
			continue
		fi

		if (( semval > 0 )); then
			state="STOPPING"
		else
			state="RUNNING"
		fi

		echo "$owner $state $__inst_name $argv"
	done < <(find "$__inst_path" -regex ".*/[0-9]+")

	return 0
}

inst_stop() {
	local pid="$1"

	local sem

	sem="$__inst_path/$pid"

	if ! sem_post "$sem"; then
		return 1
	fi

	return 0
}

inst_running() {
	if ! sem_trywait "$__inst_sem"; then
		return 0
	fi

	return 1
}

_inst_run() {
	local cmd="$1"
	local args=("${@:2}")

	local ret

	declare -xgr __inst_sem="$__inst_path/$BASHPID"

	if ! opt_get_argv > "$__inst_path/$BASHPID.argv"; then
		log_error "Could not save args"
		return 1
	fi

	if ! sem_init "$__inst_sem" 0; then
		log_error "Could not initialize semaphore $__inst_sem"
		return 1
	fi

	if ! "$cmd" "${args[@]}"; then
		ret=1
	else
		ret=0
	fi

	if ! sem_destroy "$__inst_sem"; then
		log_error "Could not destroy semaphore $__inst_sem"
	fi

	return "$ret"
}

inst_start() {
	_inst_run "$@" </dev/null &>/dev/null &
	disown

	return 0
}
