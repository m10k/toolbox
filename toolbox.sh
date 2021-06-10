#!/bin/bash

# toolbox.sh - Framework for modular bash scripts
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

__toolbox_init() {
	local modpath

	if ! modpath="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"; then
		echo "Could not determine toolbox path" 1>&2
		return 1
	fi

	declare -gxr TOOLBOX_PATH="$modpath"
	declare -gxr TOOLBOX_HOME="$HOME/.toolbox"
	declare -axgr __TOOLBOX_MODULEPATH=(
		"$TOOLBOX_HOME/include"
		"$modpath/include"
	)

	declare -Axg __TOOLBOX_INCLUDED

	return 0
}

have() {
	local module="$1"

        if [[ -n "${__TOOLBOX_INCLUDED[$module]}" ]]; then
		return 0
	fi

	return 1
}

_try_include() {
	local mod_name
	local mod_path
	local err

	mod_name="$1"
	mod_path="$2"

	if ! . "$mod_path" &>/dev/null; then
		return 1
	fi

	if ! __init; then
		echo "ERROR: Could not initialize $module" 1>&2
		err=1
	else
		__TOOLBOX_INCLUDED["$mod_name"]="$mod_path"
		err=0
	fi

	unset -f __init

	return "$err"
}

include() {
	local module

	for module in "$@"; do
		local searchpath
		local loaded

		if have "$module"; then
			continue
		fi

		loaded=false

		for searchpath in "${__TOOLBOX_MODULEPATH[@]}"; do
			local modpath

			modpath="$searchpath/$module.sh"

			if _try_include "$module" "$modpath"; then
				loaded=true
				break
			fi
		done

		if ! "$loaded"; then
			echo "ERROR: Could not include $module" 1>&2
			return 1
		fi
	done

	return 0
}

{
	if ! compgen -v | grep "^__TOOLBOX_INCLUDED$" &> /dev/null; then
		if ! __toolbox_init; then
			echo "Could not initialize toolbox" 1>&2
		fi

		unset -f __toolbox_init
	fi
}
