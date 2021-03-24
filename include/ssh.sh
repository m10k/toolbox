#!/bin/bash

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

ssh_tunnel_open() {
	local tunnel_host
	local tunnel_user
	local remote_addr
	local remote_port
	local local_addr
	local local_port

	tunnel_host="$1"
	tunnel_user="$2"
	remote_addr="$3"
        remote_port="$4"
	local_addr="$5"
	local_port="$6"

	local ctrl_sock
	local addrspec
	local sshtarget

	if ! ctrl_sock=$(_ssh_tunnel_ctrl_socket_name "$remote_addr" \
						      "$remote_port" \
						      "$local_port"); then
		return 1
	fi

	addrspec="$local_addr:$local_port:$remote_addr:$remote_port"
	sshtarget="$tunnel_user@$tunnel_host"

	if ! ssh -M -S "$ctrl_sock" -fnNT -o "ExitOnForwardFailure=yes" \
	     -L "$addrspec" "$sshtarget" > /dev/null; then
		return 1
	fi

	echo "$ctrl_sock"
	return 0
}

ssh_tunnel_close() {
	local tunnel_host
	local tunnel_user
	local ctrl_sock

	tunnel_host="$1"
	tunnel_user="$2"
	ctrl_sock="$3"

	if ! ssh -S "$ctrl_sock" -O exit "$tunnel_user@$tunnel_host" &> /dev/null; then
		return 1
	fi

	return 0
}

ssh_proxy_open() {
	local proxy_host
	local proxy_user
	local local_addr
	local local_port

	local ctrl_sock
	local addrspec
	local sshtarget

	proxy_host="$1"
	proxy_user="$2"
	local_addr="$3"
	local_port="$4"

	if ! ctrl_sock=$(_ssh_proxy_ctrl_socket_name "$local_addr" "$local_port"); then
		return 1
	fi

	addrspec="$local_addr:$local_port"
	sshtarget="$proxy_user@$proxy_host"

	if ! ssh -M -S "$ctrl_sock" -fnNT -o "ExitOnForwardFailure=yes" \
	     -D "$addrspec" "$sshtarget" > /dev/null; then
		return 1
	fi

	echo "$ctrl_sock"
	return 0
}

ssh_proxy_close() {
	local proxy_host
	local proxy_user
	local ctrl_sock

	proxy_host="$1"
	proxy_user="$2"
	ctrl_sock="$3"

	if ! ssh -S "$ctrl_sock" -O exit "$proxy_user@$proxy_host" &> /dev/null; then
		return 1
	fi

	return 0
}
