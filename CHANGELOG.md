## [Unreleased]

- [DefaultRequester] Convert request headers to string keys
  - This solves the issue that `: “Content-Type” (symbol key)` is set even if `“Content-Type” (string key)` is specified in post/put/patch.

## [1.0.0] - 2024-08-04

- Initial release
