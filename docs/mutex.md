# The mutex module

The mutex module implements a simple mechanism to enforce serial execution.
The path from a mutex lock operation to its corresponding unlock operation is
called a critical section, and is guaranteed to be executed serially.

Critical sections limit the performance of parallel processes and should thus
be as short as possible. Further, long and nested critical sections are prone
to cause deadlocks and should be avoided.
As a best practice, a critical section should not span multiple functions and
there should be only one codepath that leads out of the critical section.

### Dependencies

The mutex module has no dependencies.

### Function index

| Function                          | Purpose                              |
|-----------------------------------|--------------------------------------|
| [mutex_trylock()](#mutex_trylock) | Try to lock a mutex, without waiting |
| [mutex_lock()](#mutex_lock)       | Lock a mutex, waiting if necessary   |
| [mutex_unlock()](#mutex_unlock)   | Unlock a mutex                       |


## mutex_trylock()

Try to lock a mutex, without waiting.

### Synopsis

    mutex_trylock "$mutex"

### Description

The `mutex_trylock()` function attempts to lock the mutex with the path
`$mutex`. This function returns immediately, regardless of the outcome of
the lock operation.

### Return value

| Return value | Meaning                           |
|--------------|-----------------------------------|
| 0            | The mutex was successfully locked |
| 1            | The mutex could not be locked     |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function does not write to standard error.


## mutex_lock()

Lock a mutex, waiting if necessary.

### Synopsis

    mutex_lock "$mutex" "$timeout"

### Description

The `mutex_lock()` function locks the mutex with the path `$mutex`. If the mutex
is already locked by another process, this function will wait either until it was
able to lock the mutex, or until the timeout has expired. If `$timeout` is -1 or
was omitted, the function will wait indefinitely. Otherwise, it will wait for
`$timeout` seconds. The actual time that this function waits depends on the
process scheduler and may be more than `$timeout` seconds.
If a timeout of 0 is passed, this function is equivalent with `mutex_trylock()`.

### Return value

| Return value | Meaning                           |
|--------------|-----------------------------------|
| 0            | The mutex was successfully locked |
| 1            | The mutex could not be locked     |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function does not write to standard error.


## mutex_unlock()

Unlock a mutex.

### Synopsis

    mutex_unlock "$mutex"

### Description

The `mutex_unlock()` function unlocks the mutex at the path `$mutex`. If
`$mutex` is a valid mutex, this function checks whether the running process
is the owner of the mutex (i.e. if the running process is the process that
locked the mutex) and, if it is not the owner, refuses to unlock the mutex.


### Return value

| Return value | Meaning                                    |
|--------------|--------------------------------------------|
| 0            | The mutex was successfully unlocked        |
| 1            | The mutex could not be read                |
| 2            | The running process does not own the mutex |
| 3            | The mutex could not be removed             |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

This function does not write to standard error.
