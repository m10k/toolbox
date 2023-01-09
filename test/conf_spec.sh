#!/bin/bash

# conf_spec.sh - Test cases for the toolbox conf module
# Copyright (C) 2023 Matthias Kruk
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

. toolbox.sh
include "conf" "array"

Describe "conf_get()"
  It "prints the value of a valid configuration entry"
    _test_conf_get_valid() {
	    local key
	    local value
	    local saved_value

	    key="unlikely_to_exist_$RANDOM"
	    value="some_$RANDOM_value_$RANDOM"

	    if ! conf_set "$key" "$value"; then
		    return 1
	    fi

	    if ! saved_value=$(conf_get "$key"); then
		    return 2
	    fi

	    if [[ "$value" != "$saved_value" ]]; then
		    return 3
	    fi

	    return 0
    }

    When call _test_conf_get_valid
    The status should equal 0
  End

  It "defaults to the default configuration domain"
    _test_conf_get_valid_default() {
	    local key
	    local value
	    local saved_value

	    key="unlikely_to_exist_$RANDOM"
	    value="some.$RANDOM.value.$RANDOM"

	    if ! conf_set "$key" "$value" "default"; then
		    return 1
	    fi

	    if ! saved_value=$(conf_get "$key"); then
		    return 2
	    fi

	    if [[ "$value" != "$saved_value" ]]; then
		    return 3
	    fi

	    return 0
    }

    When call _test_conf_get_valid_default
    The status should equal 0
  End

  It "retrieves entries from user domains"
    _test_conf_get_valid_user_domain() {
	    local key
	    local value
	    local domain
	    local saved_value

	    key="unlikely_to_exist_$RANDOM"
	    value="some.$RANDOM.value.$RANDOM"
	    domain="$RANDOM.domain"

	    if ! conf_set "$key" "$value" "$domain"; then
		    return 1
	    fi

	    if ! saved_value=$(conf_get "$key" "$domain"); then
		    return 2
	    fi

	    if [[ "$value" != "$saved_value" ]]; then
		    return 3
	    fi

	    return 0
    }

    When call _test_conf_get_valid_user_domain
    The status should equal 0
  End

  It "returns an error if the requested entry does not exist"
    When call conf_get "unlikely.to.exist.$RANDOM.$RANDOM"
    The status should not equal 0
  End

  It "returns an error if the requested domain does not exist"
    When call conf_get "dontcare" "unlikely.to.exist.$RANDOM.$RANDOM"
    The status should not equal 0
  End
End

Describe "conf_unset()"
  It "removes an existing entry"
    _test_conf_unset_remove_existing() {
	    local key

	    key="unlikely.to.exist.$RANDOM.$RANDOM"

	    if ! conf_set "$key" "$RANDOM"; then
		    return 1
	    fi

	    # Retrieving an existing entry should work
	    if ! conf_get "$key" > /dev/null; then
		    return 2
	    fi

	    if ! conf_unset "$key"; then
		    return 3
	    fi

	    # This should fail now
	    if conf_get "$key" > /dev/null; then
		    return 4
	    fi

	    return 0
    }

    When call _test_conf_unset_remove_existing
    The status should equal 0
  End

  It "defaults to the default configuration domain"
    _test_conf_unset_default() {
	    local key

	    key="unlikely.to.exist.$RANDOM.$RANDOM"

	    if ! conf_set "$key" "$RANDOM" "default"; then
		    return 1
	    fi

	    if ! conf_unset "$key"; then
		    return 2
	    fi

	    if conf_get "$key" "default" > /dev/null; then
		    return 3
	    fi

	    return 0
    }

    When call _test_conf_unset_default
    The status should equal 0
  End

  It "removes entries from user domains"
    _test_conf_unset_user_domain() {
	    local key
	    local domain

	    key="unlikely.to.exist.$RANDOM.$RANDOM"
	    domain="unlikely.to.exist.$RANDOM.$RANDOM"

	    if ! conf_set "$key" "$RANDOM" "$domain"; then
		    return 1
	    fi

	    if ! conf_unset "$key" "$domain"; then
		    return 2
	    fi

	    if conf_get "$key" "$domain" > /dev/null; then
		    return 3
	    fi

	    return 0
    }

    When call _test_conf_unset_user_domain
    The status should equal 0
  End
End

