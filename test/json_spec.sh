#!/bin/bash

# json_spec.sh - Test cases for the toolbox json module
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

if ! . toolbox.sh; then
	exit 1
fi

if ! include "json"; then
	exit 1
fi

Describe "json_object()"
  It "creates an empty JSON object"
    When call json_object
    The stdout should equal "{}"
    The status should equal 0
  End

  It "fails if there are more keys than values"
    When call json_object "data"
    The stderr should match pattern "*Invalid number of arguments"
    The status should equal 1
  End

  It "inserts a string into a JSON object"
    When call json_object "data" "hello world"
    The stdout should equal '{"data": "hello world"}'
    The status should equal 0
  End

  It "inserts an integer into a JSON object"
    When call json_object "data" 123
    The stdout should equal '{"data": 123}'
    The status should equal 0
  End

  It "inserts a boolean (true) into a JSON object"
    When call json_object "data" "true"
    The stdout should equal '{"data": true}'
    The status should equal 0
  End

  It "inserts a boolean (false) into a JSON object"
    When call json_object "data" "false"
    The stdout should equal '{"data": false}'
    The status should equal 0
  End

  It "inserts a float into a JSON object"
    When call json_object "data" "3.14"
    The stdout should equal '{"data": 3.14}'
    The status should equal 0
  End

  It "inserts an object into a JSON object"
    When call json_object "data" "{}"
    The stdout should equal '{"data": {}}'
    The status should equal 0
  End

  It "inserts an array into a JSON object"
    When call json_object "data" "[]"
    The stdout should equal '{"data": []}'
    The status should equal 0
  End
End

Describe "json_object_get()"
  It "retrieves a string from an object"
    When call json_object_get '{"data": "hello world"}' "data"
    The stdout should equal "hello world"
    The status should equal 0
  End

  It "retrieves an integer from an object"
    When call json_object_get '{"data": 123}' "data"
    The stdout should equal "123"
    The status should equal 0
  End

  It "retrieves a boolean (true) from an object"
    When call json_object_get '{"data": true}' "data"
    The stdout should equal "true"
    The status should equal 0
  End

  It "retrieves a boolean (false) from an object"
    When call json_object_get '{"data": false}' "data"
    The stdout should equal "false"
    The status should equal 0
  End

  It "retrieves a float from an object"
    When call json_object_get '{"data": 1.23}' "data"
    The stdout should equal "1.23"
    The status should equal 0
  End

  It "retrieves an array from an object"
    When call json_object_get '{"data": []}' "data"
    The stdout should equal "[]"
    The status should equal 0
  End

  It "retrieves an object from an object"
    When call json_object_get '{"data": {}}' "data"
    The stdout should equal "{}"
    The status should equal 0
  End
End

Describe "json_array()"
  It "creates an empty array"
    When call json_array
    The stdout should equal "[]"
    The status should equal 0
  End

  It "creates a string array"
    When call json_array "hello" "world"
    The stdout should equal '["hello", "world"]'
    The status should equal 0
  End

  It "creates an integer array"
    When call json_array 1 2 3
    The stdout should equal '[1, 2, 3]'
    The status should equal 0
  End

  It "creates a boolean array"
    When call json_array "true" "false"
    The stdout should equal '[true, false]'
    The status should equal 0
  End

  It "creates a float array"
    When call json_array "1.23" "2.34" "3.45"
    The stdout should equal "[1.23, 2.34, 3.45]"
    The status should equal 0
  End

  It "creates an array arrays"
    When call json_array "[]" "[]"
    The stdout should equal "[[], []]"
    The status should equal 0
  End

  It "creates an object array"
    When call json_array "{}" "{}"
    The stdout should equal "[{}, {}]"
    The status should equal 0
  End
End

