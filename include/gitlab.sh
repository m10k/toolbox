#!/bin/bash

# gitlab.sh - Toolbox module for GitLab API v4
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
	if ! include "log" "json"; then
		return 1
	fi

	return 0
}

_gitlab_urlencode() {
        local str="$1"

        echo "${str//\//%2F}"
}

_gitlab_get() {
        local token="$1"
        local url="$2"

        if ! curl --silent --location -X GET \
	     --header "Private-Token: $token" "$url"; then
                return 1
        fi

        return 0
}

_gitlab_post() {
        local token="$1"
        local url="$2"
        local data="$3"

        if ! curl --silent --location -X POST \
             --header "Private-Token: $token" \
             --header "Content-Type: application/json" \
             --data "$data" "$url"; then
                return 1
        fi

        return 0
}

_gitlab_put() {
	local token="$1"
	local url="$2"

	if ! curl --silent --location -X PUT \
	          --header "Private-Token: $token" "$url"; then
		return 1
	fi

	return 0
}

gitlab_import_status() {
	local host="$1"
	local token="$2"
	local project="$3"

        local url
        local res

        id=$(_gitlab_urlencode "$project")
        url="$host/api/v4/projects/$id"

        if ! res=$(_gitlab_get "$token" "$url"); then
                return 1
        fi

        echo "$res" | jq -r ".import_status"
        return 0
}

gitlab_download_file() {
	local host="$1"
	local token="$2"
	local project="$3"
	local branch="$4"
	local file="$5"

	local url

	project=$(_gitlab_urlencode "$project")
	file=$(_gitlab_urlencode "$file")
	url="$host/api/v4/projects/$project/repository/files/$file/raw?ref=$branch"

	if ! _gitlab_get "$token" "$url"; then
		return 1
	fi

	return 0
}

gitlab_get_users() {
	local host="$1"
	local token="$2"

	local url

	url="$host/api/v4/users?per_page=512"

	if ! _gitlab_get "$token" "$url"; then
		return 1
	fi

	return 0
}

gitlab_user_list() {
	local host="$1"
	local token="$2"

	local resp

	if ! resp=$(gitlab_get_users "$host" "$token"); then
		return 1
	fi

	echo "$resp" | jq -r ".[] | \"\(.id) \(.username) \(.name)\""
	return 0
}

gitlab_get_current_user() {
	local host="$1"
	local token="$2"

	local url

	url="$host/api/v4/user"

	if ! _gitlab_get "$token" "$url"; then
		return 1
	fi

	return 0
}

gitlab_get_user_id() {
	local host="$1"
	local token="$2"
	local user="$3"

	local resp
	local uid
	local username
	local fullname

	if ! resp=$(gitlab_user_list "$host" "$token"); then
		return 1
	fi

	while read -r uid username fullname; do
		if [[ "$username" == "$user" ]]; then
			echo "$uid"
			return 0
		fi
	done <<< "$resp"

	return 1
}

gitlab_fork() {
	local host="$1"
	local token="$2"
	local project="$3"
	local namespace="$4"

	local url
	local id
	local data

	id=$(_gitlab_urlencode "$project")
	url="$host/api/v4/projects/$id/fork"

	# json_object() will silently drop the namespace if "$namespace" is empty
	data=$(json_object "id" "$id" \
			   "namespace" "$namespace")

	if ! _gitlab_post "$token" "$url" "$data"; then
		return 1
	fi

	return 0
}

