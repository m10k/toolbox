#!/bin/bash

#
# Toolbox - A set of unsophisticated bash "modules"
# Copyright (C) 2021 - Matthias Kruk <m@m10k.eu>
#

__toolbox_init() {
	export TOOLBOX_PATH="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
	export TOOLBOX_HOME="$HOME/.toolbox"

	declare -ag __TOOLBOX_INCLUDED=()

	return 0
}

have() {
	local module
	local included

	module="$1"

	for included in "${__TOOLBOX_INCLUDED[@]}"; do
		local modpath

		modpath="$TOOLBOX_PATH/include/$module.sh"

		if [[ "$included" == "$modpath" ]]; then
			return 0
		fi
	done

	return 1
}

include() {
	local err
	local module

	err=0

	for module in "$@"; do
		local modpath

		if have "$module"; then
			continue
		fi

		modpath="$TOOLBOX_PATH/include/$module.sh"

		if ! . "$modpath"; then
			echo "ERROR: Could not load $modpath" 1>&2
			err=1
			continue
		fi

		if ! __init; then
			echo "ERROR: Could not initialize $module" 1>&2
			err=1
		else
			__TOOLBOX_INCLUDED+=("$modpath")
		fi

		unset -f __init
	done

	return "$err"
}

{
	if ! compgen -v | grep "^__TOOLBOX_INCLUDED$" &> /dev/null; then
		if ! __toolbox_init; then
			echo "Could not initialize toolbox" 1>&2
		fi

		unset -f __toolbox_init
	fi
}
