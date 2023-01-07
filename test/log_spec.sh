#!/bin/bash

# log_spec.sh - Test cases for the toolbox log module
# Copyright (C) 2021-2023 Matthias Kruk
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

include "log"
include "array"

cleanup() {
	rm -f "$__log_file"
}

Describe "log_set_verbosity()"
  It "sets the verbosity to the specified value (if valid)"
    _test_log_set_verbosity_valid() {
	    local verb_min
	    local verb_max
	    local verb_cur

	    verb_min="$__log_error"
	    verb_max="$__log_debug"

	    # Make sure the verbosity is actually changed every time
	    if (( __log_verbosity == verb_min )); then
		    ((__log_verbosity++))
	    fi

	    for (( verb_cur = verb_min; verb_cur <= verb_max; verb_cur++ )); do
		    if ! log_set_verbosity "$verb_cur"; then
			    return 1
		    fi

		    if (( __log_verbosity != verb_cur )); then
			    return 1
		    fi
	    done

	    return 0
    }

    When call _test_log_set_verbosity_valid
    The status should equal 0
  End

  It "sets the verbosity to a valid value (if invalid value given)"
    _test_log_set_verbosity_invalid() {
	    local verb_min
	    local verb_max
	    local verb_cur

	    verb_min="$__log_error"
	    verb_max="$__log_debug"

	    for (( verb_cur = -10; verb_cur <= 10; verb_cur++ )); do
		    if ! log_set_verbosity "$verb_cur"; then
			    return 1
		    fi

		    if (( __log_verbosity < verb_min )) ||
		       (( __log_verbosty > verb_max )); then
			    return 1
		    fi
	    done

	    return 0
    }

    When call _test_log_set_verbosity_invalid
    The status should equal 0
  End

End

Describe "log_get_verbosity()"
  It "returns the current verbosity level"
    _test_log_get_verbosity() {
	    local verb_min
	    local verb_max
	    local verb_cur

	    verb_min="$__log_error"
	    verb_max="$__log_debug"
	    __log_verbosity=-1

	    for (( verb_cur = verb_min; verb_cur <= verb_max; verb_cur++ )); do
		    local verb_act

		    if ! log_set_verbosity "$verb_cur"; then
			    return 1
		    fi

		    if ! verb_act=$(log_get_verbosity); then
			    return 1
		    fi

		    if (( verb_act != verb_cur )); then
			    return 1
		    fi

		    if (( verb_act != __log_verbosity )); then
			    return 1
		    fi
	    done

	    return 0
    }

    When call _test_log_get_verbosity
    The status should equal 0
  End
End

Describe "log_increase_verbosity()"
  It "increases the verbosity (if not at highest level)"
    _test_log_increase_verbosity_valid() {
	    local verb_min
	    local verb_max
	    local verb_cur

	    verb_min="$__log_error"
	    verb_max="$__log_debug"

	    for (( verb_cur = verb_min; verb_cur < verb_max; verb_cur++ )); do
		    local verb_act

		    log_set_verbosity "$verb_cur"
		    verb_act=$(log_get_verbosity)

		    if (( verb_act != verb_cur )); then
			    return 1
		    fi

		    log_increase_verbosity

		    verb_act=$(log_get_verbosity)
		    if (( verb_act != (verb_cur + 1) )); then
			    return 1
		    fi
	    done

	    return 0
    }

    When call _test_log_increase_verbosity_valid
    The status should equal 0
  End

  It "does not increase the verbosity above the highest level"
    _test_log_increase_verbosity_invalid() {
	    local verb_max
	    local verb_act

	    verb_max="$__log_debug"

	    log_set_verbosity "$verb_max"
	    verb_act=$(log_get_verbosity)

	    if (( verb_act != verb_max )); then
		    return 1
	    fi

	    log_increase_verbosity
	    verb_act=$(log_get_verbosity)

	    if (( verb_act != verb_max )); then
		    return 1
	    fi

	    return 0
    }

    When call _test_log_increase_verbosity_invalid
    The status should equal 0
  End
End

