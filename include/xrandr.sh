#/bin/bash

__init() {
	return 0
}

xrandr_get_monitors() {
	local conns

	if ! conns=$(xrandr | grep -F " connected "); then
		return 1
	fi

	cut -d ' ' -f 1 <<< "$conns"
	return 0
}

_xrandr_list_all() {
	local screen
	local monitor
	local line

	local re_screen
	local re_monitor
	local re_current

	re_screen='Screen ([0-9]+):'
	re_monitor='([^ ]+) (dis)*connected'
	re_current='[0-9]+\.[0-9]+\*'

	while read -r line; do
		local resolution
		local freqs

		if [[ "$line" =~ $re_screen ]]; then
			screen="${BASH_REMATCH[1]}"
			continue
		fi

		if [[ "$line" =~ $re_monitor ]]; then
			monitor="${BASH_REMATCH[1]}"
			continue
		fi

		if read -r resolution other <<< "$line"; then
			local current

			if [[ "$other" =~ $re_current ]]; then
				current="current"
			else
				current=""
			fi

			echo "$screen $monitor $resolution $current"
		fi
	done < <(xrandr)

	return 0
}

xrandr_monitor_get_resolution() {
	local monitor="$1"

	local resolution

	if ! resolution=$(_xrandr_list_all | grep -F " $monitor " |
				  grep -F " current"); then
		return 1
	fi

	cut -d ' ' -f 3 <<< "$resolution"
	return 0
}

xrandr_monitor_get_resolutions() {
	local monitor="$1"
	local current_only="$2"

	local resolutions

	if ! resolutions=$(_xrandr_list_all | grep -F " $monitor "); then
		return 1
	fi

	cut -d ' ' -f 3 <<< "$resolutions"
	return 0
}