Describe "conf_set()"
  It "creates an entry"
    _test_conf_set_create() {
	    local key
	    local value
	    local stored_value

	    key="unlikely_to_exist.$RANDOM"
	    value="$RANDOM"

	    if ! conf_set "$key" "$value"; then
		    return 1
	    fi

	    if ! stored_value=$(conf_get "$key"); then
		    return 2
	    fi

	    if [[ "$stored_value" != "$value" ]]; then
		    return 3
	    fi

	    return 0
    }

    When call _test_conf_set_create
    The status should equal 0
  End

  It "defaults to the default configuration domain"
    _test_conf_set_create_default() {
	    local key
	    local value
	    local stored_value

	    key="unlikely_to_exist.$RANDOM"
	    value="$RANDOM"

	    if ! conf_set "$key" "$value"; then
		    return 1
	    fi

	    if ! stored_value=$(conf_get "$key" "default"); then
		    return 2
	    fi

	    if [[ "$stored_value" != "$value" ]]; then
		    return 3
	    fi

	    return 0
    }

    When call _test_conf_set_create_default
    The status should equal 0
  End

  It "creates entries in user domains"
    _test_conf_set_create_user_domain() {
	    local key
	    local value
	    local domain
	    local stored_value

	    key="unlikely_to_exist.$RANDOM"
	    value="$RANDOM"
	    domain="unlikely_to_exist.$RANDOM"

	    if ! conf_set "$key" "$value" "$domain"; then
		    return 1
	    fi

	    if ! stored_value=$(conf_get "$key" "$domain"); then
		    return 2
	    fi

	    if [[ "$stored_value" != "$value" ]]; then
		    return 3
	    fi

	    return 0
    }

    When call _test_conf_set_create_user_domain
    The status should equal 0
  End
End

Describe "conf_get_domains()"
  It "returns the names of all configuration domains"
    _test_conf_get_domains() {
	    local before
	    local after
	    local new_domain
	    local -i lines_before
	    local -i lines_after

	    if ! readarray -t before < <(conf_get_domains); then
		    return 1
	    fi

	    new_domain="likely_new_domain.$RANDOM"
	    if ! conf_set "dontcare" "dontcare" "$new_domain"; then
		    return 2
	    fi

	    if ! readarray -t after < <(conf_get_domains); then
		    return 3
	    fi

	    lines_before=$(array_to_lines "${before[@]}" | wc -l)
	    lines_after=$(array_to_lines "${after[@]}" | wc -l)

	    if (( lines_after - lines_before != 1 )); then
		    return 4
	    fi

	    if ! array_contains "$new_domain" "${after[@]}"; then
		    return 5
	    fi

	    return 0
    }

    When call _test_conf_get_domains
    The status should equal 0
  End
End

Describe "conf_get_names()"
  It "returns the names of all configuration entries"
    _test_conf_get_names() {
	    local before
	    local after
	    local new_entry
	    local -i lines_before
	    local -i lines_after

	    if ! readarray -t before < <(conf_get_names); then
		    return 1
	    fi

	    new_entry="unlikely_to_exist.$RANDOM.$RANDOM"

	    if ! conf_set "$new_entry" "$RANDOM"; then
		    return 2
	    fi

	    if ! readarray -t after < <(conf_get_names); then
		    return 3
	    fi

	    lines_before=$(array_to_lines "${before[@]}" | wc -l)
	    lines_after=$(array_to_lines "${after[@]}" | wc -l)

	    if (( lines_after - lines_before != 1 )); then
		    return 1
	    fi

	    if ! array_contains "$new_entry" "${after[@]}"; then
		    return 1
	    fi

	    return 0
    }

    When call _test_conf_get_names
    The status should equal 0
  End

  It "defaults to the default configuration domain"
    _test_conf_get_names_default() {
	    local before
	    local after
	    local new_entry
	    local -i lines_before
	    local -i lines_after

	    if ! readarray -t before < <(conf_get_names); then
		    return 1
	    fi

	    new_entry="unlikely_to_exist.$RANDOM.$RANDOM"

	    if ! conf_set "$new_entry" "$RANDOM" "default"; then
		    return 2
	    fi

	    if ! readarray -t after < <(conf_get_names); then
		    return 3
	    fi

	    lines_before=$(array_to_lines "${before[@]}" | wc -l)
	    lines_after=$(array_to_lines "${after[@]}" | wc -l)

	    if (( (lines_after - lines_before) != 1 )); then
		    return 1
	    fi

	    if ! array_contains "$new_entry" "${after[@]}"; then
		    return 1
	    fi

	    return 0
    }

    When call _test_conf_get_names_default
    The status should equal 0
  End

  It "lists entries in user domains"
    _test_conf_get_names_user_domain() {
	    local before
	    local after
	    local new_entry
	    local domain
	    local -i lines_before
	    local -i lines_after

	    domain="unlikely_to_exist.$RANDOM.$RANDOM"
	    new_entry="unlikely_to_exist.$RANDOM.$RANDOM"

	    if ! conf_set "dontcare" "$RANDOM" "$domain"; then
		    return 1
	    fi

	    if ! readarray -t before < <(conf_get_names "$domain"); then
		    return 2
	    fi

	    if ! conf_set "$new_entry" "$RANDOM" "$domain"; then
		    return 3
	    fi

	    if ! readarray -t after < <(conf_get_names "$domain"); then
		    return 4
	    fi

	    lines_before=$(array_to_lines "${before[@]}" | wc -l)
	    lines_after=$(array_to_lines "${after[@]}" | wc -l)

	    if (( (lines_after - lines_before) != 1 )); then
		    return 5
	    fi

	    if ! array_contains "$new_entry" "${after[@]}"; then
		    return 6
	    fi

	    return 0
    }

    When call _test_conf_get_names_user_domain
    The status should equal 0
  End
End
