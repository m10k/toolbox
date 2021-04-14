#!/bin/bash

#
# This implementation defines a queue as a directory containing
# a set of objects for synchronization, and a list that contains
# the elements in the queue.
# The objects used for synchronization are a lock and a semaphore,
# as described by the following petri net.
#
#                 .-----.
#  .--------------| c00 |---------------.
#  |              '-----'               |
#  |                                    |
#  '---|   .-----.   |    .-----.   |<--'
#      |<--| c02 |<--|<---| c01 |<--|
#  .---|   '-----'   |<-. '-----'   |<--.
#  |                    |               |
#  |       .-----.      |            .-----.
#  '-------| mtx |------'            | sem |
#          |  1  |                   |  0  |
#  .-------|     |<------.           |     |
#  |       '-----'       |           '-----'
#  |                     |              ^
#  '-->|   .-----.    |--' .-----.   |--'
#      |-->| p01 |--->|--->| p02 |-->|
#  .-->|   '-----'    |    '-----'   |--.
#  |                                    |
#  |               .-----.              |
#  '---------------| p00 |<-------------'
#                  '-----'
#
# The states have the following meaning:
#
#  c00: Consumer wait on semaphore (start position)
#  c01: Consumer wait on mutex
#  c02: Consumer dequeue element, release mutex
#  p00: Producer wait on mutex (start position)
#  p01: Producer enqueue element, release mutex
#  p02: Producer post semaphore
#  mtx: The mutex (start value 1 / unlocked)
#  sem: The semaphore (start value 0)
#
# The queue is implemented as a directory like this:
#
#  queue/
#   |- lock
#   |- sem
#   '- data
#
# Lock and sem may not actually be one filesystem object each
# (hint: they're not), but the queue implementation must not
# make any assumptions about this.
#
# In a nutshell, the queue can be used like this:
#
# if ! queue_init "myq"; then
#         # ERROR
# fi
#
# if ! queue_put "myq" "$data"; then
#         # ERROR
# fi
#
# if ! data=$(queue_get "myq"); then
#         # ERROR
# fi
#
# if ! queue_destroy "myq"; then
#         # ERROR
# fi
#

__init() {
	if ! include "mutex" "sem"; then
		return 1
	fi

	declare -xgr __queue_path="$TOOLBOX_HOME/queue"

	if ! mkdir -p "$__queue_path"; then
		return 1
	fi

	return 0
}

_queue_get_path() {
	local queue="$1"

	if [[ "$queue" == *"/"* ]]; then
		echo "$queue"
	else
		echo "$__queue_path/$queue"
	fi
}

_queue_get_sem() {
	local queue="$1"

	local path

	path=$(_queue_get_path "$queue")
	echo "$path/sem"
}

_queue_get_mutex() {
	local queue="$1"

	local path

	path=$(_queue_get_path "$queue")
	echo "$path/mutex"
}

_queue_get_data() {
	local queue="$1"

	local path

	path=$(_queue_get_path "$queue")
	echo "$path/data"
}

_queue_get_filedir() {
	local queue="$1"

	local path

	path=$(_queue_get_path "$queue")
	echo "$path/files"
}

queue_init() {
	local queue="$1"

	local path
	local sem

        path=$(_queue_get_path "$queue")
	sem=$(_queue_get_sem "$queue")

	if ! mkdir "$path" &> /dev/null; then
		return 1
	fi

	if ! sem_init "$sem" 0; then
		rmdir "$path" &> /dev/null
		return 1
	fi

	return 0
}

queue_destroy() {
	local queue="$1"

	local path
	local mutex
	local sem

	path=$(_queue_get_path "$queue")
	sem=$(_queue_get_sem "$queue")

	if ! sem_destroy "$sem"; then
		return 1
	fi

	if ! rm -rf "$path"; then
		return 1
	fi

	return 0
}

queue_put() {
	local queue="$1"
	local item="$2"

	local mutex
	local sem
	local data
	local err

	mutex=$(_queue_get_mutex "$queue")
	sem=$(_queue_get_sem "$queue")
	data=$(_queue_get_data "$queue")
	err=0

	mutex_lock "$mutex"

	if ! echo "$item" >> "$data"; then
		err=1
	fi

	mutex_unlock "$mutex"

	if (( err == 0 )); then
		if ! sem_post "$sem"; then
			err=1
		fi
	fi

	return "$err"
}

_queue_contains() {
	local queue="$1"
	local item="$2"

	local data
	local qdata

	data=$(_queue_get_data "$queue")

	while read -r qdata; do
		if [[ "$qdata" == "$data" ]]; then
			return 0
		fi
	done

	return 1
}

