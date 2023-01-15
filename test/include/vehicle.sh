#!/bin/bash

__init() {
	if ! interface "get_name"; then
		return 1
	fi

	return 0
}
