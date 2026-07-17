#!/bin/sh
# Stage /tmp/zp-demo with scratch repos for the README demo render.
# Commit subjects are real history snapshots from the EarthmanMuons
# repositories, deep enough to overflow the preview pane.
set -eu

root=/tmp/zp-demo
rm -rf "$root"
mkdir -p "$root/src"

commit() {
	printf '%s\n' "$2" >>"$1/NOTES.md"
	git -C "$1" add NOTES.md
	git -C "$1" -c user.name=demo -c user.email=demo@example.com \
		-c commit.gpgsign=false commit -q -m "$2"
}

# populate <repo-name>, with one commit message per stdin line,
# oldest first. Repos end up colocated so jj works in them for real.
populate() {
	d=$root/src/$1
	mkdir -p "$d"
	git -C "$d" init -q -b main
	while IFS= read -r msg; do
		commit "$d" "$msg"
	done
	jj git init --colocate "$d" >/dev/null 2>&1
}

populate whatchord <<'EOF'
Rename the analyzer explanation API away from debug framing
Rename the engine package to whatchord and the app to whatchord_app
Document the whatchord public API
Adopt a pub workspace for the whatchord package
Widen the whatchord package SDK floor to 3.8
Add a runnable example for the whatchord package
Fold the chord history domain into whatchord as its temporal module
Extract the key detectors into a whatkey package
Document the whatkey public API and add a runnable example
Polish the public API naming across both packages
Audit and normalize comments across the app
Reorganize tool/ into per-initiative subdirectories
Sync web build with latest restructured code
Simplify the paper for journal style and align claims across docs
Replace the nav checkbox hack with a disclosure button
Keep the abstention takeaway in the prose, not the figure caption
Expand package READMEs for eventual pub.dev publication
Tidy the research companion docs after the paper revision
Make the WhatKey landing page friendlier for first-time visitors
Make the WhatKey paper build reproducible
Fix the landing page image layout for phones
Make the WhatKey paper anonymous build submission-ready
Add the competing interests statement to the WhatKey paper
Review split-color oracle edge cases
Price rare altered-major flat-nine colors
Review split-color upper-structure oracle cases
Review dense altered-dominant oracle cases
Document altered-major flat-nine ranking fix
Review minor-thirteenth and altered-dominant oracle cases
Bump app_links from 7.2.0 to 7.2.1 in the dependencies group
EOF

populate herosync <<'EOF'
feat: bare bones OAuth workflow for publish is working
feat: submit multiple scopes for the client
refactor!: rename all of the media files
refactor: use rel consistently as short version for relative (path)
feat: add some type saftey to the group by values
feat: make mDNS discovery a bit more robust
feat: distinguish between incoming/outgoing on media inventory
fix: make sure we skip processed files when filtering
feat: allow filtering by all display info not just filenames
refactor: dry up the argument-based inventory filtering
fix: do not attempt to clean up processed files
feat: use custom display for out of sync files
feat: store oauth creds and token in XDG config directory
feat: automatically clean up partial downloads
chore: use recommended NewService endpoint instead of New
wip: debugging upstream youtube file details bug
wip: uploads are working!
feat: implement the yolo command wrapper
feat: only inventory mp4 media files
feat: skip uploading videos that already exist
refactor: split out the shouldUpload logic for clarity
feat: print progress updates when uploading files
feat: allow configuration for video upload details
refactor: clean up publishing code using an options structure
feat: use context to allow cancelling ffprobe exec
feat: return an error if duration can't be determined
feat: add launchctl plist file and instructions
docs: use absolute path for executable in launchctl plist file
docs: fix minor typo
chore: update dependencies to latest upstream versions
EOF

