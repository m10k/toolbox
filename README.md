# toolbox - A module framework for Bash

Have you ever written a shell script and found yourself thinking
"if only the Bash had an include mechanism", while copy-pasting
the  command line parser you wrote for a different shell script?
Then you should try toolbox for your next shell script!


## What's toolbox?

Toolbox is a simple framework for Bash that lets you modularize
your scripts. At the heart of toolbox is the `include()` function,
which works much like the `import` statement in Python. Once you
source *toolbox.sh*, you can use `include()` to load the modules
that ship with toolbox, or create your own ones.


## How do I use it?

All you have to do is source *toolbox.sh* and you can start using
the `include()` function. For example, the following code is a
minimal publisher using the *ipc* module.

    . toolbox.sh
    include "ipc"
    
    endp=$(ipc_endpoint_open)
    ipc_endpoint_publish "$endp" "mytopic" "Hello world"

And this is the corresponding subscriber.

    . toolbox.sh
    include "ipc"
    
    endp=$(ipc_endpoint_open)
    ipc_endpoint_subscribe "$endp" "mytopic"
    
    if msg=$(ipc_endpoint_recv "$endp"); then
    	data=$(ipc_msg_get_data "$msg")
    
    	echo "Received message: $data"
    fi


## What modules are there?

Toolbox comes with a number of modules that solve common problems.
The following is a list of the default modules and what they are
used for.

| Module | Purpose |
|--------|---------|
| array  | Comparing, searching, and sorting arrays |
| conf   | Configuration handling |
| git    | Interacting with git repositories |
| inst   | Writing daemons |
| ipc    | Message-based IPC |
| is     | Checking the value of variables |
| json   | Handling JSON data |
| log    | Logging and debugging |
| mutex  | Locks for protecting shared resources (similar to pthread mutexes) |
| opt    | Command line parsing |
| queue  | "Thread"-safe FIFOs |
| sem    | Process synchronization (similar to POSIX semaphores) |
| wmutex | Weak (owner-less) locks |


## Installation

There are two ways to install toolbox: using apt or from the source.


### Installation using apt

If you are using a Debian-based distribution, you can install toolbox through apt.
First, import the GPG key used to sign packages in the repository and make sure you
have `apt-transport-https` installed.

    # wget -O - -- https://deb.m10k.eu/deb.m10k.eu.gpg.key | apt-key add -
    # apt-get install apt-transport-https

Then add the following line to your `/etc/apt/sources.lst`.

    deb https://deb.m10k.eu stable main

If you prefer a more recent (and maybe slightly more unstable version), use the
`unstable` suite instead.

    deb https://deb.m10k.eu unstable main

Next, update your package index using the following command.

    # apt-get update

Now you can install and update toolbox as you're used to.

    # apt-get install toolbox

The packages in the repository are automatically built from the stable and
unstable branches, so the Debian packages are usually no more than a few minutes
older than the sources.


### Installation from source

To install toolbox from git, check out the sources and run `make install`.

    $ git clone https://github.com/m10k/toolbox
    $ cd toolbox
    $ sudo make install

You will also need to create the *toolbox* and *toolbox_ipc* groups and change
ownership on */var/lib/toolbox* and */var/lib/toolbox/ipc*.

    # chown root.toolbox /var/lib/toolbox
    # chown root.toolbox_ipc /var/lib/toolbox/ipc


### Configuration

To use the ipc module, membership in *toolbox* and *toolbox_ipc* is necessary.
You can add a user to these groups with the following command.

    # usermod -a -G toolbox,toolbox_ipc USERNAME


## How does this work?

When toolbox is installed, `toolbox.sh` is placed in *PATH*, where it will
be picked up by the `source` (aka `.`) shell command, allowing you to load
toolbox without worrying about the path of any other files.
When loading a module, `include()` will search the following paths (in
order) for modules:

 1. `$HOME/.toolbox/include`
 2. `/usr/share/toolbox/include`

This allows you to place custom modules in your home directory, while the
default modules are in a system-wide path.


