#!/bin/bash

# conf.sh - Unsophisticated configuration module for Toolbox
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
        local script_name

	if ! include "log"; then
		return 1
	fi

        script_name="${0##*/}"
	script_name="${script_name%.*}"

        if [[ -z "$script_name" ]]; then
		log_error "Could not determine script name"
                return 1
        fi

	declare -xgr __conf_root="$TOOLBOX_HOME/conf"
	declare -xgr __conf_file="$__conf_root/$script_name.conf"

	if ! mkdir -p "$__conf_root"; then
		log_error "Could not create config dir"
		return 1
	fi

	return 0
}

conf_get() {
	local name="$1"
	local default="$2"

	if ! grep -m 1 -oP "^$name=\K.*" "$__conf_file" 2>/dev/null; then
		if (( $# <= 1 )); then
			return 1
		fi

		echo "$default"
	fi

	return 0
}

conf_unset() {
	local name="$1"

	if ! sed -i -e "/^$name=.*/d" "$__conf_file" &> /dev/null; then
		return 1
	fi

	return 0
}


conf_set() {
	local name="$1"
	local value="$2"

	if conf_get "$name" &> /dev/null; then
		if ! conf_unset "$name"; then
			return 1
		fi
	fi

	if ! echo "$name=$value" >> "$__conf_file"; then
		return 1
	fi

	return 0
}