gitlab_fork_sync() {
	local host="$1"
	local token="$2"
	local project="$3"
	local namespace="$4"

	local resp
	local fork_id

	if ! resp=$(gitlab_fork "$host" "$token" "$project" "$namespace"); then
		echo "Could not fork project" 1>&2
		return 1
	fi

	if ! fork_id=$(echo "$resp" | jq ".id"); then
		echo "Could not get id of fork" 1>&2
		return 1
	fi

	# Gitlab's fork API call returns before the fork completes, but we want
	# to make sure the fork is complete by the time we return to the caller

	while true; do
		local import_status

		if ! import_status=$(gitlab_import_status "$host" \
							  "$token" \
							  "$fork_id"); then
			echo "Could not get import status of fork" 1>&2
			return 1
		fi

		if [[ "$import_status" == "none" ]] ||
			   [[ "$import_status" == "finished" ]]; then
			break
		fi

		sleep 5
	done

	return 0
}

gitlab_create_branch() {
	local host="$1"
	local token="$2"
	local project="$3"
	local branch="$4"
	local ref="$5"

	local id
	local url

	id=$(_gitlab_urlencode "$project")
	data=$(json_make "id" "$id" "branch" "$branch" "ref" "$ref")
	url="$host/api/v4/projects/$id/repository/branches"

	if ! _gitlab_post "$token" "$url" "$data"; then
		return 1
	fi

	return 0
}

gitlab_project_get_branches() {
	local host="$1"
	local token="$2"
	local project="$3"

	local url
	local resp

	project=$(_gitlab_urlencode "$project")
	url="$host/api/v4/projects/$project/repository/branches"

	if ! resp=$(_gitlab_get "$token" "$url"); then
		return 1
	fi

	if ! echo "$resp" | jq -r ".[].name"; then
		return 1
	fi

	return 0
}

gitlab_project_get_members() {
	local host="$1"
	local token="$2"
	local project="$3"

	local project_id
	local url
	local resp

	if ! project_id=$(gitlab_get_project_id "$host"  \
						"$token" \
						"$project"); then
		return 1
	fi

	url="$host/api/v4/projects/$project_id/members/all"
	if ! resp=$(_gitlab_get "$token" "$url"); then
		return 1
	fi

	echo "$resp"
	return 0
}

gitlab_project_get_merge_requests() {
	local host="$1"
	local token="$2"
	local project="$3"

	local url
	local resp

	project=$(_gitlab_urlencode "$project")
	url="$host/api/v4/projects/$project/merge_requests?state=opened"

	if ! resp=$(_gitlab_get "$token" "$url"); then
		return 1
	fi

	echo "$resp"
	return 0
}

gitlab_project_mergerequest_get_votes() {
	local host="$1"
	local token="$2"
	local project="$3"
	local mergerequest="$4"

	local project_id
	local url
	local resp

	if ! project_id=$(gitlab_get_project_id "$host" "$token" "$project"); then
		return 1
	fi

	url="$host/api/v4/projects/$project_id/merge_requests/$mergerequest/award_emoji"
	if ! resp=$(_gitlab_get "$token" "$url"); then
		return 1
	fi

	echo "$resp"
	return 0
}

gitlab_project_mergerequest_comment() {
	local host="$1"
	local token="$2"
	local project="$3"
	local mergerequest="$4"
	local comment="$5"

	local project_id
	local url
	local data

	if ! project_id=$(gitlab_get_project_id "$host" "$token" "$project"); then
		return 1
	fi

	url="$host/api/v4/projects/$project_id/merge_requests/$mergerequest/notes"
	data=$(json_object "body" "$comment")

	if ! resp=$(_gitlab_post "$token" "$url" "$data"); then
		return 1
	fi

	return 0
}

gitlab_list_merge_requests() {
	local host="$1"
	local token="$2"
	local scope="$3"

	local url
	local resp

	if [[ -z "$scope" ]]; then
		scope="assigned_to_me"
	fi

	url="$host/api/v4/merge_requests?scope=$scope"

	if ! resp=$(_gitlab_get "$token" "$url"); then
		return 1
	fi

	echo "$resp"
	return 0
}

