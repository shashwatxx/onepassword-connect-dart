import 'package:http/http.dart' as http;

import 'api/files_api.dart';
import 'api/items_api.dart';
import 'api/server_api.dart';
import 'api/vaults_api.dart';
import 'errors.dart';
import 'http.dart';
import 'models/item.dart';
import 'models/vault.dart';
import 'secret_reference.dart';

/// Client for a 1Password Connect server.
///
/// ```dart
/// final op = OnePasswordConnect(
///   serverUrl: Uri.parse('https://connect.example.com'),
///   token: Platform.environment['OP_CONNECT_TOKEN']!,
/// );
/// final password = await op.resolve('op://App Secrets/Postgres/password');
/// op.close();
/// ```
class OnePasswordConnect {
  /// Creates a client for the Connect server at [serverUrl] with [token].
  ///
  /// Pass [httpClient] to control the transport (proxies, retries, tests).
  OnePasswordConnect({
    required Uri serverUrl,
    required String token,
    http.Client? httpClient,
  }) : _http = ConnectHttpClient(
          baseUrl: serverUrl,
          token: token,
          inner: httpClient,
        );

  final ConnectHttpClient _http;

  /// Vault operations.
  late final VaultsApi vaults = VaultsApi(_http);

  /// Item operations.
  late final ItemsApi items = ItemsApi(_http);

  /// File attachment operations.
  late final FilesApi files = FilesApi(_http);

  /// Health, heartbeat, and activity-log operations.
  late final ServerApi server = ServerApi(_http);

  /// Resolves an `op://` secret [reference] to its value.
  ///
  /// Vault, item, section, and field segments match by ID first, then by
  /// title/label (case-insensitive). With `?attribute=otp` the current
  /// one-time password is returned instead of the field value.
  Future<String> resolve(String reference) async {
    final ref = SecretReference.parse(reference);
    final vault = await _findVault(ref.vault);
    final item = await _findItem(vault.id, ref.item);
    final field = _findField(item, ref);

    if (ref.attribute == 'otp' || ref.attribute == 'totp') {
      final totp = field.totp;
      if (totp == null) {
        throw SecretReferenceException(
            'Field "${ref.field}" has no one-time password: $reference');
      }
      return totp;
    }
    final value = field.value ?? field.totp;
    if (value == null) {
      throw SecretReferenceException(
          'Field "${ref.field}" has no value: $reference');
    }
    return value;
  }

  /// Releases the underlying HTTP client (when owned by this instance).
  void close() => _http.close();

  Future<Vault> _findVault(String idOrTitle) async {
    final all = await vaults.list();
    return all.firstWhere(
      (v) =>
          v.id == idOrTitle || v.name.toLowerCase() == idOrTitle.toLowerCase(),
      orElse: () => throw NotFoundException('No vault "$idOrTitle"'),
    );
  }

  Future<Item> _findItem(String vaultId, String idOrTitle) async {
    final byTitle = await items.list(vaultId, filter: 'title eq "$idOrTitle"');
    if (byTitle.isNotEmpty) return items.get(vaultId, byTitle.first.id!);
    try {
      return await items.get(vaultId, idOrTitle);
    } on ConnectApiException {
      throw NotFoundException('No item "$idOrTitle" in vault $vaultId');
    }
  }

  ItemField _findField(Item item, SecretReference ref) {
    bool sectionMatches(ItemField field) {
      final wanted = ref.section;
      if (wanted == null) return true;
      final sectionId = field.section?.id;
      if (sectionId == null) return false;
      if (sectionId == wanted) return true;
      for (final section in item.sections) {
        if (section.id == sectionId) {
          return section.label?.toLowerCase() == wanted.toLowerCase();
        }
      }
      return false;
    }

    final target = ref.field.toLowerCase();
    for (final field in item.fields) {
      if (!sectionMatches(field)) continue;
      if (field.id == ref.field || field.label?.toLowerCase() == target) {
        return field;
      }
    }
    throw NotFoundException(
        'No field "${ref.field}" on item "${item.title}" ($ref)');
  }
}
