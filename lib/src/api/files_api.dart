import 'dart:typed_data';

import '../http.dart';
import '../models/file.dart';

/// Access to `/v1/vaults/{vaultId}/items/{itemId}/files`.
class FilesApi {
  /// Creates the API group. Used internally by the client.
  const FilesApi(this._http);

  final ConnectHttpClient _http;

  /// Lists files attached to an item.
  ///
  /// With [inline] set, files under the server's size threshold include
  /// their Base64 [ItemFile.content] directly.
  Future<List<ItemFile>> list(
    String vaultId,
    String itemId, {
    bool inline = false,
  }) async {
    final json = await _http.getJson(
      '/v1/vaults/$vaultId/items/$itemId/files',
      query: {if (inline) 'inline_files': 'true'},
    );
    return (json as List)
        .map((f) => ItemFile.fromJson(f as Map<String, dynamic>))
        .toList();
  }

  /// Gets a file's metadata.
  Future<ItemFile> get(
    String vaultId,
    String itemId,
    String fileId, {
    bool inline = false,
  }) async {
    final json = await _http.getJson(
      '/v1/vaults/$vaultId/items/$itemId/files/$fileId',
      query: {if (inline) 'inline_files': 'true'},
    );
    return ItemFile.fromJson(json as Map<String, dynamic>);
  }

  /// Downloads a file's raw content.
  Future<Uint8List> content(String vaultId, String itemId, String fileId) =>
      _http.getBytes('/v1/vaults/$vaultId/items/$itemId/files/$fileId/content');
}
