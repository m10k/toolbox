#!/bin/bash

#
# gitlab_api.sh - Bash functions to access Gitlab API
# Author: Matthias Kruk <matthias.kruk@miraclelinux.com>
#

__init() {
	if ! include "log" "json"; then
		return 1
	fi

	return 0
}

_gitlab_urlencode() {
        local str

        str="$1"

        echo "${str//\//%2F}"
}

_gitlab_get() {
        local token
        local url

	token="$1"
	url="$2"

        if ! curl --silent --location -X GET \
	     --header "Private-Token: $token" "$url"; then
                return 1
        fi

        return 0
}

_gitlab_post() {
        local token
        local url
        local data

        token="$1"
        url="$2"
        data="$3"

        if ! curl --silent --location -X POST \
             --header "Private-Token: $token" \
             --header "Content-Type: application/json" \
             --data "$data" "$url"; then
                return 1
        fi

        return 0
}

gitlab_import_status() {
	local host
        local token
        local project

        local url
        local res

	host="$1"
        token="$2"
        project="$3"

        id=$(_gitlab_urlencode "$project")
        url="$host/api/v4/projects/$id"

        if ! res=$(_gitlab_get "$token" "$url"); then
                return 1
        fi

        echo "$res" | jq -r ".import_status"
        return 0
}

gitlab_download_file() {
	local host
	local token
	local project
	local branch
	local file

	local url

	host="$1"
	token="$2"
	project="$3"
	branch="$4"
	file="$5"

	project=$(_gitlab_urlencode "$project")
	file=$(_gitlab_urlencode "$file")
	url="$host/api/v4/projects/$project/repository/files/$file/raw?ref=$branch"

	if ! _gitlab_get "$token" "$url"; then
		return 1
	fi

	return 0
}

gitlab_get_users() {
	local host
	local token

	local url

	host="$1"
	token="$2"

	url="$host/api/v4/users?per_page=512"

	if ! _gitlab_get "$token" "$url"; then
		return 1
	fi

	return 0
}

gitlab_user_list() {
	local host
	local token

	local resp

	host="$1"
	token="$2"

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
	local host
	local token
	local user

	local resp
	local uid
	local username
	local fullname

	host="$1"
	token="$2"
	user="$3"

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
	local host
	local token
	local project
	local branch
	local ref

	local id
	local url

	host="$1"
	token="$2"
	project="$3"
	branch="$4"
        ref="$5"

	id=$(_gitlab_urlencode "$project")
	data=$(json_make "id" "$id" "branch" "$branch" "ref" "$ref")
	url="$host/api/v4/projects/$id/repository/branches"

	if ! _gitlab_post "$token" "$url" "$data"; then
		return 1
	fi

	return 0
}

gitlab_project_get_branches() {
	local host
	local token
	local project

	local url
	local resp

	host="$1"
	token="$2"
	project="$3"

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

gitlab_get_project_id() {
	local host
	local token
	local project

	local url
	local resp

	host="$1"
	token="$2"
	project="$3"

	project=$(_gitlab_urlencode "$project")
	url="$host/api/v4/projects/$project"

	if ! resp=$(_gitlab_get "$token" "$url"); then
		return 1
	fi

	echo "$resp" | jq ".id"
	return 0
}

gitlab_list_projects_page() {
	local host
	local token
	local perpage
	local page

	local url
	local results

	host="$1"
	token="$2"
	perpage="$3"
	page="$4"

	url="$host/api/v4/projects?simple=true&per_page=$perpage&page=$page"

	if ! results=$(_gitlab_get "$token" "$url"); then
		return 1
	fi

	echo "$results" | jq -r ".[] | \"\(.id) \(.path_with_namespace)\""

	return 0
}

gitlab_list_projects() {
	local host
	local token

	local page
	local perpage

	host="$1"
	token="$2"

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
	local host
	local token
	local source
	local destination
	local title
	local assignee
	local description

	local source_name
	local destination_name
	local source_id
	local destination_id
	local source_branch
	local destination_branch
	local assignee_id
	local url

	host="$1"
	token="$2"
	source="$3"
	destination="$4"
	title="$5"
	assignee="$6"
	description="$7"

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