Describe "log_decrease_verbosity()"
  It "decreases the verbosity (if not at lowest level)"
    _test_log_decrease_verbosity_valid() {
	    local verb_min
	    local verb_max
	    local verb_cur

	    verb_min="$__log_error"
	    verb_max="$__log_debug"

	    for (( verb_cur = verb_max; verb_cur > verb_min; verb_cur-- )); do
		    local verb_act

		    log_set_verbosity "$verb_cur"
		    verb_act=$(log_get_verbosity)

		    if (( verb_act != verb_cur )); then
			    return 1
		    fi

		    log_decrease_verbosity

		    verb_act=$(log_get_verbosity)
		    if (( verb_act != (verb_cur - 1) )); then
			    return 1
		    fi
	    done

	    return 0
    }

    When call _test_log_decrease_verbosity_valid
    The status should equal 0
  End

  It "does not decrease the verbosity below the lowest level"
    _test_log_decrease_verbosity_invalid() {
	    local verb_min
	    local verb_act

	    verb_min="$__log_error"

	    log_set_verbosity "$verb_min"
	    verb_act=$(log_get_verbosity)

	    if (( verb_act != verb_min )); then
		    return 1
	    fi

	    log_decrease_verbosity
	    verb_act=$(log_get_verbosity)

	    if (( verb_act != verb_min )); then
		    return 1
	    fi

	    return 0
    }

    When call _test_log_decrease_verbosity_invalid
    The status should equal 0
  End
End

Describe "log_stacktrace()"
  It "prefixes a stacktrace with \"Stacktrace:\""
    When call log_stacktrace
    The status should equal 0
    The stdout should start with "Stacktrace:"
  End

  It "increases the indentation by 2 spaces per line"
    _test_log_stacktrace_indentation() {
	    local line
	    local lineno

	    lineno=0

	    while read -r line; do
		    local spaces_needed
		    local spaces_found

		    spaces_needed=$(( lineno * 2 ))
		    spaces_found=0

		    while [[ "${str:$i:1}" == " " ]]; do
			    ((spaces_found++))
		    done

		    if (( spaces_needed != spaces_found )); then
			    return 1
		    fi

		    ((needed_spaces++))
	    done < <(log_stacktrace)

	    return 0
    }

    When call _test_log_stacktrace_indentation
    The status should equal 0
  End
End

Describe "log_highlight()"
  It "prefixes the output with ===== BEGIN \$tag ====="
    When call log_highlight "test" "foo" "bar" "baz"
    The stdout should start with "===== BEGIN test ====="
  End

  It "suffixes the output with ===== END \$tag ====="
    When call log_highlight "test" "foo" "bar" "baz"
    The stdout should end with "===== END test ====="
  End

  It "prints lines passed in positional parameters"
    When call log_highlight "test" "line"
    The stdout should include "line"
  End

  It "prints lines passed through stdin"
    _test_log_highlight_stdin() {
	    local needle
	    local line

	    needle="$RANDOM.line.$RANDOM"

	    while read -r line; do
		    if [[ "$line" == "$needle" ]]; then
			    return 0
		    fi
	    done < <(log_highlight "test" <<< "$needle")

	    return 1
    }

    When call _test_log_highlight_stdin
    The status should equal 0
  End
End


