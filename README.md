# 1Password for Dart & Flutter

Unofficial 1Password packages for Dart and Flutter, mirroring the capabilities of the
official [1Password SDKs](https://developer.1password.com/docs/sdks/).

| Package | Status | Auth | Platforms |
|---|---|---|---|
| [`onepassword_connect`](packages/onepassword_connect) | ✅ available | [Connect server](https://developer.1password.com/docs/connect/) bearer token | All (Android, iOS, web, desktop, server-side Dart) |
| `onepassword_sdk` | 🧪 planned | [Service accounts](https://developer.1password.com/docs/service-accounts/) via the official WASM core | All (experimental) |

## Which one should I use?

- **You can run a small server (Docker) and want something stable today** → `onepassword_connect`.
  It is a pure-Dart client for the documented, versioned Connect REST API.
- **You want service-account tokens with no extra infrastructure** → `onepassword_sdk`, once it
  ships. It embeds the same WebAssembly core the official Go/JS SDKs use, which is an
  unofficial reuse of 1Password internals and therefore marked experimental.

## Security

A Connect token or service-account token embedded in a distributed app can be extracted by
anyone who has the app. Only ship these tokens in **internal** apps (VPN/SSO-gated), never in
public ones. Prefer handing the token to the app from your own backend after the user signs in.
