# The log module

The log module implements functions for logging and debugging with different log levels. A script that includes
this module has a global log level that defaults to `__log_warning`, meaning that by default only warnings and
errors will be logged. The log level may be adjusted to increase or decrease the amount of log messages.

| Log level       | Meaning                                          |
|-----------------|--------------------------------------------------|
| `__log_debug`   | Log everything                                   |
| `__log_info`    | Log errors, warnings, and informational messages |
| `__log_warning` | Log errors and warnings (default)                |
| `__log_error`   | Log only errors                                  |

### Dependencies

This module does not depend on other modules.

### Function index

| Function                                            | Purpose                                             |
|-----------------------------------------------------|-----------------------------------------------------|
| [log_debug()](#log_debug)                           | Log a debug message                                 |
| [log_decrease_verbosity()](#log_decrease_verbosity) | Decrease the log level                              |
| [log_error()](#log_error)                           | Log an error                                        |
| [log_get_verbosity()](#log_get_verbosity)           | Get the current log level                           |
| [log_highlight()](#log_highlight)                   | Highlight a message and write it to standard output |
| [log_increase_verbosity()](#log_increase_verbosity) | Increase the log level                              |
| [log_info()](#log_info)                             | Log an informational message                        |
| [log_set_verbosity()](#log_set_verbosity)           | Change the current log level                        |
| [log_stacktrace()](#log_stacktrace)                 | Write the call hierarchy to standard output         |
| [log_warn()](#log_warn)                             | Log a warning                                       |


## log_debug()

Log a debug message

### Synopsis

    log_debug "${messages[@]}"
    log_debug <<< "$messages"

### Description

The `log_debug()` function writes debug messages to standard error and the script's log file. If debug messages
were passed as arguments, this function will treat each argument as a debug message. Otherwise, this function
will read debug messages line-by-line from standard input.
Each line of output is prefixed with a timestamp, log tag, as well as the name of the source file and the line
number that the function was called from.

Messages will only be logged if the current log level is `__log_debug` or above.

### Return value

| Return value | Meaning                              |
|--------------|--------------------------------------|
| 0            | The message was written successfully |
| 1            | The message could not be logged      |

### Standard input

If this function is invoked without arguments, messages will be read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function will write one message per line to standard error.


## log_decrease_verbosity()

Decrease the log level

### Synopsis

    log_decrease_verbosity

### Description

The `log_decrease_verbosity()` function lowers the log level of the executing script by one step. If the log level
is at `__log_error`, it will remain unchanged.

### Return value

| Return value | Meaning                   |
|--------------|---------------------------|
| 0            | Success (always returned) |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function does not write to standard error.


## log_error()

Log an error

### Synopsis

    log_error "${messages[@]}"
    log_error <<< "$messages"

### Description

The `log_error()` function writes error messages to standard error and the script's log file. If error messages
were passed as arguments, this function will treat each argument as an error message. Otherwise, this function
will read error messages line-by-line from standard input. Each line of output is prefixed with a timestamp and
log tag.

Error messages are always logged, regardless of the log level.

### Return value

| Return value | Meaning                              |
|--------------|--------------------------------------|
| 0            | The message was written successfully |
| 1            | The message could not be logged      |

### Standard input

If this function is invoked without arguments, messages will be read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function will write one message per line to standard error.


## log_get_verbosity()

Get the current log level

### Synopsis

    log_get_verbosity

### Description

The `log_get_verbosity()` function writes the current log level to standard output.

### Return value

| Return value | Meaning                         |
|--------------|---------------------------------|
| 0            | Success (always returned)       |

### Standard input

This function does not read from standard input.

### Standard output

An integer value indicating the current log level is written to standard output.

### Standard error

This function does not write to standard error.


## log_highlight()

Highlight a message and write it to standard output

### Synopsis

    log_highlight "$tag" "${lines[@]}"
    log_highlight "$tag" <<< "$lines"

### Description

The `log_highlight()` function adds markers with a tag `$tag` around the lines passed in `$lines` and writes them
to standard output, making the lines easier to find in a large amount of log output.
If no lines were passed as arguments, this function reads the data to be highlighted from standard input.

### Return value

| Return value | Meaning                   |
|--------------|---------------------------|
| 0            | Success (always returned) |

### Standard input

If this function is invoked without arguments, data to be highlighted will be read from standard input.

### Standard output

Highlighted data will be written to standard output.

### Standard error

This function may write a message to standard error if standard input is not readable.


## log_increase_verbosity()

Increase the log level

### Synopsis

    log_increase_verbosity

### Description

The `log_increase_verbosity()` function raises the log level of the executing script by one step. If the log level
is at `__log_debug`, it will remain unchanged.

### Return value

| Return value | Meaning                   |
|--------------|---------------------------|
| 0            | Success (always returned) |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function does not write to standard error.


## log_info()

Log an informational message

### Synopsis

    log_info "${messages[@]}"
    log_info <<< "$messages"

### Description

The `log_info()` function writes informational messages to standard error and the script's log file. If messages
were passed as arguments, this function will treat each argument as a message. Otherwise, this function will read
messages line-by-line from standard input. Each line of output is prefixed with a timestamp and log tag.

Messages will only be logged if the log level is `__log_info` or above.

### Return value

| Return value | Meaning                              |
|--------------|--------------------------------------|
| 0            | The message was written successfully |
| 1            | The message could not be logged      |

### Standard input

If this function is invoked without arguments, messages will be read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function will write one message per line to standard error.


## log_set_verbosity()

Change the current log level

### Synopsis

    log_set_verbosity "$verbosity"

### Description

The `log_set_verbosity()` function sets the log level of the executing script to `$verbosity`. If the value passed in
`$verbosity` is not a valid log level, the function will set it to the nearest valid log level.

### Return value

| Return value | Meaning                         |
|--------------|---------------------------------|
| 0            | Success (always returned)       |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output

### Standard error

This function does not write to standard error.


## log_stacktrace()

Write the call hierarchy to standard output

### Synopsis

    log_stacktrace

### Description

The `log_stacktrace()` function writes the call hierarchy of the calling function to standard output, allowing
the user to determine where a particular function was called from. The output written to standard output includes
file names, function names, and the line numbers that functions were called from. Indentation is used to visually
highlight the nesting of function calls.

### Return value

| Return value | Meaning                         |
|--------------|---------------------------------|
| 0            | Success (always returned)       |

### Standard input

This function does not read from standard input.

### Standard output

The stacktrace of the calling function is written to standard output.

### Standard error

This function does not write to standard error.


## log_warn()

Log a warning

### Synopsis

    log_warn "${messages[@]}"
    log_warn <<< "$messages"

### Description

The `log_warn()` function writes warning messages to standard error and the script's log file. If messages were
passed as arguments, this function will treat each argument as a message. Otherwise, this function will read
messages line-by-line from standard input. Each line of output is prefixed with a timestamp and log tag.

Messages will only be logged if the log level is `__log_warning` or above.

### Return value

| Return value | Meaning                              |
|--------------|--------------------------------------|
| 0            | The message was written successfully |
| 1            | The message could not be logged      |

### Standard input

If this function is invoked without arguments, messages will be read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function will write one message per line to standard error.
