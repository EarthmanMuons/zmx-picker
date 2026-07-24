# zmx-picker

A fuzzy finder for [zmx] sessions and repositories, provided as the `zp`
command.

`zp` presents your running zmx sessions in an [fzf] picker with log and
scrollback previews. When given root directories to search, it also lists any
git or jj repositories beneath them. Selecting a session attaches to it;
selecting a repository starts a numbered session inside it.

<img width="2400" height="1120" alt="Animated demo of the zp session picker" src="https://github.com/user-attachments/assets/c80ce837-25eb-4c1f-b394-d9f6f1daed54" />

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
usage: zp [root ...]

zmx-picker - lists zmx sessions, plus repos under any roots
given as arguments or $ZP_ROOT (colon-separated)

options: -h/--help, -V/--version
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

## License

zmx-picker is released under the [Zero Clause BSD License](LICENSE) (SPDX:
0BSD).

Copyright &copy; 2026 [Aaron Bull Schaefer][EMAIL] and contributors

[EMAIL]: mailto:aaron@elasticdog.com
