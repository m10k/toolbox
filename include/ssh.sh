#!/bin/bash

# ssh.sh - Toolbox module for SSH tunnels and dynamic proxies
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
	if ! include "log"; then
		return 1
	fi

	declare -xgr __ssh_socket_dir="$TOOLBOX_HOME/ssh"

	return 0
}

_ssh_get_socket_dir() {
	if ! mkdir -p "$__ssh_socket_dir" &> /dev/null; then
		error "Could not create $__ssh_socket_dir"
		return 1
	fi

	echo "$__ssh_socket_dir"
	return 0
}

_ssh_tunnel_ctrl_socket_name() {
	local host
	local port
	local lport

	local sockdir

	host="$1"
	port="$2"
	lport="$3"

	if ! sockdir=$(_ssh_get_socket_dir); then
		return 1
	fi

	echo "$sockdir/tunnel-$lport-$host-$port.sock"
	return 0
}

_ssh_proxy_ctrl_socket_name() {
	local host
	local port

	local sockdir

	host="$1"
	port="$2"

	if ! sockdir=$(_ssh_get_socket_dir); then
		return 1
	fi

	echo "$sockdir/proxy-$host-$port.sock"
	return 0
}

_ssh_make_handle() {
	local ctrlsock="$1"
	local hostspec="$2"

	local handle

	if ! handle=$(base64 <<< "$ctrlsock" 2>/dev/null); then
		return 1
	fi

	handle+=":"

	if ! handle+=$(base64 <<< "$hostspec" 2>/dev/null); then
		return 1
	fi

	echo "$handle"
	return 0
}

_ssh_handle_get_ctrlsock() {
	local handle="$1"

	local ctrlsock

	if ! ctrlsock=$(base64 -d <<< "${handle%%:*}" 2>/dev/null); then
		return 1
	fi

	echo "$ctrlsock"
	return 0
}

_ssh_handle_get_hostspec() {
	local handle="$1"

	local hostspec

	if ! hostspec=$(base64 -d <<< "${handle##*:}" 2>/dev/null); then
		return 1
	fi

	echo "$hostspec"
	return 0
}

ssh_tunnel_open() {
	local tunnel_host="$1"
	local tunnel_user="$2"
	local remote_addr="$3"
	local remote_port="$4"
	local local_addr="$5"
	local local_port="$6"

	local ctrl_sock
	local addrspec
	local sshtarget
	local handle

	addrspec="$local_addr:$local_port:$remote_addr:$remote_port"
	sshtarget="$tunnel_user@$tunnel_host"

	if ! ctrl_sock=$(_ssh_tunnel_ctrl_socket_name "$remote_addr" \
						      "$remote_port" \
						      "$local_port"); then
		return 1
	fi

	if ! handle=$(_ssh_make_handle "$ctrl_sock" "$sshtarget"); then
		return 1
	fi

	if ! ssh -M -S "$ctrl_sock" -fnNT -o "ExitOnForwardFailure=yes" \
	     -L "$addrspec" "$sshtarget" > /dev/null; then
		return 1
	fi

	echo "$handle"
	return 0
}

ssh_proxy_open() {
	local proxy_host="$1"
	local proxy_user="$2"
	local local_addr="$3"
	local local_port="$4"

	local ctrl_sock
	local addrspec
	local sshtarget
	local handle

	addrspec="$local_addr:$local_port"
	sshtarget="$proxy_user@$proxy_host"

	if ! ctrl_sock=$(_ssh_proxy_ctrl_socket_name "$local_addr" "$local_port"); then
		return 1
	fi

	if ! handle=$(_ssh_make_handle "$ctrl_sock" "$sshtarget"); then
		return 1
	fi

	if ! ssh -M -S "$ctrl_sock" -fnNT -o "ExitOnForwardFailure=yes" \
	     -D "$addrspec" "$sshtarget" > /dev/null; then
		return 1
	fi

	echo "$handle"
	return 0
}

ssh_close() {
	local handle="$1"

	local ctrlsock
	local hostspec

	if ! ctrlsock=$(_ssh_handle_get_ctrlsock "$handle") ||
	   ! hostspec=$(_ssh_handle_get_hostspec "$handle"); then
		log_error "Invalid handle"
		return 1
	fi

	if ! ssh -S "$ctrlsock" -O exit "$hostspec" &> /dev/null; then
		return 1
	fi

	return 0
}
