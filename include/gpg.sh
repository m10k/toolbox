#!/bin/bash

# gpg.sh - Toolbox module for GnuPG
# Copyright (C) 2021-2026 Matthias Kruk
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
	declare -gxr __gpg_root="$TOOLBOX_HOME/gpg"

	local -a submodules

	submodules=(
		"gpg/key"
		"gpg/keyring"
	)

	if ! include "${submodules[@]}"; then
		return 1
	fi

	return 0
}

gpg_get_root() {
	echo "$__gpg_root"
	return 0
}
