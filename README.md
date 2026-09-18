# zmx-picker

A fuzzy finder for [zmx] sessions and repositories, provided as the `zp`
command.

`zp` presents your running zmx sessions in an [fzf] picker with log and
scrollback previews. When given root directories to search, it also lists any
git or jj repositories beneath them. Selecting a session attaches to it;
selecting a repository starts a numbered session inside it.

<img width="2400" height="1120" alt="Animated demo of the zp session picker" src="https://github.com/user-attachments/assets/cdc4ca7a-b4d5-45b7-a1e4-7a956e212261" />

[zmx]: https://github.com/neurosnap/zmx
[fzf]: https://github.com/junegunn/fzf

## Requirements

- [zmx] and [fzf] (>= 0.51)
- optional: git and/or [jj](https://github.com/jj-vcs/jj) for repository
  previews
- optional: [fd](https://github.com/sharkdp/fd) for faster repository scans

## Installation

### Homebrew

```sh
brew install EarthmanMuons/tap/zmx-picker
```

This installs the `zp` command along with zmx and fzf.

### Manual

Copy the `zp` script somewhere on your `PATH`.

## Usage

```
usage: zp [--print] [root ...]

zmx-picker - lists zmx sessions, plus repos under any roots
given as arguments or $ZP_ROOT (colon-separated)

options:
  --print        Print directory and complete session name, each NUL-terminated,
                 instead of attaching; cancellation emits nothing
  -h, --help     Show this help message
  -V, --version  Print the version
```

For example, to always pick from repositories under `~/src`, set:

**Bash:**

```sh
export ZP_ROOT="$HOME/src"
```

**fish:**

```fish
set -gx ZP_ROOT $HOME/src
```

> [!TIP]
>
> Bind `zp` to a key for quick access:
>
> ```fish
> # bind Ctrl-\ to zp when not inside a zmx session;
> # inside zmx, Ctrl-\ detaches the current session
> if not set -q ZMX_SESSION
>     bind ctrl-\\ 'zp; commandline -f execute'
> end
> ```

Inside the picker:

| Key      | Action                                                                       |
| -------- | ---------------------------------------------------------------------------- |
| `Enter`  | Attach the selection, or create a session named after an unmatched query     |
| `Tab`    | Mark or unmark a session                                                     |
| `Ctrl-N` | Create a session named after the query, even when a candidate is highlighted |
| `Ctrl-X` | Kill the marked sessions, or the highlighted one when none are marked        |
| `Esc`    | Cancel                                                                       |

Sessions created from a repository are named `<repo>.<n>` with the next free
number and start in the repository's directory; sessions created from a query
start in the current directory.

Any [zmx] session labels (`zmx set <name> key=value`) are shown alongside each
session and are fuzzy-searchable, so typing `key=value` narrows the picker to
the sessions that carry that label.

### Selecting without attaching

Use `zp --print [root ...]` to select a session for another command, such as an
autossh wrapper that reconnects to the same selection. Selecting an entry prints
two NUL-terminated fields to stdout, with no trailing newline:

1. The directory from which to attach: the repository directory when selecting a
   repository, or the directory where `zp` was launched when selecting an
   existing session or typing a name. This is not the selected session's
   original starting directory or its live `cwd` reported by zmx.
2. The complete session name, including `ZMX_SESSION_PREFIX` when set. Clear
   that variable when attaching so zmx does not apply the prefix again.

Selection does not create or attach a session. Esc or Ctrl-C cancels with exit
status 0 and no output. The picker still supports Ctrl-X to kill sessions.

In Bash, read the fields directly; command substitution (`$(zp --print)`) cannot
preserve NUL bytes. For example, to attach to the selection:

```bash
if { IFS= read -r -d '' start_dir && IFS= read -r -d '' session_name; } < <(zp --print); then
    (cd "$start_dir" && ZMX_SESSION_PREFIX= zmx attach "$session_name")
fi
```

The reads fail on cancellation, so the example does not attach in that case.

## License

zmx-picker is released under the [Zero Clause BSD License](LICENSE) (SPDX:
0BSD).

Copyright &copy; 2026 [Aaron Bull Schaefer][EMAIL] and contributors

[EMAIL]: mailto:aaron@elasticdog.com
