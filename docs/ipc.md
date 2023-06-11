# The ipc and uipc modules

The ipc module provides and implements an interface for message-based communication
using point-to-point as well as publish-subscribe messaging.
An application can choose between signed and unsigned messaging by including either
the `ipc` or the `uipc` module. It is, however, not possible to use both modules at
once. Further, because the two modules do not use the same message format, messages
sent by one module cannot be read by the other.

### Dependencies

 * [json](json.md)
 * [queue](queue.md)
 * [ipc](ipc.md) (uipc module)


### Function index

| Function                                                            | Purpose                                                  |
|---------------------------------------------------------------------|----------------------------------------------------------|
| [ipc_decode()](#ipc_decode)                                         | Decode an IPC message                                    |
| [ipc_encode()](#ipc_encode)                                         | Encode an IPC message                                    |
| [ipc_endpoint_close()](#ipc_endpoint_close)                         | Close an IPC endpoint                                    |
| [ipc_endpoint_foreach_message()](#ipc_endpoint_foreach_message)     | Iterate over an endpoint's message queue ]               |
| [ipc_endpoint_get_subscriptions()](#ipc_endpoint_get_subscriptions) | Get the list of topics that an endpoint is subscribed to |
| [ipc_endpoint_open()](#ipc_endpoint_open)                           | Open an endpoint for IPC messaging                       |
| [ipc_endpoint_publish()](#ipc_endpoint_publish)                     | Publish a message to a topic                             |
| [ipc_endpoint_recv()](#ipc_endpoint_recv)                           | Receive a point-to-point or pub-sub message              |
| [ipc_endpoint_send()](#ipc_endpoint_send)                           | Send a point-to-point message to another endpoint        |
| [ipc_endpoint_subscribe()](#ipc_endpoint_subscribe)                 | Subscribe an endpoint to one or more topics              |
| [ipc_endpoint_unsubscribe()](#ipc_endpoint_unsubscribe)             | Unsubscribe an endpoint from one or more topics          |
| [ipc_get_root()](#ipc_get_root)                                     | Return the path to the IPC directory                     |
| [ipc_msg_dump()](#ipc_msg_dump)                                     | Dump the contents of an IPC message to standard output   |
| [ipc_msg_get()](#ipc_msg_get)                                       | Extract data from an IPC message                         |
| [ipc_msg_get_data()](#ipc_msg_get_data)                             | Get the payload from a message                           |
| [ipc_msg_get_destination()](#ipc_msg_get_destination)               | Get the address of a message's receiver                  |
| [ipc_msg_get_source()](#ipc_msg_get_source)                         | Get the address of a message's sender                    |
| [ipc_msg_get_timestamp()](#ipc_msg_get_timestamp)                   | Get the time when a message was sent                     |
| [ipc_msg_get_topic()](#ipc_msg_get_topic)                           | Get the topic of a pub-sub message                       |
| [ipc_msg_get_user()](#ipc_msg_get_user)                             | Get the user name of a message's sender                  |
| [ipc_msg_get_version()](#ipc_msg_get_version)                       | Get the protocol version of a message                    |
| [ipc_msg_new()](#ipc_msg_new)                                       | Generate a new IPC message                               |


## ipc_decode()

Decode an IPC message

### Synopsis

    ipc_decode "$encoded"
    ipc_decode <<< "$encoded"

### Description

The `ipc_decode()` function decodes the encoded data that was passed in `encoded` and writes
the resulting data to standard output. If no arguments were passed to this function, it expects
the encoded data to be passed via standard input.

### Return value

| Return value | Meaning                       |
|--------------|-------------------------------|
| 0            | Success                       |
| non-zero     | The data could not be decoded |

### Standard input

If no arguments were passed, this function expects encoded data to be readable on standard input.

### Standard output

If the decoding was successful, the decoded data is written to standard output.

### Standard error

An error message will be written to standard output if the data could not be decoded.


## ipc_encode()

Encode an IPC message

### Synopsis

    ipc_encode "$data"
	ipc_encode <<< "$data"

### Description

The `ipc_encode()` function encodes the data that was passed in `data` and writes the resulting
encoded data to standard output. If no arguments were passed to this function, it expects the
data to be passed via standard input.

### Return value

| Return value | Meaning                       |
|--------------|-------------------------------|
| 0            | Success                       |
| 1            | The data could not be encoded |

### Standard input

If no arguments were passed, this function expects the data to be readable on standard input.

### Standard output

If the encoding was successful, the resulting data is written to standard output.

### Standard error

An error message will be written to standard error if the data could not be encoded.


## ipc_endpoint_close()

Close an IPC endpoint

### Synopsis

    ipc_endpoint_close "$endpoint"

### Description

The `ipc_endpoint_close()` function closes the endpoint referenced by `endpoint` and removes
all storage occupied by it. The endpoint will be unsubscribed from any topics that it was
subscribed to and any unread messages in the endpoint's queue will be discarded. This function
should not be used on endpoints that may be in use by other processes, as closing it in one
process will make it unavailable to all processes.

### Return value

| Return value | Meaning                          |
|--------------|----------------------------------|
| 0            | Success                          |
| 1            | The endpoint could not be closed |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

In case of an error, error messages will be written to standard error to indicate the error
condition that was encountered.


## ipc_endpoint_foreach_message()

Iterate over an endpoint's message queue

### Synopsis

    ipc_endpoint_foreach_message "$endpoint" "$func" "${args[@]}"

### Description

The `ipc_endpoint_foreach_message()` function iterates over the queue of messages that were
received by the endpoint `endpoint` but not yet dispatched using [ipc_endpoint_recv()](#ipc_endpoint_recv).
For each message in the queue, the callback specified in `func` will be executed and passed a reference to
the endpoint in the first, and the message in the second argument, followed by the values of `args`.
Thus, the callback referenced by `func` shall have the following signature.

    foreach_callback() {
        local endpoint="$1"
        local message="$2"
        local args=("${@:3}")
        # ...
    }

If the callback returns a non-zero value, `ipc_endpoint_foreach_message()` will return early
without visiting the remaining elements of the queue.

### Return value

| Return value | Meaning                                                                    |
|--------------|----------------------------------------------------------------------------|
| 0            | Success                                                                    |
| 1            | The endpoint's queue could not be locked or the callback returned an error |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function does not write to standard error.


## ipc_endpoint_get_subscriptions()

Get the list of topics that an endpoint is subscribed to

### Synopsis

    ipc_endpoint_get_subscriptions "$endpoint"

### Description

The `ipc_endpoint_get_subscriptions()` function queries the topics that the endpoint
referenced by `endpoint` is subscribed to and writes the topic names one per line to
standard output.

### Return value

| Return value | Meaning         |
|--------------|-----------------|
| 0            | Always returned |

### Standard input

This function does not read from standard input.

### Standard output

The names of the topics that the endpoint is subscribed to are written to standard output,
one topic per line.

### Standard error

In case of an error, a message indicating the error condition will be written to standard
error.


## ipc_endpoint_open()

Open an endpoint for IPC messaging

### Synopsis

    ipc_endpoint_open "$endpoint"

### Description

The `ipc_endpoint_open()` function opens a public or private endpoint for IPC messaging. If
`endpoint` was not omitted, a public endpoint with the name specified in `endpoint` will be
opened. Otherwise, a private endpoint will be opened.

### Return value

| Return value | Meaning                          |
|--------------|----------------------------------|
| 0            | Success                          |
| 1            | The endpoint could not be opened |

### Standard input

This function does not read from standard input.

### Standard output

Upon success, the name of the endpoint is written to standard output. Otherwise, no data
will be written to standard output.

### Standard error

In case of an error, a message indicating the error condition will be written to standard
error.


## ipc_endpoint_publish()

Publish a message to a topic

### Synopsis

    ipc_endpoint_publish "$endpoint" "$topic" "$message"

### Description

The `ipc_endpoint_publish()` function publishes the message `message` to the topic
specified by `topic` using the endpoint referenced in `endpoint`.

### Return value

| Return value | Meaning                        |
|--------------|--------------------------------|
| 0            | Success                        |
| 1            | The topic could not be created |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

In case of an error, an error message will be written to standard error.


## ipc_endpoint_recv()

Receive a point-to-point or pub-sub message

### Synopsis

    ipc_endpoint_recv "$endpoint" "$timeout"

### Description

The `ipc_endpoint_recv()` function receives an IPC message on the endpoint referenced by
`endpoint` and writes it to standard output. If there are no messages in the queue of the
endpoint, it will wait for up to `timeout` seconds. If `timeout` is zero, the function will
return immediately without waiting for messages. If `timeout` was omitted, the function
will wait indefinitely.

### Return value

| Return value | Meaning            |
|--------------|--------------------|
| 0            | Success            |
| 1            | A timeout occurred |

### Standard input

This function does not read from standard input.

### Standard output

Upon success, the received message will be written to standard output.

### Standard error

This function does not write to standard error.


## ipc_endpoint_send()

Send a point-to-point message to another endpoint

### Synopsis

    ipc_endpoint_send "$endpoint" "$destination" "$message"

### Description

The `ipc_endpoint_send()` function sends the message `message` to the endpoint `destination` using the
endpoint referenced in `endpoint`.

### Return value

| Return value | Meaning                       |
|--------------|-------------------------------|
| 0            | Success                       |
| 1            | The message could not be sent |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

In case of an error, an error message will be written to standard error.


## ipc_endpoint_subscribe()

Subscribe an endpoint to one or more topics

### Synopsis

    ipc_endpoint_subscribe "$endpoint" "${topics[@]}"

### Description

The `ipc_endpoint_subscribe()` function subscribes the endpoint referenced by `endpoint` to
the topics listed in `topics`. If the call succeeded, the endpoint will receive any messages
published on any of the topics that were passed to this function. If any of the subscriptions
failed, successful subscriptions will be undone, restoring the state the endpoint had before
this function was invoked.

### Return value

| Return value | Meaning                                                    |
|--------------|------------------------------------------------------------|
| 0            | All topics were successfully subscribed                    |
| 1            | The endpoint could not be subscribed to some of the topics |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

In case of an error, an error message is written to standard error.


## ipc_endpoint_unsubscribe()

Unsubscribe an endpoint from one or more topics

### Synopsis

    ipc_endpoint_unsubscribe "$endpoint" "${topics[@]}"

### Description

The `ipc_endpoint_unsubscribe()` function unsubscribes the endpoint referenced by `endpoint` from the
topics passed in `topics`. If the call succeeded, the endpoint will no longer receive messages that
were published on any of the topics. However, the endpoint will still receive messages that were
already in its queue at the time when the topic was unsubscribed.

### Return value

| Return value | Meaning                                                 |
|--------------|---------------------------------------------------------|
| 0            | All unsubscribe operations were successful              |
| 1            | The endpoint could not be unsubscribed from some topics |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

In case of an error, an error message is written to standard error.


## ipc_get_root()

Return the path to the IPC directory

### Synopsis

    ipc_get_root

### Description

The `ipc_get_root()` function returns the absolute path to the module's IPC directory. The purpose of this
function is to allow a module that is implementing the `ipc` interface to use an IPC path that is different
from the one defined in the `ipc` module. This function is used by the `ipc` module and users typically do
not need to execute this function.

### Return value

| Return value | Meaning                   |
|--------------|---------------------------|
| 0            | Success (always returned) |

### Standard input

This function does not read from standard input.

### Standard output

The absolute path of the module's IPC directory is written to standard output.

### Standard error

This function does not write to standard error.


## ipc_msg_dump()

Dump the contents of an IPC message to standard output

### Synopsis

    ipc_msg_dump "$envelope"

### Description

The `ipc_msg_dump()` function pretty-prints and dumps the contents of the IPC
message `envelope` to standard output.

### Return value

| Return value | Meaning                   |
|--------------|---------------------------|
| 0            | Success (always returned) |

### Standard input

This function does not read from standard input.

### Standard output

The pretty-printed contents of the message are written to standard output.

### Standard error

In case of an error, an error message will be written to standard error.


## ipc_msg_get()

Extract data from an IPC message

### Synopsis

    ipc_msg_get "$envelope" "$field"

### Description

The `ipc_msg_get()` function extracts the data stored in the field `field` from the message
`envelope` and writes it to standard output.

### Return value

| Return value | Meaning                          |
|--------------|----------------------------------|
| 0            | Success                          |
| 1            | The field could not be extracted |

### Standard input

This function does not read from standard input.

### Standard output

Upon success, the extracted data is written to standard output.

### Standard error

In case of an error, an error message will be written to standard error.


## ipc_msg_get_data()

Get the payload from a message

### Synopsis

    ipc_msg_get_data "$msg"

### Description

The `ipc_msg_get_data()` function extracts the payload contained within the message `msg` and
writes it to standard output.

### Return value

| Return value | Meaning                            |
|--------------|------------------------------------|
| 0            | Success                            |
| 1            | The payload could not be extracted |

### Standard input

This function does not read from standard input.

### Standard output

Upon success, the payload contained within the message is written to standard output.

### Standard error

In case of an error, an error message is written to standard output.


## ipc_msg_get_destination()

Get the address of a message's receiver

### Synopsis

    ipc_msg_get_destination "$msg"

### Description

The `ipc_msg_get_destination()` function retrieves the destination address from the message `msg`
and writes it to standard output.

### Return value

| Return value | Meaning                                        |
|--------------|------------------------------------------------|
| 0            | Success                                        |
| 1            | The destination address could not be retrieved |

### Standard input

This function does not read from standard input.

### Standard output

Upon success, the destination address is written to standard output.

### Standard error

An error will be written to standard error if the destination address could not be read.


## ipc_msg_get_source()

Get the address of a message's sender

### Synopsis

    ipc_msg_get_source "$msg"

### Description

The `ipc_msg_get_source()` function retrieves the source address from the message `msg` and
writes it to standard output.

### Return value

| Return value | Meaning                              |
|--------------|--------------------------------------|
| 0            | Success                              |
| 1            | The source address could not be read |

### Standard input

This function does not read from standard input.

### Standard output

Upon success, the source address is written to standard output.

### Standard error

An error will be written to standard error if the source address could not be read.


## ipc_msg_get_timestamp()

Get the time when a message was sent

### Synopsis

    ipc_msg_get_timestamp "$msg"

### Description

The `ipc_msg_get_timestamp()` function retrieves the timestamp from the message `msg` and
writes it to standard output. The timestamp is an integer value representing the Unix time
of the sender at the time when the message was generated.

### Return value

| Return value | Meaning                         |
|--------------|---------------------------------|
| 0            | Success                         |
| 1            | The timestamp could not be read |

### Standard input

This function does not read from standard input.

### Standard output

Upon success, the timestamp is written to standard output.

### Standard error

An error will be written to standard error if the timestamp could not be read.


## ipc_msg_get_topic()

Get the topic of a pub-sub message

### Synopsis

    ipc_msg_get_topic "$msg"

### Description

The `ipc_msg_get_topic()` function retrieves the topic from the message `msg` and writes
it to standard output.

### Return value

| Return value | Meaning                     |
|--------------|-----------------------------|
| 0            | Success                     |
| 1            | The topic could not be read |

### Standard input

This function does not read from standard input.

### Standard output

Upon success, the topic will be written to standard output.

### Standard error

An error will be written to standard error if the topic could not be read.


## ipc_msg_get_user()

Get the user name of a message's sender

### Synopsis

    ipc_msg_get_user "$msg"

### Description

The `ipc_msg_get_user()` function retrieves the name of the user that sent the message `msg` and
writes it to standard output.

### Return value

| Return value | Meaning                         |
|--------------|---------------------------------|
| 0            | Success                         |
| 1            | The user name could not be read |

### Standard input

This function does not read from standard input.

### Standard output

Upon success, the user name of the sender is written to standard output.

### Standard error

An error will be written to standard error if the user name could not be read.


## ipc_msg_get_version()

Get the protocol version of a message

### Synopsis

    ipc_msg_get_version "$msg"

### Description

The `ipc_msg_get_version()` function retrieves the protocol version from the message `msg` and
writes it to standard output. The protocol version is an integer value.

### Return value

| Return value | Meaning                                |
|--------------|----------------------------------------|
| 0            | Success                                |
| 1            | The protocol version could not be read |

### Standard input

This function does not read from standard input.

### Standard output

Upon success, an integer value representing the protocol version is written to standard output.

### Standard error

An error will be written to standard error if the protocol version could not be read.


## ipc_msg_new()

Generate a new IPC message

### Synopsis

    ipc_msg_new "$source" "$destination" "$data" "$topic"

### Description

The `ipc_msg_new()` function generates a new IPC message with the source address, destination
address, and payload set to the values passed in `source`, `destination`, and `data`,
respectively. If `topic` was omitted, the generated message will not carry a topic field.
Otherwise, the value of the topic field will be set to the value of `topic`.
This function is meant for module-internal use and may need to be overridden by modules that
implement the `ipc` interface. There is no need for users to call this function.

### Return value

| Return value | Meaning                            |
|--------------|------------------------------------|
| 0            | Success                            |
| 1            | The message could not be generated |

### Standard input

This function does not read from standard input.

### Standard output

Upon success, the generated message is written to standard output.

### Standard error

An error is written to standard error if the message could not be generated.
