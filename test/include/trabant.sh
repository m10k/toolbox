#!/bin/bash

__init() {
	if ! implements "car"; then
		return 1
	fi

	return 0
}

trabant_get_name() {
	echo "trabant"
}
