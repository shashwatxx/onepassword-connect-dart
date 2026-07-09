## 0.1.0

Initial release.

- Vaults: list (with SCIM filters), get by ID or title.
- Items: list, get, create, replace, JSON Patch (RFC 6902), delete; convenience
  accessors for username/password/notes fields; server-side password generation
  via `GeneratorRecipe`.
- Files: list/get metadata, inline Base64 content, raw content download.
- Server: health, heartbeat, activity log.
- `op://vault/item/[section/]field[?attribute=otp]` secret-reference resolution.
- Typed exceptions for 401/403/404/429/5xx responses.
- Pure Dart — supports all Flutter platforms including web, plus server-side Dart.
