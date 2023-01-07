#!/bin/bash

. toolbox.sh
include "opt"

Describe "opt_add_arg()"
  It "succeeds when adding a valid option"
    _test_opt_add_arg_valid() (
	    opt_add_arg "o" "opt"
    )

    When call _test_opt_add_arg_valid
    The status should equal 0
  End

  It "fails when re-defining an option"
    _test_opt_add_arg_redefine() (
	    opt_add_arg "h" "help"
    )

    When call _test_opt_add_arg_redefine
    The status should equal 1
    The stderr should not equal ""
  End
End

Describe "opt_add_arg() - Attributes"
  Parameters
  "r"    0 "accepts"
  "v"    0 "accepts"
  "a"    0 "accepts"         "array"
  "rv"   0 "accepts"
  "rva"  0 "accepts"         "array"
  "vr"   0 "accepts"
  "rvrv" 0 "accepts"
  "x"    1 "does not accept"
  "a"    1 "does not accept"
  End

  _test_opt_add_arg_attr() (
	  local attr="$1"
	  local default="$2"

	  declare -a array

	  opt_add_arg "o" "opt" "$attr" "$default" 2>/dev/null
  )

  It "$3 the attribute '$1'"
    When call _test_opt_add_arg_attr "$1" "$4"
    The status should equal "$2"
  End
End

Describe "opt_parse()"
  It "fails if a required parameter is missing"
    _test_opt_parse_parameter_missing() (
	    opt_add_arg "o" "opt" "rv"
	    opt_parse "-o"
    )

    When call _test_opt_parse_parameter_missing
    The status should equal 1
    The stderr should not equal ""
  End

  It "succeeds if a required parameter is present"
    _test_opt_parse_parameter_present() (
	    opt_add_arg "o" "opt" "rv"
	    opt_parse "-o" "value"
    )

    When call _test_opt_parse_parameter_present
    The status should equal 0
  End

  It "fails when a required option is missing"
    _test_opt_parse_required_missing() (
	    opt_add_arg "o" "opt" "rv"
	    opt_parse
    )

    When call _test_opt_parse_required_missing
    The status should equal 1
    The stderr should not equal ""
  End

  It "succeeds when all required options are present"
    _test_opt_parse_required_present() (
	    opt_add_arg "o" "opt" "rv"
	    opt_parse "-o" "value"
    )

    When call _test_opt_parse_required_present
    The status should equal 0
  End

  It "succeeds if all regex validations succeeded"
    _test_opt_parse_regex_pass() (
	    opt_add_arg "o" "opt" "rv" "" "" '^[0-9]+$'
	    opt_parse "-o" "123"
    )

    When call _test_opt_parse_regex_pass
    The status should equal 0
  End

  It "fails if a regex validation failed"
    _test_opt_parse_regex_fail() (
	    opt_add_arg "o" "opt" "rv" "" "" '^[0-9]+$'
	    opt_parse "-o" "abc"
    )

    When call _test_opt_parse_regex_fail
    The status should equal 1
    The stderr should not equal ""
  End

  It "succeeds if all callback succeeded"
    _test_opt_parse_callback_pass() (
	    opt_add_arg "o" "opt" "rv" "" "" "" true
	    opt_parse "-o" "123"
    )

    When call _test_opt_parse_callback_pass
    The status should equal 0
  End

  It "fails if a callback failed"
    _test_opt_parse_callback_fail() (
	    opt_add_arg "o" "opt" "rv" "" "" "" false
	    opt_parse "-o" "123"
    )

    When call _test_opt_parse_callback_fail
    The status should equal 1
  End

  It "passes on the return value from a failing callback"
    _test_opt_parse_callback_retval_helper() {
	    return 123
    }

    _test_opt_parse_callback_retval() (
	    opt_add_arg "o" "opt" "rv" "" "" "" _test_opt_parse_callback_retval_helper
	    opt_parse "-o" "123"
    )

    When call _test_opt_parse_callback_retval
    The status should equal 123
  End

  It "adds elements to an array"
    _test_opt_parse_array_append() (
	    declare -a array
	    declare -a expected

	    expected=(
		    123
	    )

	    opt_add_arg "o" "opt" "a" "array"
	    opt_parse "-o" "123"

	    array_identical array expected
	    return "$?"
    )

    When call _test_opt_parse_array_append
    The status should equal 0
  End

  It "does not overwrite existing elements"
    _test_opt_parse_array_no_overwrite() (
	    declare -a array
	    declare -a expected

	    array=(
		    123
		    234
	    )
	    expected=(
		    123
		    234
		    345
		    456
	    )

	    opt_add_arg "o" "opt" "a" "array"
	    opt_parse "-o" "345" "--opt" "456"

	    array_identical array expected
	    return "$?"
    )

    When call _test_opt_parse_array_no_overwrite
    The status should equal 0
  End
End

Describe "opt_get()"
  It "returns 0 if the requested option has a value"
    _test_opt_get_set() (
	    opt_add_arg "o" "opt" "rv" "default"
	    opt_get "opt"
    )

    When call _test_opt_get_set
    The status should equal 0
    The stdout should equal "default"
  End

  It "returns 1 if an invalid option was passed"
    _test_opt_get_invalid() (
	    opt_get "invalid"
    )

    When call _test_opt_get_invalid
    The status should equal 1
    The stdout should equal ""
  End

  It "returns 2 if the requested option does not have a value"
    _test_opt_get_unset() (
	    opt_add_arg "o" "opt" "rv"
	    opt_get "opt"
    )

    When call _test_opt_get_unset
    The status should equal 2
    The stdout should equal ""
  End

  It "returns the default value if no user-defined value is set"
    _test_opt_get_default() (
	    opt_add_arg "o" "opt" "rv" "default"
	    opt_get "opt"
    )

    When call _test_opt_get_default
    The status should equal 0
    The stdout should equal "default"
  End

  It "returns the user-defined value if it was set"
    _test_opt_get_user() (
	    opt_add_arg "o" "opt" "rv" "default"
	    opt_parse "-o" "uservalue"
	    opt_get "opt"
    )

    When call _test_opt_get_user
    The status should equal 0
    The stdout should equal "uservalue"
  End
End
