# zmx-picker

A fuzzy finder for [zmx] sessions and repositories, provided as the `zp`
command.

`zp` presents your running zmx sessions in an [fzf] picker with log and
scrollback previews. When given root directories to search, it also lists any
git or jj repositories beneath them. Selecting a session attaches to it;
selecting a repository starts a numbered session inside it.

[zmx]: https://github.com/neurosnap/zmx
[fzf]: https://github.com/junegunn/fzf

## Requirements

- [zmx], [fzf] (>= 0.53), and [fd](https://github.com/sharkdp/fd)
- git and/or [jj](https://github.com/jj-vcs/jj) for repository previews

## Installation

Copy the `zp` script somewhere on your `PATH`.

## Usage

```
usage: zp [root ...]

zmx-picker - lists zmx sessions, plus repos under any roots
given as arguments or $ZP_ROOT (colon-separated)
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

Inside the picker:

| Key      | Action                                                                       |
| -------- | ---------------------------------------------------------------------------- |
| `Enter`  | Attach the selection, or create a session named after an unmatched query     |
| `Ctrl-N` | Create a session named after the query, even when a candidate is highlighted |
| `Ctrl-X` | Kill the highlighted session                                                 |
| `Esc`    | Cancel                                                                       |

Sessions created from a repository are named `<repo>.<n>` with the next free
number and start in the repository's directory; sessions created from a query
start in the current directory.

## License

zmx-picker is released under the [Zero Clause BSD License](LICENSE) (SPDX:
0BSD).

Copyright &copy; 2026 [Aaron Bull Schaefer][EMAIL] and contributors

[EMAIL]: mailto:aaron@elasticdog.com
