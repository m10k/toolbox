# The conf module

The conf module implements primitive configuration handling. This module
allows the caller to load and store configuration values without having
to worry about configuration files and other implementation details.

Settings are stored per-script, meaning that one script will not be able
to load and store settings from another script. Settings are further kept
in *configuration domains*, which are namespaces, allowing a script to
have different configuration profiles.

### Dependencies

 * [log](log.md)

### Function index

| Function                                | Purpose                       |
|-----------------------------------------|-------------------------------|
| [conf_get()](#conf_get)                 | Get the value of a setting    |
| [conf_get_domains()](#conf_get_domains) | List all setting domains      |
| [conf_get_names()](#conf_get_names)     | List all settings in a domain |
| [conf_set()](#conf_set)                 | Set the value of a setting    |
| [conf_unset()](#conf_unset)             | Remove a setting              |


## conf_get()

Get the value of a setting.

### Synopsis

    conf_get "$name" "$domain"

### Description

The `conf_get()` function retrieves the configuration setting identified by
the name `$name` from the domain `$domain`. If `$domain` is omitted, the
value from the domain `default` is retrieved.

### Return value

| Return value | Meaning                                        |
|--------------|------------------------------------------------|
| 0            | The value of the setting was successfully read |
| 1            | The setting was not found                      |

### Standard input

This function does not read from standard input.

### Standard output

On success, the value of the setting is written to standard output. No data
will be written if the setting was not found.

### Standard error

This function does not write to standard error.


## conf_get_domains()

List all setting domains.

### Synopsis

    conf_get_domains

### Description

The `conf_get_domains()` function returns the names of all configuration
domains for the script. If the script does not have any settings, no names
will be returned.
If configuration domains for the script have been defined, their names will
be written to standard output, one domain per line.

### Return value

| Return value | Meaning                   |
|--------------|---------------------------|
| 0            | Success (always returned) |

### Standard input

This function does not read from standard input.

### Standard output

If configuration domains have been defined for the caller, the names of
the domains will be written to standard output, one domain per line.

### Standard error

This function does not write to standard error.


## conf_get_names()

List all settings in a domain.

### Synopsis

    conf_get_names "$domain"

### Description

The `conf_get_names()` function writes the names of all settings that
have been stored in the configuration domain identified by `$domain`
to standard output. If no settings have been defined in the domain, no
data will be written. If `$domain` was omitted, this function will
output the names of the settings in the default domain.

### Return value

| Return value | Meaning                                  |
|--------------|------------------------------------------|
| 0            | The domain contains settings             |
| 1            | The domain does not contain any settings |

### Standard input

This function does not read from standard input.

### Standard output

Upon success, this function will write the names of settings to
standard output, one name per line. Otherwise, no data will be
written.

### Standard error

This function does not write to standard error.


## conf_set()

Set the value of a setting.

### Synopsis

    conf_set "$name" "$value" "$domain"

### Description

The `conf_set()` function sets the value of the setting `$name`
in the domain `$domain` to `$value`. If `$domain` was omitted,
the setting in the `default` domain will be set.

### Return value

| Return value | Meaning                                     |
|--------------|---------------------------------------------|
| 0            | The setting was written successfully        |
| 1            | The setting could not be written to storage |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function does not write to standard error.


## conf_unset()

Remove a setting.

### Synopsis

    conf_unset "$name" "$domain"

### Description

The `conf_unset()` function removes the setting with name `$name` from
the domain `$domain`. If `$domain` was omitted, the setting will be
removed from the `default` domain.

### Return value

| Return value | Meaning                        |
|--------------|--------------------------------|
| 0            | The setting was removed        |
| 1            | The setting could not be found |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function does not write to standard error.
