# Changelog

All notable changes to this project (from version 2.3.0 onwards) will be
documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.12.0] - 2025-05-19

### Added

- Support has been added for running Micropublish and redis with Docker using 
  the `docker-compose.yml` file. 
- Optionally pass in `DEV_` environment variables if running in development
  mode (see new section in `README.md` for details).
- Thanks to @perryflynn for contributing these changes.

## [2.11.0] - 2025-02-22

### Added

- Introduces a dark mode that is enabled based on the system setting. This uses
  overrides to the Bootstrap library to implement the dark mode via CSS 
  variables.

## [2.10.1] - 2025-02-11

### Fixed

- Fixed Post Type Discovery for photo posts by looking for `photo` property
  when editing. Thanks to @hacdias for submitting the PR to fix this.

## [2.10.0] - 2025-02-09

### Added

- Extended endpoint discovery to allow servers to specify their IndieAuth Server 
  Metadata endpoint as an alternative to the existing (legacy) headers/body 
  methods. Thanks to @gRegorLove for raising this.

## [2.9.1] - 2024-11-09

### Changed

- Upgrade to Ruby 3.3.5 from 2.6.8. Render (the host for micropublish.net) had
  announced EOL for versions <3.1.0. Shotgun, which was used to auto-reload in
  development mode, is incompatible so it's been replaced with rackup. A more
  permanent (auto-reloading) solution is needed.
- For session management a stronger secret (>64 bytes) is now needed.

## [2.9.0] - 2024-08-26

### Changed

- Upgrade the [Trix](https://trix-editor.org) editor and support inline photo
  uploads in articles. This requires a media endpoint to be defined in your
  server's Micropub config.
  Many thanks to @gorka for contributing this enhancement.

## [2.8.0] - 2022-03-12

### Added

- Support media uploads for the `photo` property. Requires server to return a
  media endpoint in its config.
  Many thanks to @hacdias for contributing this feature.

### Changed

- Use `JSONBodyParser` instead of deprecated `PostBodyContentTypeParser`.

## [2.7.0] - 2022-02-12

### Added

- New "food" and "drink" post types - thanks @hacdias. Your server must specify
  these types in its config properties to see them on the dashboard.
- Location property with geo-location support - thanks @hacdias. Your server
  must specify `location` in its config for a type's properties to see the field
  when creating a post.

## [2.6.1] - 2021-11-22

### Changed

- `client_id` sent to auth endpoint [must include the path element](https://indieauth.spec.indieweb.org/#client-identifier).
  Micropublish now includes a path ("/").

## [2.6.0] - 2021-11-15

### Added

- [Use Redis to cache servers' config data](https://github.com/barryf/micropublish/issues/86).
  If there is a `REDIS_URL` environment variable defined Micropublish will use
  Redis as a cache to avoid repeated lookups for config from a server. This is
  optional: if there is no instance defined Micropublish will fetch config on
  each request. Config is cached for 24 hours.

### Changed

- Updates Puma to non-vulnerable version 5.5.2

## [2.5.4.1] - 2021-06-06

### Fixed

- Fixed Post Type Discovery for listen posts by looking for `listen-of` property
  when editing.

## [2.5.4] - 2021-06-05

### Added

- Support creating listen posts (using `listen-of` URL field).

## [2.5.3] - 2021-05-28

### Changed

- [Don't cache Micropub config in session](https://github.com/barryf/micropublish/issues/76).
  Some servers' Micropub config responses are larger than 4K which is too big
  for cookie storage.

## [2.5.2] - 2021-05-26

### Added

- [Add photo page and field](https://github.com/barryf/micropublish/issues/73).
  For now this won't support the uploading of photos, just specifying existing
  photo URLs.

### Fixed

- Fix tests via webmock
- Update gems

## [2.5.1] - 2021-04-03

### Fixed

- [Ignore unknown/unsupported properties from server](https://github.com/barryf/micropublish/pull/68).
  If your server specifies `post-type` properties and includes properties that
  Micropublish didn't know, when updating a post using one of these properties
  it was possible for them to be marked as removed in the update request.

## [2.5.0] - 2021-03-28

### Changed

- Character counter now works for fields other than `content`. If a `summary`
  field is available this will now include a counter.
- Support changing article content field type: (Trix) Editor, HTML or Text.
  The options available depends on whether you're creating or updating an
  article -- you cannot switch to Text if you're editing an HTML article.
- When redirecting after creating/updating a post, the URL parameter is now
  passed in the query-string, instead of in the session. This is intended as
  a short-term fix for large sessions, as discussed in Issue #62.

## [2.4.5] - 2021-03-01

### Changed

- Upgrade Ruby to 2.6.6, required for the
  [Heroku-20](https://devcenter.heroku.com/articles/heroku-20-stack) stack.
  The previous stack (Heroku-16) is deprecated.

## [2.4.4] - 2021-03-01

### Changed

- [Present authorized scopes to user, post-auth](https://github.com/barryf/micropublish/pull/63).
  Previously the scopes that were requested were assumed to have been granted by
  the server. Thanks to @jamietanna.

## [2.4.3] - 2021-02-09

### Changed

- [Autoconfiguration of fields requires manually editing the `published` property](https://github.com/barryf/micropublish/issues/59)
  - If the `published` field is specified in the properties for a post-type,
    default the value to the current timestamp in ISO8601 UTC format.

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
