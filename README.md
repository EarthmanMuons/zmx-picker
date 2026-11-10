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

### Shell setup

To always list repositories under `~/src`, set `ZP_ROOT` with
`export ZP_ROOT="$HOME/src"` in Bash or zsh, or `set -gx ZP_ROOT $HOME/src` in
fish.

In fish, you can also open `zp` with `Ctrl-\` by adding this to your
`config.fish`. The `ZMX_SESSION` check keeps `Ctrl-\` free inside a zmx session,
where it detaches the current session instead:

```fish
if not set -q ZMX_SESSION
    bind ctrl-\\ 'zp; commandline -f execute'
end
```

### Picker keys

| Key      | Action                                                                       |
| -------- | ---------------------------------------------------------------------------- |
| `Enter`  | Attach the selection, or create a session named after an unmatched query     |
| `Tab`    | Mark or unmark a session for `Ctrl-X`                                        |
| `Ctrl-N` | Create a session named after the query, even when a candidate is highlighted |
| `Ctrl-X` | Kill the marked sessions, or the highlighted one when none are marked        |
| `Esc`    | Cancel                                                                       |

Sessions created from a repository are named `<repo>.<n>` with the next free
number and start in the repository's directory. Sessions created from a query
start in the current directory.

Session paths show the working directory zmx reports, shortened to `~`. A
session whose shell is on another host, such as inside SSH, shows its
`file://<host>/...` URL instead.

### Session labels

Labels set with `zmx set <name> key=value` appear at the end of each session's
row and are fuzzy-searchable, so typing `state=failed` narrows the list to the
sessions carrying that label.

To also show an icon ahead of the session name, set `ZP_LABEL_MARKS` to
space-separated `key=value=icon` entries:

```sh
export ZP_LABEL_MARKS='state=working=◐ state=blocked=🔔 state=failed=❌'
```

After `zmx set api.1 state=working`, that session's row looks like this:

```
  ◐  api.1  clients:1   ~/src/api  state=working
```

A session with several matching labels shows each icon, in the order the entries
are listed. A later entry for the same label replaces an earlier one, so you can
override a map set elsewhere: `ZP_LABEL_MARKS="$ZP_LABEL_MARKS state=failed=⊘"`.

### Unreachable sessions

zmx can't reach some sessions, such as daemons left running by a zmx version
with an incompatible protocol. `zp` lists these with the reason, but they can't
be attached.

With `lsof` installed, the preview shows the daemon process and `Ctrl-X` stops
it. This ends anything still running in the session, so if a terminal is still
attached to it, finish up there first.

### Selecting without attaching

`zp --print [root ...]` passes the selection to another command, such as an
autossh wrapper that reconnects to the same session. It doesn't create or attach
a session. Instead, it writes two NUL-terminated fields to stdout, with no
trailing newline:

1. The directory to attach from: the repository's directory for a repository,
   otherwise the directory where `zp` was launched. For an existing session,
   this is not its starting directory or live working directory.
2. The complete session name, including any `ZMX_SESSION_PREFIX`. Clear that
   variable when attaching so zmx doesn't apply the prefix again.

Esc or Ctrl-C prints nothing and exits with status 0. `Ctrl-X` still kills
sessions.

Command substitution can't preserve NUL bytes, so in Bash, read the fields
directly. The reads fail on cancellation, which skips the attach:

```bash
if { IFS= read -r -d '' start_dir && IFS= read -r -d '' session_name; } < <(zp --print); then
    (cd "$start_dir" && ZMX_SESSION_PREFIX= zmx attach "$session_name")
fi
```

## License

zmx-picker is released under the [Zero Clause BSD License](LICENSE) (SPDX:
0BSD).

Copyright &copy; 2026 [Aaron Bull Schaefer][EMAIL] and contributors

[EMAIL]: mailto:aaron@elasticdog.com