gitlab_project_merge_merge_request() {
	local host="$1"
	local token="$2"
	local project="$3"
	local mergerequest="$4"

	local project_id
	local url
	local resp

	if [[ "$project" =~ ^[0-9]+$ ]]; then
		project_id="$project"
	elif ! project_id=$(gitlab_get_project_id "$host" "$token" "$project"); then
		return 1
	fi

	url="$host/api/v4/projects/$project_id/merge_requests/$mergerequest/merge"

	if ! resp=$(_gitlab_put "$token" "$url"); then
		return 1
	fi

	echo "$resp"
	return 0
}

gitlab_get_project_id() {
	local host="$1"
	local token="$2"
	local project="$3"

	local url
	local resp

	project=$(_gitlab_urlencode "$project")
	url="$host/api/v4/projects/$project"

	if ! resp=$(_gitlab_get "$token" "$url"); then
		return 1
	fi

	echo "$resp" | jq ".id"
	return 0
}

gitlab_list_projects_page() {
	local host="$1"
	local token="$2"
	local perpage="$3"
	local page="$4"

	local url
	local results

	url="$host/api/v4/projects?simple=true&per_page=$perpage&page=$page"

	if ! results=$(_gitlab_get "$token" "$url"); then
		return 1
	fi

	echo "$results" | jq -r ".[] | \"\(.id) \(.path_with_namespace)\""

	return 0
}

gitlab_list_projects() {
	local host="$1"
	local token="$2"

	local page
	local perpage

	page=1
	perpage=50

	while true; do
		local projects
		local num

		if ! projects=$(gitlab_list_projects_page "$host" \
							  "$token" \
							  "$perpage" \
							  "$page"); then
			return 1
		fi

		num=$(echo "$projects" | wc -l)
		echo "$projects"

		if ((num < perpage)); then
			break
		fi

		((page++))
	done

	return 0
}

#
# gitlab_merge_request - Create a new merge request
#
# SYNOPSIS
#  gitlab_merge_request "$host" "$token" "$source" "$destination"
#                       "$title" "$assignee" "$description"
#
# DESCRIPTION
#  The gitlab_merge_request function creates a new merge request from the
#  repository:branch identified by $source to the repository:branch identified
#  by $destination. The title, assignee, and description of the merge request
#  will be set according to the $title, $assignee, and $description arguments,
#  respectively.
#
gitlab_merge_request() {
	local host="$1"
	local token="$2"
	local source="$3"
	local destination="$4"
	local title="$5"
	local assignee="$6"
	local description="$7"

	local source_name
	local destination_name
	local source_id
	local destination_id
	local source_branch
	local destination_branch
	local assignee_id
	local url

	source_name="${source%:*}"
	destination_name="${destination%:*}"
	source_branch="${source##*:}"
	destination_branch="${destination##*:}"

	if ! assignee_id=$(gitlab_get_user_id "$host" \
					      "$token" \
					      "$assignee"); then
		echo "Invalid user: $assignee" 1>&2
		return 1
	fi

	if [ -z "$source_branch" ]; then
		echo "Invalid source branch" 1>&2
		return 1
	fi

	if [ -z "$destination_branch" ]; then
		echo "Invalid destination branch" 1>&2
		return 1
	fi

	if ! source_id=$(gitlab_get_project_id "$host" "$token" "$source_name"); then
		echo "Could not get project id for $source_name" 1>&2
		return 1
	fi

	if ! destination_id=$(gitlab_get_project_id "$host" "$token" "$destination_name"); then
		echo "Could not get project id for $destination_name" 1>&2
		return 1
	fi

	data=$(json_make "id" "$source_id" \
			 "target_project_id" "$destination_id" \
			 "source_branch" "$source_branch" \
			 "target_branch" "$destination_branch" \
			 "title" "$title" \
			 "assignee_id" "$assignee_id" \
			 "description" "$description")
	url="$host/api/v4/projects/$source_id/merge_requests"

	if ! _gitlab_post "$token" "$url" "$data"; then
		return 1
	fi

	return 0
}