populate spellout <<'EOF'
Allow Unicode override keys and clarify normalization
Update project dependencies in the lockfile
Bump convert_case to 0.11.0
Update spellout and xtask dependencies
Ignore the @main pin for our first-party CI tooling
Ignore pull_request_target usage on our auto-label job
Enable dependabot cooldown for stability and security
Tighten up our broad permissions and secrets inheritance
Add derives and Default for PhoneticConverter in spellabet
Preallocate the alphabet map capacity for spellabet
Add a sorted accessor for `PhoneticConverter` mappings
Move workspace to Rust 2024 and MSRV 1.91
Summarize post-0.2.0 work for spellabet
Remove deprecated package.authors field
Release spellabet v0.3.0
Correct the crate license metadata to reflect 0BSD
Release spellabet v0.3.1
Release spellout v0.3.0
Bump the dependencies group with 2 updates
Bump the dependencies group with 2 updates
Bump lexopt from 0.3.1 to 0.3.2 in the dependencies group
Bump which from 8.0.0 to 8.0.1 in the dependencies group
Bump the dependencies group with 4 updates
Bump the dependencies group with 2 updates
Bump insta from 1.47.1 to 1.47.2 in the dependencies group
Bump the dependencies group with 2 updates
Bump clap_complete from 4.6.2 to 4.6.3 in the dependencies group
Bump clap_complete from 4.6.3 to 4.6.4 in the dependencies group
Bump clap_complete from 4.6.4 to 4.6.5 in the dependencies group
Bump the dependencies group with 2 updates
EOF

populate toolbox-envy <<'EOF'
Add temporary signing smoke test to validate codesign failures
Emit the IOS_KEYCHAIN_PATH as output from our ios-signing-setup script
Add pairing safety check for certificate vs profile cert match
Fix illegal byte sequence issue in our pairing safety check
Revert the pairing check logic but ensure profile was created
Rework Android screenshot preparation and fail more gracefully
Fix possible code injection via template expansion
Address the overly broad permissions warning from zizmor
Document our purposeful unpinned use case
Ignore the @main pin for our first-party reusable workflows
Add get-project-version script for Rust packages
Output the available packages if multiple are detected
Improve manifest lookup in version scripts
Add script to set up App Store Connect auth key from env vars
Add script to verify asset checksums
Add script to verify checksums for asset files
Remove old script named verify-asset
Also emit the filename and full path for the ASC key
Make our emitted output naming consistent
Add script index to our README documentation
Rename emit_output to emit_github_output for clarity
Refactor verify-checksums to use main() and structured helpers
Refactor all scripts to standarize structure and docs
Use resolve_repo_root helper function consistently across scripts
Update verify-checksums to handle multiple patterns
Standardize format for usage placeholder values
Document the --help flag consistently
Capture the temp path so it doesn't dereference a local
Fix to avoid unbound tmp_dir in EXIT trap under set -u
Add rotate-whatsnew script to roll unreleased docs into a release dir
EOF

populate reusable-workflows <<'EOF'
Add step to debug OIDC claims for our Google Auth
Remove debug step for OIDC claims
Bump the dependencies group across 1 directory with 3 updates
Bump the dependencies group with 2 updates
Use built-in gh cli instead of third-party action for release step
Bump the dependencies group across 1 directory with 14 updates
Replace archived gh-actions-cache extension with direct gh command
Do not update dependencies when bumping versions
Update docs to reflect non updating deps on bump
Migrate from track to tracks based on upstream changes
Migrate to supported Action to generate GitHub App tokens
Bump the dependencies group with 2 updates
Limit GitHub App token permissions in workflows
Bump the dependencies group across 1 directory with 3 updates
Add optional Google Play release notes upload
Bump the dependencies group with 3 updates
Bump the dependencies group with 2 updates
Bump the dependencies group with 3 updates
Bump taiki-e/install-action in the dependencies group
Add reusable Stylelint workflow
Document reusable workflow inputs
Add reusable HTML formatting workflow
Install stylelint-config-recess-order and stylint-config-standard
Rename check-stylelint to check-css for consistency
Bump the dependencies group with 4 updates
Bump the dependencies group with 3 updates
Add reusable Python Ruff checks
Bump the dependencies group with 4 updates
Check local Dart packages in the Flutter workflow
Resolve local packages before the root Flutter analyze
EOF

populate zmx-picker <<'EOF'
Initial commit
Add multi-select session killing
Make session previews scrollable back through history
Fix false "no sessions" report under pipefail
Make shellcheck clean
Replace basename and tr with parameter expansions
Cut per-repo forks from the candidates loop
Make fd optional with a find fallback
Add an end-to-end test suite
Handle ZMX_SESSION_PREFIX cleanly
Add a header comment linking to the repository
Add --version/-V in preparation for packaging
Mark the current session in the picker
Shorten home directory paths to ~ in the picker
Kill the current session last
Let --version and --help run without dependencies
Document the Homebrew tap installation
Degrade repo previews gracefully when git or jj is missing
EOF
