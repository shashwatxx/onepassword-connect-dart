/// Unofficial pure-Dart client for the
/// [1Password Connect REST API](https://developer.1password.com/docs/connect/connect-api-reference/).
///
/// Works on every Dart and Flutter platform (mobile, web, desktop, server).
library;

export 'src/api/files_api.dart' show FilesApi;
export 'src/api/items_api.dart' show ItemsApi, PatchOperation;
export 'src/api/server_api.dart' show ServerApi;
export 'src/api/vaults_api.dart' show VaultsApi;
export 'src/client.dart' show OnePasswordConnect;
export 'src/errors.dart';
export 'src/models/api_request.dart';
export 'src/models/file.dart';
export 'src/models/item.dart';
export 'src/models/vault.dart';
export 'src/secret_reference.dart' show SecretReference;
