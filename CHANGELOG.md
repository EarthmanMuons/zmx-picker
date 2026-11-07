# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] - 2026-11-07

### Added

- Sessions that zmx cannot reach, such as daemons left running by a zmx older
  than 1.0, are listed with the reason instead of as broken rows. Their preview
  explains the cause and shows the daemon process, and Ctrl-X stops it, since
  `zmx kill` hangs on an old daemon

### Fixed

- Session paths from zmx 1.0+, which arrive as `file://` URLs, show as `~` paths
  again, restoring repo session counts. A session on another host, such as
  inside SSH, keeps its URL so the host stays visible
- New numbered sessions skip names held by sessions zmx cannot reach

## [0.4.0] - 2026-09-18

### Added

- `zp --print` selects a session without attaching, writing the attach directory
  and complete session name as two NUL-terminated fields, so scripts can pick
  once and reconnect later
  ([#11](https://github.com/EarthmanMuons/zmx-picker/pull/11))

### Fixed

- `cwd=` from zmx 0.8.0+ list output is parsed alongside the older `start_dir=`,
  fixing the path column and repo session counts on newer zmx versions

## [0.3.0] - 2026-07-24

### Added

- zmx session labels show alongside each session and are fuzzy-searchable, so
  typing `key=value` narrows the list. Labeled sessions keep a clean path and an
  accurate repo session count. Requires zmx 0.7.0 or newer

## [0.2.2] - 2026-07-18

### Fixed

- Enter always acts on the highlighted row, even with rows marked for killing
- Ctrl-N always creates from the typed query, and errors out when the query is
  empty

## [0.2.1] - 2026-07-18

### Changed

- The current session shows a "you are here" note instead of recursively
  previewing the picker itself

## [0.2.0] - 2026-07-18

### Changed

- The preview pane moves below the list when the terminal is narrow
- Columns size themselves to their content
- Repo rows show the name and parent directory instead of the full path

### Removed

- The pid column

### Fixed

- Repo previews degrade gracefully when git or jj is missing

## [0.1.0] - 2026-07-17

### Added

- Initial release: a fuzzy finder for zmx sessions and git or jj repositories,
  with log and scrollback previews
- Selecting a repository starts a numbered session inside it, and Ctrl-N creates
  a session named after the query
- Ctrl-X kills the marked sessions, killing the current session last
- `$ZMX_SESSION_PREFIX` support, `~` path shortening, and an optional fd
  dependency with a find fallback

[unreleased]: https://github.com/EarthmanMuons/zmx-picker/compare/v0.5.0...HEAD
[0.5.0]: https://github.com/EarthmanMuons/zmx-picker/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/EarthmanMuons/zmx-picker/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/EarthmanMuons/zmx-picker/compare/v0.2.2...v0.3.0
[0.2.2]: https://github.com/EarthmanMuons/zmx-picker/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/EarthmanMuons/zmx-picker/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/EarthmanMuons/zmx-picker/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/EarthmanMuons/zmx-picker/releases/tag/v0.1.0