queue_put_unique() {
	local queue="$1"
	local item="$2"

	local mutex
	local sem
	local data
	local err

	# When this function returns success, the caller can be sure that
	# the item is in the queue. However, this includes the case that
	# it was already in the queue. Since the item is transient data,
	# this behavior seems appropriate. Files are a different story.

	mutex=$(_queue_get_mutex "$queue")
	sem=$(_queue_get_sem "$queue")
	data=$(_queue_get_data "$queue")

	mutex_lock "$mutex"

	if _queue_contains "$queue" "$item"; then
		err=-1
	else
		if ! echo "$item" >> "$data"; then
			err=1
		else
			err=0
		fi
	fi

	mutex_unlock "$mutex"

	if (( err == 0 )); then
		if ! sem_post "$sem"; then
			err=1
		fi
	elif (( err < 0 )); then
		err=0
	fi

	return "$err"
}

_queue_move_to_q() {
	local queue="$1"
	local filepath="$2"

	local filedir
	local filename
	local data
	local dest

	filedir=$(_queue_get_filedir "$queue")
	data=$(_queue_get_data "$queue")

	filename="${filepath##*/}"
	dest="$filedir/$filename"

	if ! cp -a "$filepath" "$dest"; then
		return 1
	fi

	if ! echo "$dest" >> "$data"; then
		log_error "Could not append to queue: $data"

		if ! rm -rf "$dest"; then
			log_error "Could not remove file from queue: $dest"
		fi

		return 1
	fi

	if ! rm -rf "$filepath"; then
		log_error "Could not remove source file: $filepath"
	fi

	return 0
}

queue_put_file() {
	local queue="$1"
	local filepath="$2"

	local mutex
	local sem
	local filedir
	local filename
	local data
	local err

	# Unlike queue_put_unique(), this function returns failure if the
	# file was already in the queue. The file queue does not allow
	# duplicates because files would be overwritten.

	filename="${filepath##*/}"

	mutex=$(_queue_get_mutex "$queue")
	filedir=$(_queue_get_filedir "$queue")
	sem=$(_queue_get_sem "$queue")

	mutex_lock "$mutex"

	if ! mkdir -p "$filedir" &> /dev/null; then
		err=1
	else
		local dest

		dest="$filedir/$filename"

		if [ -e "$filedir/$filename" ]; then
			# Must not succeed if the file was already in the queue
			err=1
		else
			if _queue_move_to_q "$queue" "$filepath"; then
				err=0
			else
				err=1
			fi
		fi
	fi

	mutex_unlock "$mutex"

	if (( err == 0 )); then
		if ! sem_post "$sem"; then
			err=1
		fi
	elif (( err < 0 )); then
		err=0
	fi

	return "$err"
}

queue_get() {
	local queue="$1"

	local sem
	local mutex
	local data
	local item
	local err

	sem=$(_queue_get_sem "$queue")
	mutex=$(_queue_get_mutex "$queue")
	data=$(_queue_get_data "$queue")

	err=false

	if ! sem_wait "$sem"; then
		return 1
	fi

	mutex_lock "$mutex"

	if ! item=$(head -n 1 "$data" 2>/dev/null); then
		err=true
	else
		if ! sed -i '1d' "$data" &>/dev/null; then
			err=true
		fi
	fi

	mutex_unlock "$mutex"

	if "$err"; then
		return 1
	fi

	echo "$item"
	return 0
}

queue_get_file() {
	local queue="$1"
	local destdir="$2"

	local sem
	local mutex
	local data
	local item
	local dest
	local err

	if ! [ -d "$destdir" ]; then
		log_error "Destination must be a directory"
		return 1
	fi

	sem=$(_queue_get_sem "$queue")
	mutex=$(_queue_get_mutex "$queue")
	data=$(_queue_get_data "$queue")

	err=false

	if ! sem_wait "$sem"; then
		return 1
	fi

	mutex_lock "$mutex"

	if ! item=$(head -n 1 "$data" 2>/dev/null); then
		err=true
	else
		dest="$destdir/${item##*/}"

		if ! sed -i '1d' "$data" 2>/dev/null; then
			log_error "Could not remove item from $data"
			err=true
		else
			log_debug "Moving $item to $dest"

			if ! mv "$item" "$dest"; then
				log_error "Could not move $item to $dest"

				if ! sed -i "1s|^|$item\n|" "$data"; then
					log_error "Could not put item back in queue"
				fi
				err=true
			fi
		fi
	fi

	mutex_unlock "$mutex"

	if "$err"; then
		return 1
	fi

	echo "$dest"
	return 0
}