Describe "json_array_head()"
  It "fails if the array is empty"
    When call json_array_head "[]"
    The status should equal 1
  End

  It "retrieves a string from the head of the array"
    When call json_array_head '["hello", "world"]'
    The stdout should equal "hello"
    The status should equal 0
  End

  It "retrieves an integer from the head of the array"
    When call json_array_head "[1, 2, 3]"
    The stdout should equal "1"
    The status should equal 0
  End

  It "retrieves a boolean (true) from the head of the array"
    When call json_array_head "[true, false]"
    The stdout should equal "true"
    The status should equal 0
  End

  It "retrieves a boolean (false) from the head of the array"
    When call json_array_head "[false, true]"
    The stdout should equal "false"
    The status should equal 0
  End

  It "retrieves a float from the head of the array"
    When call json_array_head "[1.23, 2.34, 3.45]"
    The stdout should equal "1.23"
    The status should equal 0
  End

  It "retrieves an array from the head of the array"
    When call json_array_head "[[], [1]]"
    The stdout should equal "[]"
    The status should equal 0
  End

  It "retrieves an object from the head of the array"
    When call json_array_head '[{}, {"hello": "world"}]'
    The stdout should equal "{}"
    The status should equal 0
  End
End

Describe "json_array_tail()"
  It "returns an empty array if the array is empty"
    When call json_array_tail "[]"
    The stdout should equal "[]"
    The status should equal 0
  End

  It "removes a string from the head of the array"
    When call json_array_tail '["hello", "world", "foobar"]'
    The stdout should equal '["world", "foobar"]'
    The status should equal 0
  End

  It "removes an integer from the head of the array"
    When call json_array_head "[1, 2, 3]"
    The stdout should equal "[2, 3]"
    The status should equal 0
  End

  It "removes a boolean (true) from the head of the array"
    When call json_array_head "[true, false, false]"
    The stdout should equal "[false, false]"
    The status should equal 0
  End

  It "removes a boolean (false) from the head of the array"
    When call json_array_head "[false, true, true]"
    The stdout should equal "[true, true]"
    The status should equal 0
  End

  It "removes a float from the head of the array"
    When call json_array_head "[1.23, 2.34, 3.45]"
    The stdout should equal "[2.34, 3.45]"
    The status should equal 0
  End

  It "removes an array from the head of the array"
    When call json_array_head "[[], [1]]"
    The stdout should equal "[[1]]"
    The status should equal 0
  End

  It "removes an object from the head of the array"
    When call json_array_head '[{}, {"hello": "world"}]'
    The stdout should equal '[{"hello": "world"}]'
    The status should equal 0
  End
End

Describe "json_array_to_lines()"
  It "does not output any lines if the array is empty"
    When call json_array_to_lines "[]"
    The status should equal 0
  End

  It "splits a string array to lines"
    When call json_array_to_lines '["hello", "world"]'
    The first line of stdout should equal "hello"
    The second line of stdout should equal "world"
    The status should equal 0
  End

  It "splits an integer array to lines"
    When call json_array_to_lines "[1, 2, 3]"
    The first line of stdout should equal "1"
    The second line of stdout should equal "2"
    The third line of stdout should equal "3"
    The status should equal 0
  End

  It "splits a boolean array to lines"
    When call json_array_to_lines "[true, false]"
    The first line of stdout should equal "true"
    The second line of stdout should equal "false"
    The status should equal 0
  End

  It "splits a float array to lines"
    When call json_array_to_lines "[1.23, 2.34, 3.45]"
    The first line of stdout should equal "1.23"
    The second line of stdout should equal "2.34"
    The third line of stdout should equal "3.45"
    The status should equal 0
  End

  It "splits an array array to lines"
    When call json_array_to_lines "[[1], [2], [3]]"
    The first line of stdout should equal "[1]"
    The second line of stdout should equal "[2]"
    The third line of stdout should equal "[3]"
    The status should equal 0
  End

  It "splits an object array to lines"
    When call json_array_to_lines '[{"data": 1}, {"data": 2}]'
    The first line of stdout should equal '{"data": 1}'
    The second line of stdout should equal '{"data": 2}'
    The status should equal 0
  End
End