Describe "log_debug()"
  BeforeAll 'log_set_verbosity $__log_debug'
  AfterAll 'cleanup'

  It "does not print to stdout"
    When call log_debug "test"
    The status should equal 0
    The stdout should equal ""
    The stderr should match pattern "*"
  End

  It "prints log messages to stderr"
    When call log_debug "test"
    The status should equal 0
    The stdout should equal ""
    The stderr should match pattern "* test"
  End

  It "prints messages when the verbosity is $__log_debug"
    _test_log_debug_verbosity_equal() {
	    log_set_verbosity "$__log_debug"
	    log_debug "test"
    }

    When call _test_log_debug_verbosity_equal
    The stderr should match pattern "* test"
  End

  It "prints messages when the verbosity is above $__log_debug"
    _test_log_debug_verbosity_above() {
	    log_set_verbosity "$(( __log_debug + 1 ))"
	    log_debug "test"
    }

    When call _test_log_debug_verbosity_above
    The stderr should match pattern "* test"
  End

  It "does not print a message when the verbosity is below $__log_debug"
    _test_log_debug_verbosity_below() {
	    log_set_verbosity "$(( __log_debug - 1 ))"
	    log_debug "test"
    }

    When call _test_log_debug_verbosity_below
    The stderr should equal ""
  End

  It "prints the same message to stderr and the logfile"
    _test_log_debug_same_output() {
	    local message
	    local stderr
	    local logfile

	    message=$(echo "Somewhat $RANDOM message"
		      echo "For testing purposes $RANDOM")

	    rm -f "$__log_file"
	    output=$(log_debug "$message" 2>&1)
	    logfile=$(< "$__log_file")

	    if [[ "$output" != "$logfile" ]]; then
		    return 1
	    fi

	    return 0
    }

    When call _test_log_debug_same_output
    The status should equal 0
  End

  It "prints lines passed in positional parameters"
    _test_log_debug_lines_in_args() {
	    local lines
	    local num_lines

	    lines=("test$RANDOM"
		   "test$RANDOM")
	    num_lines=$(log_debug "${lines[@]}" 2>&1 | wc -l)

	    if (( num_lines != ${#lines[@]} )); then
		    return 1
	    fi

	    return 0
    }

    When call _test_log_debug_lines_in_args
    The status should equal 0
  End

  It "prints lines passed via stdin"
    _test_log_debug_lines_via_stdin() {
	    local lines
	    local num_lines

	    lines=("test$RANDOM"
		   "test$RANDOM")
	    num_lines=$(array_to_lines "${lines[@]}" | log_debug 2>&1 | wc -l)

	    if (( num_lines != ${#lines[@]} )); then
		    return 1
	    fi

	    return 0
    }

    When call _test_log_debug_lines_via_stdin
    The status should equal 0
  End
End


Describe "log_info()"
  BeforeAll 'log_set_verbosity $__log_info'
  AfterAll 'cleanup'

  It "does not print to stdout"
    When call log_info "test"
    The status should equal 0
    The stdout should equal ""
    The stderr should match pattern "*"
  End

  It "prints log messages to stderr"
    When call log_info "test"
    The status should equal 0
    The stdout should equal ""
    The stderr should match pattern "* test"
  End

  It "prints messages when the verbosity is $__log_info"
    _test_log_info_verbosity_equal() {
	    log_set_verbosity "$__log_info"
	    log_info "test"
    }

    When call _test_log_info_verbosity_equal
    The stderr should match pattern "* test"
  End

  It "prints messages when the verbosity is above $__log_info"
    _test_log_info_verbosity_above() {
	    log_set_verbosity "$(( __log_info + 1 ))"
	    log_info "test"
    }

    When call _test_log_info_verbosity_above
    The stderr should match pattern "* test"
  End

  It "does not print a message when the verbosity is below $__log_info"
    _test_log_info_verbosity_below() {
	    log_set_verbosity "$(( __log_info - 1 ))"
	    log_info "test"
    }

    When call _test_log_info_verbosity_below
    The stderr should equal ""
  End

  It "prints the same message to stderr and the logfile"
    _test_log_info_same_output() {
	    local message
	    local stderr
	    local logfile

	    message=$(echo "Somewhat $RANDOM message"
		      echo "For testing purposes $RANDOM")

	    rm -f "$__log_file"
	    output=$(log_info "$message" 2>&1)
	    logfile=$(< "$__log_file")

	    if [[ "$output" != "$logfile" ]]; then
		    return 1
	    fi

	    return 0
    }

    When call _test_log_info_same_output
    The status should equal 0
  End

  It "prints lines passed in positional parameters"
    _test_log_info_lines_in_args() {
	    local lines
	    local num_lines

	    lines=("test$RANDOM"
		   "test$RANDOM")
	    num_lines=$(log_info "${lines[@]}" 2>&1 | wc -l)

	    if (( num_lines != ${#lines[@]} )); then
		    return 1
	    fi

	    return 0
    }

    When call _test_log_info_lines_in_args
    The status should equal 0
  End

  It "prints lines passed via stdin"
    _test_log_info_lines_via_stdin() {
	    local lines
	    local num_lines

	    lines=("test$RANDOM"
		   "test$RANDOM")
	    num_lines=$(array_to_lines "${lines[@]}" | log_info 2>&1 | wc -l)

	    if (( num_lines != ${#lines[@]} )); then
		    return 1
	    fi

	    return 0
    }

    When call _test_log_info_lines_via_stdin
    The status should equal 0
  End
End


Describe "log_warn()"
  BeforeAll 'log_set_verbosity $__log_warning'
  AfterAll 'cleanup'

  It "does not print to stdout"
    When call log_warn "test"
    The status should equal 0
    The stdout should equal ""
    The stderr should match pattern "*"
  End

  It "prints log messages to stderr"
    When call log_warn "test"
    The status should equal 0
    The stdout should equal ""
    The stderr should match pattern "* test"
  End

  It "prints messages when the verbosity is $__log_warning"
    _test_log_warn_verbosity_equal() {
	    log_set_verbosity "$__log_warning"
	    log_warn "test"
    }

    When call _test_log_warn_verbosity_equal
    The stderr should match pattern "* test"
  End

  It "prints messages when the verbosity is above $__log_warning"
    _test_log_warn_verbosity_above() {
	    log_set_verbosity "$(( __log_warning + 1 ))"
	    log_warn "test"
    }

    When call _test_log_warn_verbosity_above
    The stderr should match pattern "* test"
  End

  It "does not print a message when the verbosity is below $__log_warning"
    _test_log_warn_verbosity_below() {
	    log_set_verbosity "$(( __log_warning - 1 ))"
	    log_warn "test"
    }

    When call _test_log_warn_verbosity_below
    The stderr should equal ""
  End

  It "prints the same message to stderr and the logfile"
    _test_log_warn_same_output() {
	    local message
	    local stderr
	    local logfile

	    message=$(echo "Somewhat $RANDOM message"
		      echo "For testing purposes $RANDOM")

	    rm -f "$__log_file"
	    output=$(log_warn "$message" 2>&1)
	    logfile=$(< "$__log_file")

	    if [[ "$output" != "$logfile" ]]; then
		    return 1
	    fi

	    return 0
    }

    When call _test_log_warn_same_output
    The status should equal 0
  End

  It "prints lines passed in positional parameters"
    _test_log_warn_lines_in_args() {
	    local lines
	    local num_lines

	    lines=("test$RANDOM"
		   "test$RANDOM")
	    num_lines=$(log_warn "${lines[@]}" 2>&1 | wc -l)

	    if (( num_lines != ${#lines[@]} )); then
		    return 1
	    fi

	    return 0
    }

    When call _test_log_warn_lines_in_args
    The status should equal 0
  End

  It "prints lines passed via stdin"
    _test_log_warn_lines_via_stdin() {
	    local lines
	    local num_lines

	    lines=("test$RANDOM"
		   "test$RANDOM")
	    num_lines=$(array_to_lines "${lines[@]}" | log_warn 2>&1 | wc -l)

	    if (( num_lines != ${#lines[@]} )); then
		    return 1
	    fi

	    return 0
    }

    When call _test_log_warn_lines_via_stdin
    The status should equal 0
  End
End

Describe "log_error()"
  BeforeAll 'log_set_verbosity $__log_error'
  AfterAll 'cleanup'

  It "does not print to stdout"
    When call log_error "test"
    The status should equal 0
    The stdout should equal ""
    The stderr should match pattern "*"
  End

  It "prints log messages to stderr"
    When call log_error "test"
    The status should equal 0
    The stdout should equal ""
    The stderr should match pattern "* test"
  End

  It "prints messages when the verbosity is $__log_error"
    _test_log_error_verbosity_equal() {
	    log_set_verbosity "$__log_error"
	    log_error "test"
    }

    When call _test_log_error_verbosity_equal
    The stderr should match pattern "* test"
  End

  It "prints messages when the verbosity is above $__log_error"
    _test_log_error_verbosity_above() {
	    log_set_verbosity "$(( __log_error + 1 ))"
	    log_error "test"
    }

    When call _test_log_error_verbosity_above
    The stderr should match pattern "* test"
  End

  It "prints the same message to stderr and the logfile"
    _test_log_error_same_output() {
	    local message
	    local stderr
	    local logfile

	    message=$(echo "Somewhat $RANDOM message"
		      echo "For testing purposes $RANDOM")

	    rm -f "$__log_file"
	    output=$(log_error "$message" 2>&1)
	    logfile=$(< "$__log_file")

	    if [[ "$output" != "$logfile" ]]; then
		    return 1
	    fi

	    return 0
    }

    When call _test_log_error_same_output
    The status should equal 0
  End

  It "prints lines passed in positional parameters"
    _test_log_error_lines_in_args() {
	    local lines
	    local num_lines

	    lines=("test$RANDOM"
		   "test$RANDOM")
	    num_lines=$(log_error "${lines[@]}" 2>&1 | wc -l)

	    if (( num_lines != ${#lines[@]} )); then
		    return 1
	    fi

	    return 0
    }

    When call _test_log_error_lines_in_args
    The status should equal 0
  End

  It "prints lines passed via stdin"
    _test_log_error_lines_via_stdin() {
	    local lines
	    local num_lines

	    lines=("test$RANDOM"
		   "test$RANDOM")
	    num_lines=$(array_to_lines "${lines[@]}" | log_error 2>&1 | wc -l)

	    if (( num_lines != ${#lines[@]} )); then
		    return 1
	    fi

	    return 0
    }

    When call _test_log_error_lines_via_stdin
    The status should equal 0
  End
End
