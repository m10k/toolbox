#!/bin/bash

__init() {
	if ! implements "vehicle"; then
		return 1
	fi

	if ! interface "get_name" "get_speed"; then
		return 1
	fi

	return 0
}

car_get_name() {
	echo "car"
}

car_get_speed() {
	echo "30"
}
