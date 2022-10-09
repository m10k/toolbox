# The queue module

The queue implements a "thread"-safe mechanism for exchanging messages
between multiple processes. Messages exchanged via queues will be received
in the same order that they were sent.

### Dependencies

 * [log](log.md)
 * [mutex](mutex.md)
 * [sem](sem.md)

### Function index

| Function                          | Purpose                                        |
|-----------------------------------|------------------------------------------------|
| [queue_destroy()](#queue_destroy) | Remove a queue                                 |
| [queue_foreach()](#queue_foreach) | Execute a callback for each message in a queue |
| [queue_get()](#queue_get)         | Get a message from a queue                     |
| [queue_init()](#queue_init)       | Create a new queue                             |
| [queue_put()](#queue_put)         | Insert a message into a queue                  |

## queue_destroy()

Remove a queue

### Synopsis

    queue_destroy "$queue"

### Description

The `queue_destory()` function removes the queue referenced by `$queue`.

### Return value

| Return value | Meaning                            |
|--------------|------------------------------------|
| 0            | The queue was successfully removed |
| 1            | The queue could not be removed     |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function does not write to standard error.


## queue_foreach()

Execute a callback for each message in a queue

### Synopsis

    queue_foreach "$queue" "$func" "${args[@]}"

### Description

The `queue_foreach()` function executes the callback `$func` once for each message contained in the queue
referenced by `$queue`. The callback will be passed the message in the first parameter, followed by the
elements in `$args`.
If the callback returns a non-zero value, `queue_foreach()` will not visit the remaining messages in the
queue.

### Return value

| Return value | Meaning                                               |
|--------------|-------------------------------------------------------|
| 0            | The callback successfully processed all messages      |
| 1            | The queue could not be locked, or the callback failed |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function does not write to standard error.


## queue_get()

Get a message from a queue

### Synopsis

    queue_get "$queue" "$timeout"

### Description

The `queue_get()` function will return the message from the head of the queue `$queue`. If the queue is empty,
the function will wait for at least `$timeout` seconds for the arrival of a message. If `$timeout` was
omitted, the function will wait indefinitely; if `$timeout` is zero, the function will return immediately.

### Return value

| Return value | Meaning                                             |
|--------------|-----------------------------------------------------|
| 0            | A message was successfully retrieved from the queue |
| 1            | Could not retrieve a message from the queue         |

### Standard input

This function does not read from standard input.

### Standard output

Upon success, the message retrieved from the queue is written to standard output. Otherwise, no data is
written to standard output.

### Standard error

This function does not write to standard error.


## queue_init()

Create a new queue

### Synopsis

    queue_init "$queue"

### Description

The `queue_init()` function initializes a new queue with path `$queue`. If `$queue` is a relative path, the
queue will be created in the home directory of the executing user.

### Return value

| Return value | Meaning                            |
|--------------|------------------------------------|
| 0            | The queue was successfully created |
| 1            | The queue could not be created     |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function does not write to standard error.


## queue_put()

Insert a message into a queue

### Synopsis

    queue_put "$queue" "$item"

### Description

The `queue_put()` function places the item `$item` in the queue referenced by `$queue`.

### Return value

| Return value | Meaning                            |
|--------------|------------------------------------|
| 0            | The item was successfully inserted |
| 1            | The item could not be inserted     |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function does not write to standard error.
