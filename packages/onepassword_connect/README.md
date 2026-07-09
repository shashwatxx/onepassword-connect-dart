# onepassword_connect

Unofficial pure-Dart client for the
[1Password Connect REST API](https://developer.1password.com/docs/connect/connect-api-reference/).
Works on **every** Dart and Flutter platform — Android, iOS, web, macOS, Windows,
Linux, and server-side Dart — because it is plain HTTP with no native code.

> This package is not affiliated with or endorsed by 1Password (AgileBits Inc.).

## What you need

A self-hosted [1Password Connect server](https://developer.1password.com/docs/connect/)
(two small Docker containers) and an access token, both created from your
1Password account. `tool/dev/docker-compose.yaml` in this repo spins one up
locally. If you want service-account tokens without any server, that requires
1Password's SDK core and is planned as a separate experimental package.

## Usage

```dart
import 'package:onepassword_connect/onepassword_connect.dart';

final op = OnePasswordConnect(
  serverUrl: Uri.parse('https://connect.example.com'),
  token: connectToken,
);

// The fastest way to read a secret — op:// secret references:
final dbPassword = await op.resolve('op://App Secrets/Postgres/password');
final otp = await op.resolve('op://App Secrets/GitHub/one-time password?attribute=otp');

// Vaults and items:
final vaults = await op.vaults.list();
final vault = await op.vaults.getByTitle('App Secrets');
final item = await op.items.getByTitle(vault.id, 'Postgres');
print(item.username?.value);

// Create an item with a server-generated password:
final created = await op.items.create(
  vault.id,
  Item(
    title: 'New Login',
    vault: VaultRef(vault.id),
    category: ItemCategory.login,
    fields: [
      ItemField.username('admin'),
      ItemField.password(null, generate: true),
    ],
  ),
);

// Update with RFC 6902 JSON Patch:
await op.items.patch(vault.id, created.id!, [
  PatchOperation.replace('/title', 'New Login (prod)'),
]);

// Files:
final files = await op.files.list(vault.id, created.id!, inline: true);

op.close();
```

Errors are typed: `AuthenticationException` (401), `AuthorizationException` (403),
`NotFoundException` (404), `RateLimitException` (429), `ServerException` (5xx) —
all subtypes of `ConnectApiException`.

## Flutter web and CORS

The Connect server does not send CORS headers, so a browser app cannot call it
directly. Front it with a reverse proxy that adds them. Caddy example:

```caddyfile
connect.example.com {
  @preflight method OPTIONS
  handle @preflight {
    header Access-Control-Allow-Origin "https://app.example.com"
    header Access-Control-Allow-Methods "GET, POST, PUT, PATCH, DELETE, OPTIONS"
    header Access-Control-Allow-Headers "Authorization, Content-Type"
    respond 204
  }
  handle {
    header Access-Control-Allow-Origin "https://app.example.com"
    reverse_proxy connect-api:8080
  }
}
```

For local development, `docker compose --profile cors up` in `tool/dev/`
serves a CORS-enabled proxy at `http://localhost:8081`.

## Security: where does the token live?

**Anyone who has your app can extract the token embedded in it**, and the token
grants access to every vault it was scoped to. Rules of thumb:

- ✅ Server-side Dart, CI, internal tools on trusted machines.
- ⚠️ Internal mobile/web apps: acceptable only when distribution is restricted
  (MDM, VPN, SSO-gated hosting) — and scope the token to the minimum vaults.
- ❌ Public apps: never. Have your backend talk to Connect and expose only the
  specific values your app needs, after authenticating the user.

Prefer handing the token to the app at login time from your own backend instead
of compiling it in. If you must bake it in, use `--dart-define=OP_TOKEN=...`
rather than committing it to source.

## Example app

[`example/`](example/) contains a Flutter vault browser (connect → vaults →
items → reveal/copy fields) that runs on web:

```sh
cd example && flutter run -d chrome
```

## Local Connect server for development

1. [Create a Connect server](https://developer.1password.com/docs/connect/get-started/)
   in your 1Password account and download `1password-credentials.json`.
2. Put it in `tool/dev/` (gitignored) and run `docker compose up`.
3. The API is at `http://localhost:8080`; the integration test suite in
   `test/` tagged `integration` runs against it.
