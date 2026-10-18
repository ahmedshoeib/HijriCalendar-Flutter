# Releasing

1. Update the version and changelog. Document any calculation data, date-range, or JSON-schema changes.
2. Run formatting, analysis, native/browser tests, example tests, and platform builds.
3. Push changes and verify GitHub Actions on all supported platform families.
4. Tag the tested commit, for example `1.0.0`, and push the tag.
5. Consumers can pin their private Git dependency to that tag or commit.

This repository is private. Keep `publish_to: none`. A future public/pub.dev release is a separate decision requiring a package-name availability check, license/dependency review, and publication dry run. There is no automatic publication workflow.

Do not move a released tag; issue a new patch version instead. Project SSH credentials live in local Git metadata or CI secrets, never in tracked files.
