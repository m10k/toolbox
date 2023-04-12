#!/bin/bash

# git.sh - Toolbox module for interaction with git
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

	return 0
}

git_clone() {
	local source="$1"
	local destination="$2"

	local output

	if ! output=$(git clone "$source" "$destination" 2>&1); then
		log_error "Could not clone $source to $destination"
		log_highlight "git clone" <<< "$output" | log_error
		return 1
	fi

	return 0
}

git_branch_new() {
	local repository="$1"
	local branch="$2"

	local output

	if ! output=$(cd "$repository" && git branch "$branch" 2>&1); then
		log_error "Could not create branch $branch in $repository"
		log_highlight "git branch" <<< "$output" | log_error
		return 1
	fi

	return 0
}

git_branch_get_current() {
	local repository="$1"

	if ! grep -oP "refs/heads/\\K.*" < "$repository/.git/HEAD"; then
		log_error "Could not get current branch of $repository"
		return 1
	fi

	return 0
}

git_branch_get_commits() {
	local repository="$1"
	local branch="$2"

	if ! (cd "$repository" && git log --format="%H %aI %ae" "$branch" 2>/dev/null); then
		return 1
	fi

	return 0
}

git_branch_checkout() {
	local repository="$1"
	local branch="$2"

	local output

	if (( $# < 2 )); then
		branch="master"
	fi

	if ! output=$(cd "$repository" && git checkout "$branch" 2>&1); then
		log_error "Could not check out $branch in $repository"
		log_highlight "git checkout" <<< "$output" | log_error
		return 1
	fi

	return 0
}

git_merge() {
	local repository="$1"
	local source="$2"
	local destination="$3"

	local original_branch
	local output
	local err

	err=0

	if ! original_branch=$(git_branch_get_current "$repository"); then
		return 1
	fi

	if (( $# < 3 )); then
		destination="$original_branch"
	fi

	if [[ "$original_branch" != "$destination" ]]; then
		if ! git_branch_checkout "$repository" "$destination"; then
			return 1
		fi
	fi

	if ! output=$(cd "$repository" && git merge "$source" 2>&1); then
		log_error "Could not merge $source info $destination of $repository"
		log_highlight "git merge" <<< "$output" | log_error
		err=1
	fi

	if [[ "$original_branch" != "$destination" ]]; then
		if ! git_branch_checkout "$repository" "$original_branch"; then
			log_error "Could not check out previous branch $original_branch"
			return 1
		fi
	fi

	return "$err"
}

git_push() {
	local repository="$1"
	local branch="$2"
	local remote="$3"

	local output

	if (( $# < 3 )); then
		remote="origin"
	fi

	if (( $# < 2 )); then
		if ! branch=$(git_branch_get_current "$repository"); then
			return 1
		fi
	fi

	if ! output=$(cd "$repository" && git push "$remote" "$branch" 2>&1); then
		log_error "Could not push to $branch of $repository to $remote"
		log_highlight "git push" <<< "$output" | log_error
		return 1
	fi

	return 0
}

git_commit() {
	local repository="$1"
	local message="$2"

	local output

	if ! output=$(cd "$repository" && git commit -F - <<< "$message" 2>&1); then
		log_error "Could not commit to $repository"
		log_highlight "git commit" <<< "$output" | log_error
		return 1
	fi

	return 0
}

git_remote_get() {
	local repository="$1"
	local remote="$2"

	local url

	if ! url=$(cd "$repository" && git remote get-url "$remote"); then
		log_error "Could not get URL of remote $remote in $repository"
		return 1
	fi

	echo "$url"
	return 0
}
