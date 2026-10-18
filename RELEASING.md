# Releasing

1. Update the version and changelog. Document any calculation data, date-range, or JSON-schema changes. Never move an existing release tag.
2. Run formatting, analysis, native/browser tests, example tests, and platform builds. Verify GitHub Actions on all supported platform families.
3. Run `flutter pub publish --dry-run` and inspect every included file. Keep credentials, signing materials, and build outputs excluded.
4. Commit the tested release changes and push using the repository-scoped SSH credential.
5. Run `flutter pub publish` and authenticate with the Google account intended to own the package. Verify the published package and version on pub.dev.
6. Tag the published commit with its version and push the tag.

The GitHub repository remains private. Packages uploaded to pub.dev are publicly downloadable, including their source, and published versions normally cannot be removed. There is no automatic publication workflow. A new package is first published under a Google account; it can subsequently be transferred to a verified publisher.

Project SSH credentials live in local Git metadata or CI secrets, never in tracked files. GitHub credentials do not authenticate pub.dev publication.
