# The is module

The is module implements functions for checking the contents of strings.

### Dependencies

The is module does not depend on other modules.

| Function                  | Purpose                                                 |
|---------------------------|---------------------------------------------------------|
| [is_alnum()](#is_alnum)   | Check if a string contains only alphanumeric characters |
| [is_alpha()](#is_alpha)   | Check if a string contains only alphabet characters     |
| [is_base64()](#is_base64) | Check if a string contains a base64-encoded value       |
| [is_digits()](#is_digits) | Check if a string contains only digits                  |
| [is_hex()](#is_hex)       | Check if a string contains a hexadecimal value          |
| [is_int()](#is_int)       | Check if a string contains an integer value             |
| [is_lower()](#is_lower)   | Check if a string contains only lower-case letters      |
| [is_upper()](#is_upper)   | Check if a string contains only upper-case letters      |


## is_alnum()

Check if a string contains only alphanumeric characters

### Synopsis

    is_alnum "$str"

### Description

The `is_alnum()` function tests whether all characters in the string `$str` are alphanumeric.

### Return value

| Return value | Meaning                       |
|--------------|-------------------------------|
| 0            | The input is alphanumeric     |
| 1            | The input is not alphanumeric |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function does not write to standard error.


## is_alpha()

Check if a string contains only alphabet characters

### Synopsis

    is_alpha "$str"

### Description

The `is_alpha()` function tests whether all characters in the string `$str` are alphabet characters.

### Return value

| Return value | Meaning                     |
|--------------|-----------------------------|
| 0            | The input is alphabetic     |
| 1            | The input is not alphabetic |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function does not write to standard error.


## is_base64()

Check if a string contains a base64-encoded value

### Synopsis

    is_base64 "$str"

### Description

The `is_base64()` function tests whether the string `$str` contains a base64-encoded value. Aside of upper and
lower-case alphabet letters and digits, `/` and `+` are considered part of the base64-alphabet. This function
does not check if the length of the padding is correct.

### Return value

| Return value | Meaning                 |
|--------------|-------------------------|
| 0            | The input is base64     |
| 1            | The input is not base64 |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function does not write to standard error.


## is_digits()

Check if a string contains only digits

### Synopsis

    is_digits "$str"

### Description

The `is_digits()` function tests whether all characters in the string `$str` are digits.

### Return value

| Return value | Meaning                                 |
|--------------|-----------------------------------------|
| 0            | The input contains only digits          |
| 1            | The input contains non-digit characters |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function does not write to standard error.


## is_hex()

Check if a string contains a hexadecimal value

### Synopsis

    is_hex "$str"

### Description

The `is_hex()` function tests whether the string `$str` contains a hexadecimal value. The value must neither
be prefixed with `0x` or `0X`, nor suffixed with `h` or `H`.

### Return value

| Return value | Meaning                      |
|--------------|------------------------------|
| 0            | The input is hexadecimal     |
| 1            | The input is not hexadecimal |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function does not write to standard error.


## is_int()

Check if a string contains an integer value

### Synopsis

    is_int "$str"

### Description

The `is_int()` function tests whether the string `$str` contains an integer value. This function is similar to
`is_digits()`, except that it allows the value to be prefixed with a sign (either `+` or `-`).

### Return value

| Return value | Meaning                     |
|--------------|-----------------------------|
| 0            | The input is an integer     |
| 1            | The input is not an integer |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function does not write to standard error.


## is_lower()

Check if a string contains only lower-case letters

### Synopsis

    is_lower "$str"

### Description

The `is_lower()` function tests whether all characters in the string `$str` are lower-case alphabet letters.

### Return value

| Return value | Meaning                     |
|--------------|-----------------------------|
| 0            | The input is lower-case     |
| 1            | The input is not lower-case |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function does not write to standard error.


## is_upper()

Check if a string contains only upper-case letters

### Synopsis

    is_upper "$str"

### Description

The `is_upper()` function tests whether all characters in the string `$str` are upper-case alphabet letters.

### Return value

| Return value | Meaning                     |
|--------------|-----------------------------|
| 0            | The input is upper-case     |
| 1            | The input is not upper-case |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function does not write to standard error.
