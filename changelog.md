# Changelog

All notable changes to this project (from version 2.3.0 onwards) will be
documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.3.0] - 2020-10-11

### Added

- [Filter syndication targets by post-type, specify checked as appropriate](https://github.com/barryf/micropublish/issues/45)
- [Raw content instead of HTML for Articles](https://github.com/barryf/micropublish/issues/42)
- [Make JSON the default post creation method](https://github.com/barryf/micropublish/issues/41)
- [Support `visibility` property](https://github.com/barryf/micropublish/issues/36)
- [Support `post-status` property](https://github.com/barryf/micropublish/issues/35)
- [Add granular scopes to login/auth](https://github.com/barryf/micropublish/issues/33)

### Changed

- Only show edit, delete or undelete controls if scope allows
- Added `draft` scope to login form
- Force `post-status` to `draft` when using (only) draft scope
- Bump kramdown from 2.1.0 to 2.3.0
