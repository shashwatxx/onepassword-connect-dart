import 'package:meta/meta.dart';

import '../errors.dart';
import '../http.dart';
import '../models/item.dart';

/// A single RFC 6902 JSON Patch operation for [ItemsApi.patch].
@immutable
class PatchOperation {
  /// Creates a patch operation.
  const PatchOperation(this.op, this.path, [this.value]);

  /// Adds [value] at [path].
  const PatchOperation.add(String path, Object? value)
      : this('add', path, value);

  /// Removes the value at [path].
  const PatchOperation.remove(String path) : this('remove', path);

  /// Replaces the value at [path] with [value].
  const PatchOperation.replace(String path, Object? value)
      : this('replace', path, value);

  /// `add`, `remove`, or `replace`.
  final String op;

  /// JSON Pointer into the item, e.g. `/fields/username/value` or `/title`.
  final String path;

  /// New value for `add`/`replace` operations.
  final Object? value;

  /// Encodes this operation as JSON.
  Map<String, dynamic> toJson() =>
      {'op': op, 'path': path, if (op != 'remove') 'value': value};
}

/// Access to `/v1/vaults/{vaultId}/items`.
class ItemsApi {
  /// Creates the API group. Used internally by the client.
  const ItemsApi(this._http);

  final ConnectHttpClient _http;

  /// Lists item summaries in [vaultId] (no fields/sections/files).
  ///
  /// [filter] is a SCIM-style expression, e.g. `title eq "GitHub"`.
  Future<List<Item>> list(String vaultId, {String? filter}) async {
    final json = await _http.getJson(
      '/v1/vaults/$vaultId/items',
      query: {if (filter != null) 'filter': filter},
    );
    return (json as List)
        .map((i) => Item.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  /// Gets the full item [itemId] from [vaultId].
  Future<Item> get(String vaultId, String itemId) async {
    final json = await _http.getJson('/v1/vaults/$vaultId/items/$itemId');
    return Item.fromJson(json as Map<String, dynamic>);
  }

  /// Finds a single item in [vaultId] whose title equals [title] and
  /// returns it in full.
  ///
  /// Throws [NotFoundException] when no item matches.
  Future<Item> getByTitle(String vaultId, String title) async {
    final matches = await list(vaultId, filter: 'title eq "$title"');
    if (matches.isEmpty) {
      throw NotFoundException('No item with title "$title" in vault $vaultId');
    }
    return get(vaultId, matches.first.id!);
  }

  /// Creates [item] in [vaultId] and returns the stored item.
  ///
  /// The Connect API cannot create `CUSTOM` or `DOCUMENT` items.
  Future<Item> create(String vaultId, Item item) async {
    if (item.category == ItemCategory.custom ||
        item.category == ItemCategory.document) {
      throw ArgumentError(
        'The Connect API cannot create items with the '
        '${item.category.value} category.',
      );
    }
    final json = await _http.postJson('/v1/vaults/$vaultId/items', item);
    return Item.fromJson(json as Map<String, dynamic>);
  }

  /// Replaces the entire item [itemId] in [vaultId] with [item].
  Future<Item> replace(String vaultId, String itemId, Item item) async {
    final json = await _http.putJson('/v1/vaults/$vaultId/items/$itemId', item);
    return Item.fromJson(json as Map<String, dynamic>);
  }

  /// Applies RFC 6902 [operations] to item [itemId] and returns the result.
  Future<Item> patch(
    String vaultId,
    String itemId,
    List<PatchOperation> operations,
  ) async {
    final json = await _http.patchJson(
      '/v1/vaults/$vaultId/items/$itemId',
      operations.map((o) => o.toJson()).toList(),
    );
    return Item.fromJson(json as Map<String, dynamic>);
  }

  /// Moves item [itemId] to the trash.
  Future<void> delete(String vaultId, String itemId) =>
      _http.delete('/v1/vaults/$vaultId/items/$itemId');
}
