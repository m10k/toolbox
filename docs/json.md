# The json module

The json module implements functions for creating and parsing JSON data.

### Dependencies

 * [array](array.md)
 * [is](is.md)
 * [log](log.md)

### Function index

| Function                                      | Purpose                                          |
|-----------------------------------------------|--------------------------------------------------|
| [json_array()](#json_array)                   | Create a JSON array                              |
| [json_array_head()](#json_array_head)         | Get the first element from a JSON array          |
| [json_array_tail()](#json_array_tail)         | Remove the first element from a JSON array       |
| [json_array_to_lines()](#json_array_to_lines) | Get the elements from a JSON array, one per line |
| [json_object()](#json_object)                 | Create a JSON object                             |
| [json_object_get()](#json_object_get)         | Extract a field from a JSON object               |

## json_array()

Create a JSON array

### Synopsis

    json_array "${args[@]}"

### Description

The `json_array()` function creates a JSON array that is equivalent to the Bash array `$args` and writes
it to standard output. This function attempts to parse values in `$args`, meaning that inputs that look
like integer, floating-point, or other values will be converted to the corresponding types. If this is
not desired, the caller must prefix values with type hints.

| Prefix | Type        |
|--------|-------------|
| `s:`   | String      |
| `i:`   | Integer     |
| `b:`   | Bool        |
| `f:`   | Float       |
| `o:`   | JSON Object |
| `a:`   | JSON Array  |

### Return value

| Return value | Meaning                            |
|--------------|------------------------------------|
| 0            | The array was written successfully |
| 1            | The array could not be created     |

### Standard input

This function does not read from standard input.

### Standard output

On success, the JSON array is written to standard output. Otherwise, no data will be written to standard
output.

### Standard error

This function does not write to standard error.


## json_array_head()

Get the first element from a JSON array

### Synopsis

    json_array_head "$array"

### Description

The `json_array_head()` function extracts the first element from the JSON array `$array` and writes it to
standard output.

### Return value

| Return value | Meaning                                                 |
|--------------|---------------------------------------------------------|
| 0            | The element was written successfully to standard output |
| 1            | The element could not be retrieved from the array       |

### Standard input

This function does not read from standard input.

### Standard output

Upon success, the first element of the array is written to standard output. Otherwise no data is written
to standard output.

### Standard error

In case of an error, messages from an internal call to `jq` may be written to standard error.


## json_array_tail()

Remove the first element from a JSON array

### Synopsis

    json_array_tail "$array"

### Description

The `json_array_tail()` function creates a new JSON array with all but the first element of `$array`, and writes
the new JSON array to standard output. The order of elements in the array is preserved.

### Return value

| Return value | Meaning                                                   |
|--------------|-----------------------------------------------------------|
| 0            | The new array was successfully written to standard output |
| 1            | The new array could not be created                        |

### Standard input

This function does not read from standard input.

### Standard output

Upon success, the new JSON array is written to standard output. Otherwise no data is written to standard output.

### Standard error

In case of an error, messages from an internal call to `jq` may be written to standard error.


## json_array_to_lines()

Get the elements from a JSON array, one per line

### Synopsis

    json_array_to_lines "$array"

### Description

The `json_array_to_lines()` function retrieves the elements from the JSON array passed in `$array` and writes them
to standard output, one element per line.

### Return value

| Return value | Meaning                           |
|--------------|-----------------------------------|
| 0            | The array was output successfully |
| 1            | The array could not be parsed     |

### Standard input

This function does not read from standard input.

### Standard output

Upon success, the elements from the array are written to standard output, one element per line. Otherwise, no data
is written to standard output.

### Standard error

In case of an error, messages from an internal call to `jq` may be written to standard error.


## json_object()

Create a JSON object

### Synopsis

    json_object "$name0" "$value0" ...

### Description

The `json_object()` function creates a new JSON object using pairs of arguments as the names and values of fields in
the object. If either the name or the value in a pair of arguments is the empty string, the pair will be skipped. The
same rules as for the [json_array()](#json_array) function apply to this function. In particular, this means that
values may need to be prefixed with type hints.
An even number of arguments must be passed to this function.

### Return value

| Return value | Meaning                                                    |
|--------------|------------------------------------------------------------|
| 0            | The new object was successfully written to standard output |
| 1            | The object could not be created                            |

### Standard input

This function does not read from standard input.

### Standard output

Upon success, the new JSON object is written to standard output. Otherwise no data is written to standard output.

### Standard error

In case of an error, this function may write a message to standard error.


## json_object_get()

Extract a field from a JSON object

### Synopsis

    json_object_get "$object" "$field"

### Description

The `json_object_get()` function extracts the field `$field` from the JSON object passed in `$object` and writes its
value to standard output.

### Return value

| Return value | Meaning                                       |
|--------------|-----------------------------------------------|
| 0            | The value was written successfully            |
| 1            | The field could not be parsed from the object |

### Standard input

This function does not read from standard input.

### Standard output

Upon success, the the value of the field is written to standard output. Otherwise no data is written to standard output.

### Standard error

In case of an error, messages from an internal call to `jq` may be written to standard error.
