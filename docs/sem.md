# The sem module

The sem module implements a semaphore datatype for synchronizing access
to shared resources such as queues.

### Dependencies

 * [is](is.md)
 * [log](log.md)
 * [mutex](mutex.md)
 * [wmutex](wmutex.md)

### Function index

| Function                      | Purpose                                             |
|-------------------------------|-----------------------------------------------------|
| [sem_destroy()](#sem_destroy) | Clean up a semaphore                                |
| [sem_init()](#sem_init)       | Initialize a new semaphore                          |
| [sem_post()](#sem_post)       | Increase a semaphore                                |
| [sem_peek()](#sem_peek)       | Get the counter of a semaphore without modifying it |
| [sem_trywait()](#sem_trywait) | Try to decrease a semaphore without waiting         |
| [sem_wait()](#sem_wait)       | Decrease a semaphore, waiting if necessary          |

## sem_destroy()

Clean up a semaphore

### Synopsis

    sem_destroy "$name"

### Description

The `sem_destroy()` function removes the semaphore referenced by `$name` and frees all resources
occupied by it. Before removing the semaphore, this function checks if the calling process is the
owner of the semaphore. If the caller is not the owner of the semaphore, an error will be returned.

### Return value

| Return value | Meaning                                |
|--------------|----------------------------------------|
| 0            | The semaphore was removed successfully |
| 1            | The semaphore could not be removed     |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

In case of an error, this function writes a message to standard error.


## sem_init()

Initialize a new semaphore

### Synopsis

    sem_init "$name" "$value"

### Description

The `sem_init()` function creates a new semaphore with the name `$name` and initializes its counter
to the value `$value`. If `$name` is a relative path, the semaphore will be created in the calling
user's home directory, otherwise `$name` is assumed to be the absolute path of a semaphore.

### Return value

| Return value | Meaning                                                |
|--------------|--------------------------------------------------------|
| 0            | The semaphore was created and initialized successfully |
| 1            | The semaphore could not be created                     |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

In case of an error, this function writes a message to standard error.


## sem_post()

Increase a semaphore

### Synopsis

    sem_post "$name"

### Description

The `sem_post()` function increases the counter of a semaphore. This is a synchronous operation, and
may cause the caller to block indefinitely.

### Return value

| Return value | Meaning                                  |
|--------------|------------------------------------------|
| 0            | The semaphore was increased successfully |
| 1            | The semaphore could not be increased     |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function does not write to standard error.


## sem_peek()

Get the counter of a semaphore without modifying it

### Synopsis

    sem_peek "$name"

### Description

The `sem_peek()` function reads the counter of the semaphore referenced by `$name` and writes it to
standard output. This is a synchronous operation, and may cause the caller to block indefinitely.

### Return value

| Return value | Meaning                                                 |
|--------------|---------------------------------------------------------|
| 0            | The counter was successfully written to standard output |
| 1            | The counter could not be read                           |

### Standard input

This function does not read from standard input.

### Standard output

On success, the counter of the semaphore is written to standard output. Otherwise, no data is written
to standard output.

### Standard error

This function does not write to standard error.


## sem_trywait()

Try to decrease a semaphore without waiting

### Synopsis

    sem_trywait "$name"

### Description

The `sem_trywait()` function attempts to decrease the counter of the semaphore referenced by `$name`
and returns immediately. If the counter cannot be decreased without waiting on the semaphore, the
counter is not decreased, and an error is returned.
This function is equivalent to `sem_wait()` with a timeout of `0`, and may be implemented as a call
to `sem_wait()`.

### Return value

| Return value | Meaning                                              |
|--------------|------------------------------------------------------|
| 0            | The semaphore was decreased successfully             |
| 1            | The semaphore could not be decreased without waiting |


### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function does not write to standard error.


## sem_wait()

Decrease a semaphore, waiting if necessary

### Synopsis

    sem_wait "$name" "$timeout"

### Description

The `sem_wait()` function decreases the counter of the semaphore referenced by `$name`, waiting on the
semaphore if necessary. The function will wait at most `$timeout` seconds, however the exact time waited
depends on the process scheduler and may exceed `$timeout` seconds. If the timeout is negative or has been
omitted, the function may wait indefinitely. If the timeout is `0`, the function will attempt to decrease
the counter without waiting. The latter is equivalent to a call to `sem_trywait()`.

### Return value

| Return value | Meaning                                                           |
|--------------|-------------------------------------------------------------------|
| 0            | The semaphore has been decreased successfully                     |
| 1            | The semaphore could not be decreased within the specified timeout |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function does not write to standard error.
