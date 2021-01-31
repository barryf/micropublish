# Changelog

All notable changes to this project (from version 2.3.0 onwards) will be
documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.4.2] - 2021-01-31

### Added

- Support [Channels](https://github.com/indieweb/micropub-extensions/issues/40)
  Micropub extension. If the server supports channels, a new field with
  checkboxes is added to the form and a `mp-channel` property is sent with the
  Micropub request.

## [2.4.1] - 2020-12-14

### Changed

- [Fix code challenge generator](https://github.com/barryf/micropublish/commit/c42324a2a61523942f484b51d3d7e3b87f5fbef7)
  - The previous version did not adhere to [RFC 7636](https://tools.ietf.org/html/rfc7636#appendix-A) for the code challenge.

## [2.4.0] - 2020-12-13

### Added

- [Improve IndieAuth spec compliance](https://github.com/barryf/micropublish/issues/54)
- [Query for supported properties, for a supported post-type](https://github.com/barryf/micropublish/issues/51)

### Changed

- As part of "Query for supported properties..." above, in the `config/properties.json` file the `default` object is now ignored. Properties are explicity defined for each `post-type`.

## [2.3.0] - 2020-10-12

### Added

- [Filter syndication targets by post-type, specify checked as appropriate](https://github.com/barryf/micropublish/issues/45)
- [Raw content instead of HTML for Articles](https://github.com/barryf/micropublish/issues/42)
- [Support `visibility` property](https://github.com/barryf/micropublish/issues/36)
- [Support `post-status` property](https://github.com/barryf/micropublish/issues/35)
- [Add granular scopes to login/auth](https://github.com/barryf/micropublish/issues/33)

### Changed

- [Make JSON the default post creation method](https://github.com/barryf/micropublish/issues/41)
- Only show edit, delete or undelete controls if scope allows
- Added `draft` scope to login form
- Force `post-status` to `draft` when using (only) draft scope
- Bump kramdown from 2.1.0 to 2.3.0
