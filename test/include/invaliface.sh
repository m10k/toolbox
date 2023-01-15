#!/bin/bash

__init() {
	if ! implements "missinginterface"; then
		return 1
	fi
}
