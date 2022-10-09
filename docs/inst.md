# The inst module

The inst module implements functions for writing daemons.

### Dependencies

 * [log](log.md)
 * [opt](opt.md)
 * [sem](sem.md)

### Function index

| Function                                                  | Purpose                                       |
|-----------------------------------------------------------|-----------------------------------------------|
| [inst_count()](#inst_count)                               | Count the running instances of a script       |
| [inst_get_status()](#inst_get_status)                     | Get the status of an instance                 |
| [inst_get_status_message()](#inst_get_status_message)     | Get the status message of an instance         |
| [inst_get_status_timestamp()](#inst_get_status_timestamp) | Get the timestamp of an instance's status     |
| [inst_list()](#inst_list)                                 | List running instances of a script            |
| [inst_running()](#inst_running)                           | Return the state of the current instance      |
| [inst_set_status()](#inst_set_status)                     | Set the status of the current instance        |
| [inst_singleton()](#inst_singleton)                       | Start a unique instance of the current script |
| [inst_start()](#inst_start)                               | Start an instance of the current script       |
| [inst_stop()](#inst_stop)                                 | Stop an instance of a script                  |

## inst_count()

Count the running instances of a script

### Synopsis

    inst_count "$instname"

### Description

The `inst_count()` function counts the running instances of the script determined by `$instname` and writes
the count to standard output.

### Return value

| Return value | Meaning                                          |
|--------------|--------------------------------------------------|
| 0            | The number of instances was successfully written |
| 1            | The number of instances could not be determined  |

### Standard input

This function does not read from standard input.

### Standard output

Upon success, an integer value representing the number of running instances is written to standard output.
Otherwise, no data is written to standard output.

### Standard error

This function does not write to standard error.


## inst_get_status()

Get the status of an instance

### Synopsis

    inst_get_status "$pid" "$instname"

### Description

The `inst_get_status()` function retrieves the status of the instance with pid `$pid` of the script
`$instname` and writes it to standard output. If `$instname` is omitted, the status for the instance
of the current script will be retrieved.

### Return value

| Return value | Meaning                                                |
|--------------|--------------------------------------------------------|
| 0            | The status was successfully written to standard output |
| 1            | The status for the instance could not be retrieved     |

### Standard input

This function does not read from standard input.

### Standard output

Upon success, the instance status is written to standard output. Otherwise, no data is written to standard
output.

### Standard error

In case of an error, a message will be written to standard error.


## inst_get_status_message()

Get the status message of an instance

### Synopsis

    inst_get_status_message "$pid" "$instname"

### Description

The `inst_get_status_message()` function retrieves the status message of the instance with pid `$pid` of the
script `$instname` and writes it to standard output. If `$instname` was omitted, the status for an instance
of the executing script will be retrieved.

### Return value

| Return value | Meaning                                                |
|--------------|--------------------------------------------------------|
| 0            | The status was successfully written to standard output |
| 1            | The status for the instance could not be retrieved     |

### Standard input

This function does not read from standard input.

### Standard output

Upon success, the status message of the instance is written to standard output. Otherwise, no data is written
to standard output.

### Standard error

In case of an error, a message will be written to standard error.


## inst_get_status_timestamp()

Get the timestamp of an instance's status

### Synopsis

    inst_get_status_timestamp "$pid" "$instname"

### Description

The `inst_get_status_timestamp()` retrieves the timestamp of the status of the instance with pid `$pid` of the
script `$instname` and writes it to standard output. If `$instname` was omitted, the status for an instance of
the executing script will be retrieved.

### Return value

| Return value | Meaning                                                   |
|--------------|-----------------------------------------------------------|
| 0            | The timestamp was successfully written to standard output |
| 1            | The timestamp could not be retrieved                      |

### Standard input

This function does not read from standard input.

### Standard output

Upon success, an integer value representing the timestamp in UNIX-time is written to standard output.
Otherwise, no data is written to standard output.

### Standard error

In case of an error, a message is written to standard output.


## inst_list()

List running instances of a script

### Synopsis

    inst_list "$instname"

### Description

The `inst_list()` function retrieves a list of running instances of the script `$instname` and writes it to
standard output. If `$instname` was omitted, instances of the executing script will be returned.

### Return value

| Return value | Meaning                   |
|--------------|---------------------------|
| 0            | Success (always returned) |

### Standard input

This function does not read from standard input.

### Standard output

If running instances of the script were found, details about each of them will be written to standard output,
one per line. The following is the format of each line.

    OWNER STATE [STATUS_TIMESTAMP:STATUS_TEXT] INSTANCE_NAME ARGV0 ...

### Standard error

This function does not write to standard error.


## inst_running()

Return the state of the current instance

### Synopsis

    inst_running

### Description

The `inst_running()` function determines the state of the executing script. Instances should use this function
to determine whether they should stop execution. If this function returns a non-zero value, the calling
instance has been requested to stop either by `inst_stop()` or a signal.

### Return value

| Return value | Meaning                                 |
|--------------|-----------------------------------------|
| 0            | The instance is running                 |
| 1            | The instance has been requested to stop |


### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

In case of an error, this function writes a message to standard error.


## inst_set_status()

Set the status of the current instance

### Synopsis

    inst_set_status "$status"

### Description

The `inst_set_status()` function sets the status of the executing instance to `$status`. The
`inst_get_status_message()` and `inst_get_status_timestamp()` functions may be used to retrieve the status
and the timestamp of the status, respectively.

### Return value

| Return value | Meaning                         |
|--------------|---------------------------------|
| 0            | The status was successfully set |
| 1            | The status could not be set     |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

In case of an error, this function writes a message to standard error.



## inst_singleton()

Start a unique instance of the current script

### Synopsis

    inst_singleton "${args[@]}"

### Description

The `inst_singleton()` function starts a unique instance of the executing script using the array passed in
`$args` as the main function of the new instance. If another instance of the executing script is already
running, no instance will be started.

### Return value

| Return value | Meaning                                                     |
|--------------|-------------------------------------------------------------|
| 0            | The instance was started                                    |
| 1            | Another instance of the executing script is already running |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

In case of an error, this function writes a message to standard error.


## inst_start()

Start an instance of the current script

### Synopsis

    inst_start "${args[@]}"

### Description

The `inst_start()` function starts an instance of the executing script using the array passed in
`$args` as the main function of the new instance.

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


## inst_stop()

Stop an instance of a script

### Synopsis

    inst_stop "$pid" "$instname"

### Description

The `inst_stop()` function requests the instance with pid `$pid` of the script `$instname` to stop. If
`$instname` was omitted, an instance of the executing script will be requested to stop. Note that the
instance that was requested to stop is highly unlikely to be stopped by the time this function returns.

### Return value

| Return value | Meaning                                         |
|--------------|-------------------------------------------------|
| 0            | The instance was successfully requested to stop |
| 1            | The instance could not be requested to stop     |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

A message will be written to standard error if the instance does not exist.
