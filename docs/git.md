# The git module

The git module implements functions for interacting with git
repositories in the local file system.

### Dependencies

 * [log](log.md)

### Function index

| Function                                            | Purpose                               |
|-----------------------------------------------------|---------------------------------------|
| [git_clone()](#git_clone)                           | Clone a git repository                |
| [git_commit()](#git_commit)                         | Commit a change to the current branch |
| [git_branch_new()](#git_branch_new)                 | Create a new branch                   |
| [git_branch_get_current()](#git_branch_get_current) | Get the name of the current branch    |
| [git_branch_checkout()](#git_branch_checkout)       | Change the current branch             |
| [git_merge()](#git_merge)                           | Merge one branch into another one     |
| [git_push()](#git_push)                             | Push a branch to a remote             |
| [git_remote_get()](#git_remote_get)                 | Get the URL of a remote               |


## git_clone()

Clone a git repository

### Synopsis

    git_clone "$source" "$destination"

### Description

The `git_clone()` function clones the repository specified by `$source` into the path specified
by `$destination`. The source repository may be reachable via any protocol that is understood by
git. The path specified in `$destination` must be on a local file system. It is not necessary
that the destination path exists, however the executing user must have sufficient permissions to
create the path, if it does not exist.

### Return value

| Return value | Meaning                                |
|--------------|----------------------------------------|
| 0            | The repository was successfully cloned |
| 1            | The repository could not be cloned     |

### Standard input

`git_clone()` does not read from standard input.

### Standard output

`git_clone()` does not write to standard output.

### Standard error

If an error occurs, `git_clone()` will write an error message to standard error. The message
that is written includes the standard output and standard error from the git command that was
invoked by `git_clone()`.


## git_commit()

Commit a change to the current branch

### Synopsis

    git_commit "$repository" "$message"

### Description

The `git_commit()` function commits the changes that are staged in the repository specified by
`$repository` to the repository's current branch. The commit message will be set to the value
passed in `$message`.

### Return value

| Return value |                                                |
|--------------|------------------------------------------------|
| 0            | The staged changes were successfully committed |
| 1            | The changes could not be committed             |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

In case of an error, `git_commit()` will write an error message to standard error. The message
that is written includes the standard output and standard error from the git command that was
invoked by `git_commit()`.

## git_branch_new()

Create a new branch

### Synopsis

    git_branch_new "$repository" "$branch"

### Description

The `git_branch_new()` function creates a new branch with name `$branch` in the repository
specified by `$repository`.

### Return value

| Return value | Meaning                             |
|--------------|-------------------------------------|
| 0            | The branch was created successfully |
| 1            | The branch could not be created     |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

In case of an error, `git_branch_new()` will write an error message to standard error. The message
that is written includes the standard output and standard error from the git command that was
invoked by `git_branch_new()`.


## git_branch_get_current()

Get the name of the current branch

### Synopsis

    git_branch_get_current "$repository"

### Description

The `git_branch_get_current()` function writes the name of the working branch of the repository
specified by `$repository` to standard output. The repository must be located in the local file
system and must not be a bare repository.

### Return value

| Return value | Meaning                                        |
|--------------|------------------------------------------------|
| 0            | The branch name was written to standard output |
| 1            | The branch name could not be determined        |

### Standard input

This function does not read from standard input.

### Standard output

On success, the name of the repository's working branch is written to standard output. Otherwise,
no data is written to standard output.

### Standard error

In case of an error, `git_branch_get_current()` will write an error message to standard error.


## git_branch_checkout()

Change the current branch

### Synopsis

    git_branch_checkout "$repository" "$branch"

### Description

The `git_branch_checkout()` function changes the working branch of the repository specified by
`$repository` to the branch specified by `$branch`. The repository must be located in the local
file system. If `$branch` was omitted, the `master` branch will be checked out.

### Return value

| Return value | Meaning                                     |
|--------------|---------------------------------------------|
| 0            | The working branch was successfully changed |
| 1            | The working branch could not be changed     |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

In case of an error, `git_branch_checkout()` will write an error message to standard error. The message
that is written includes the standard output and standard error from the git command that was invoked
by `git_branch_checkout()`.


## git_merge()

Merge one branch into another one

### Synopsis

    git_merge "$repository" "$source" "$destination"

### Description

The `git_merge()` function merges the branch `$source` of the repository `$repository` into the branch
`$destination` of the same repository. If `$destination` was omitted, `$source` will be merged into the
working branch of the repository.

### Return value

| Return value | Meaning                            |
|--------------|------------------------------------|
| 0            | The merge operation was successful |
| 1            | The merge could not be performed   |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

In case of an error, `git_merge()` will write an error message to standard error. The message
that is written includes the standard output and standard error from the git command that was
invoked by `git_merge()`.


## git_push()

Push a branch to a remote

### Synopsis

    git_push "$repository" "$branch" "$remote"

### Description

The `git_push()` function pushes the branch `$branch` of the repository `$repository` to the
remote `$remote`. If `$remote` was omitted, the branch will be pushed to the remote `origin`.
If `$branch` was omitted, the working branch will be pushed.

### Return value

| Return value | Meaning                            |
|--------------|------------------------------------|
| 0            | The branch was pushed successfully |
| 1            | The branch could not be pushed     |

### Standard input

This function does not read from standard input.

### Standard output

This function does not write to standard output.

### Standard error

In case of an error, `git_push()` will write an error message to standard error. The message that
is written will include the standard output and standard error of the git command that was invoked
by `git_push()`.


## git_remote_get()

Get the URL of a remote

### Synopsis

    git_remote_get "$repository" "$remote"

### Description

The `git_remote_get()` function determines the URL of the remote `$remote` of the repository
`$repository` and writes it to standard output.

### Return value

| Return value | Meaning                                              |
|--------------|------------------------------------------------------|
| 0            | The URL of the remote was written to standard output |
| 1            | The URL of the remote could not be determined        |

### Standard input

This function does not read from standard input.

### Standard output

On success, the URL of the remote is written to standard output. Otherwise, no data is written to
standard output.

### Standard error

In case of an error, `git_remote_get()` will write an error message to standard error.
