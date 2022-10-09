# The opt module

The opt module implements a versatile command line parser. The parser can be used for
options without values (flags) and options with one or multiple values. The parser can
be instructed to validate values using regular expressions, and call user-defined
functions when an option was parsed and validated.

### Dependencies

 * [array](array.md)
 * [log](log.md)

### Function index

| Function                            | Purpose                                 |
|-------------------------------------|-----------------------------------------|
| [opt_add_arg()](#opt_add_arg)       | Declare an option                       |
| [opt_get()](#opt_get)               | Get the value of an option              |
| [opt_get_argv()](#opt_get_argv)     | Get the executing script's command line |
| [opt_parse()](#opt_parse)           | Parse a command line                    |
| [opt_print_help()](#opt_print_help) | Print a help text                       |


## opt_add_arg()

Declare an option

### Synopsis

    opt_add_arg "$short" "$long" "$flags" "$default" "$desc" "$regex" "$action"

### Description

The `opt_add_arg()` function declares a new option with the short and long names `$short` and `$long`. The
behavior of the option is determined by the flags passed in `$flags`, which is a string containing one or more
of the following attributes.

| Attribute | Meaning                              |
|-----------|--------------------------------------|
| `a`       | The option is an array (implies `v`) |
| `r`       | The option is required               |
| `v`       | The option has a value               |

If the `a` flag was set, the `$default` parameter must contain the name of the array that the parsed values
will be appended to. The parser will only append to the array; values that it contains before the parser is
invoked will not be overwritten.
If the `r` flag was set, the option must be passed on the command line, otherwise the parser will return an
error.
If the `v` or `a` flag was set, the option must be followed by a value. The value is validated against the
regular expression passed in `$regex`.
The `$action` parameter may be used to determine a callback that is executed when an option was successfully
parsed, i.e. it has no value or the value matches `$regex`. The callback `$action` will be passed the long
name of the option in the first, and the value of the option in the second argument.

The value passed in `$desc` will be displayed as the description in the script's help text.


### Return value

| Return value | Meaning                              |
|--------------|--------------------------------------|
| 0            | The option was successfully declared |
| 1            | The option could not be declared     |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

In case of an error, a message is written to standard error.


## opt_get()

Get the value of an option

### Synopsis

    opt_get "$long"

### Description

The `opt_get()` function returns the value of the option with the long name `$long`. If the option does not
have a value (i.e. it was declared without the `a` or `v` flags), the number of times it was encountered on
the command line is returned.

### Return value

| Return value | Meaning                                                |
|--------------|--------------------------------------------------------|
| 0            | The value of the option was written to standard output |
| 1            | The option was not set                                 |
| 2            | The option name is invalid                             |

### Standard input

This function does not read from standard input.

### Standard output

Upon success, the value of the option is written to standard output. If the option's value was not passed on
the command line, its default value will be written. Otherwise, no data will be written to standard output.

### Standard error

This function does not write to standard error.


## opt_get_argv()

Get the executing script's command line

### Synopsis

    opt_get_argv

### Description

The `opt_get_argv()` function returns options that were passed to the executing script, one argument per line.

### Return value

| Return value | Meaning                          |
|--------------|----------------------------------|
| 0            | Success                          |
| 1            | The options could not be written |

### Standard input

This function does not read from standard input.

### Standard output

Upon success, the options that were passed to the executing script are written to standard output, each
argument on a separate line. Otherwise no data will be written to standard output.

### Standard error

This function does not write to standard error.


## opt_parse()

Parse a command line

### Synopsis

    opt_parse "${opts[@]}"

### Description

The `opt_parse()` function parses the command line passed in `$opts` according to the option definitions that
were declared using `opt_add_arg()`. Options may appear on the command line either with their short name,
prefixed by one dash, or with their long name, prefixed by two dashes. The parser operates as follows.
 * If an option does not have a value, the parser will count the number of times the option was found on the command line.
 * If an option has a value, but the value is missing or could not be validated against the option's regular expression, the parser will return an error.
 * If the option is an array, and its value could be validated, the value will be added to the array that stores the option's values.
 * If the option does not have a value, or it has a value that could be validated against the option's regular expression, the parser will call the option's callback. If the option's callback returns a non-zero value, the parser will stop parsing and return the value that the callback returned.
 * If `-h` or `--help` were encountered in `$opts`, the help text will be written to standard output.
 * If `-v` or `--verbose` were encountered in `$opts`, the verbosity of the script is increased one level.
 * If `-q` or `--quiet` were encountered in `$opts`, the verbosity of the script is decreased one level.

### Return value

| Return value | Meaning                                  |
|--------------|------------------------------------------|
| 0            | The command line was successfully parsed |
| 1            | The command line could not be parsed     |
| *            | A callback failed with this return value |

### Standard input

This function does not read from standard input.

### Standard output

If `-h` or `--help` were found in `$opts`, the help text will be written to standard output.

### Standard error

In case of an error, a message will be written to standard error.


## opt_print_help()

Print a help text

### Synopsis

    opt_print_help

### Description

The `opt_print_help()` function writes a help text to standard output. The content of the help text depends
on the options that were declared using `opt_add_arg()`.

### Return value

| Return value | Meaning         |
|--------------|-----------------|
| 2            | Always returned |

### Standard input

This function does not read from standard input.

### Standard output

The help text of the script is written to standard output.

### Standard error

This function does not write to standard error.