### And the modules?

Bash does not have a notion of modules, so toolbox tries its best to provide
something that looks like a module, feels like a module, and tastes like a
module, but is not actually a module. For this to work, modules have to
follow strict guidelines.

A module is a single shell script with one or more of the following:

| Element | Description |
|---------|-------------|
| Constructor | Module initialization function called by `include()` |
| Public functions | Functions that may be called by users |
| Private functions | Functions that users must not call |
| Private variables | Variables that users must not use |

In shell, everything shares the same namespace. Thus, the most important
thing about a module is that it does not declare functions or variables
outside of its own namespace. The following table summarizes the naming
convention for modules.

| Element | Naming convention | Example |
|---------|-------------------|---------|
| Module name | Lower-case letters | `example` |
| Module file name | Module name + `.sh` | `example.sh` |
| Constructor | `__init()` | `__init()` |
| Public function | Module name + `_` + function name | `example_open()` |
| Private function | `_` + module name + `_` + function name | `_example_write()` |
| Private variable | `__` + module name + `_` + variable name | `__example_mode` |

Functions intended to be called by users are prefixed with the module name and an
underscore. Functions that users must not call because they might change between
versions at the developers' whim (that is, private functions) are prefixed with an
underscore, the module name, and another underscore. Variables are prefixed with two
underscores, the module name, and another underscore. Variables declared by modules
are always considered private and must not be used directly by users. Further,
because users may execute functions in sub-shells, modules **must** export their
variables (`declare -x`). Module developers are also encouraged to declare their
variables as integers (`declare -i`), arrays (`declare -a`), or associative arrays
(`declare -A`) when they are any of those types. Variables that are not expected to
change (i.e. constants) must be declared as such using `declare -r` or `readonly`.
All global variables must be declared in the module constructor, unless that is
absolutely not feasible. All variables used in module functions **must be declared
using local** unless they are intended to be global.


#### Example module

The following code example illustrates the coding guidelines for modules.

    #
    # logrun.sh - Toolbox module for logging commands
    #

    __init() {
    	if ! include "log"; then
    		return 1
    	fi

    	declare -gxr __logrun_timestamp_format="%Y-%m-%d %H:%M:%S"

    	return 0
    }

    _logrun_get_timestamp() {
    	if ! date +"$__logrun_timestamp_format"; then
    		log_error "Call to date failed. Out of memory?"
    		return 1
    	fi

    	return 0
    }

    _logrun_write_line() {
    	local data="$1"

    	local timestamp

    	if ! timestamp=$(_logrun_get_timestamp); then
    		return 1
    	fi

    	echo "$timestamp $data" 1>&2
    	return 0
    }

    _logrun_log() {
    	local data="$1"

    	local line

    	if (( $# < 1 )); then
    		data=$(< /dev/stdin)
    	fi

    	while read -r line; do
    		if ! _logrun_write_line "$line"; then
    			return 1
    		fi
    	done <<< "$data"

    	return 0
    }

    logrun_exec() {
    	local cmd="$1"
    	local args=("${@:2}")

    	local stdout
    	local retval

    	_logrun_log "Executing: $cmd ${args[*]}"
    	stdout=$("$cmd" "${args[@]}")
    	retval="$?"

    	_logrun_log "$cmd returned $retval"
    	_logrun_log "===== BEGIN stdout ====="
    	_logrun_log <<< "$stdout"
    	_logrun_log "===== END stdout ====="

    	return "$retval"
    }


## Additional modules

There are additional modules in the following repositories. These modules have been
removed from this repository to reduce the dependencies of the toolbox package.

| Repository | Purpose |
|------------|---------|
| [toolbox-goodies](https://github.com/m10k/toolbox-goodies) | Nice-to-have modules |
| [toolbox-linux](https://github.com/m10k/toolbox-linux) | Linux-specific modules |
| [toolbox-restapis](https://github.com/m10k/toolbox-restapis) | Modules for interacting with REST-ful APIs |
