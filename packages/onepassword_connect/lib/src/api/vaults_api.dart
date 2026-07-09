import '../errors.dart';
import '../http.dart';
import '../models/vault.dart';

/// Access to `/v1/vaults`.
class VaultsApi {
  /// Creates the API group. Used internally by the client.
  const VaultsApi(this._http);

  final ConnectHttpClient _http;

  /// Lists all vaults the token can access.
  ///
  /// [filter] is a SCIM-style expression, e.g. `name eq "My Vault"`.
  Future<List<Vault>> list({String? filter}) async {
    final json = await _http.getJson(
      '/v1/vaults',
      query: {if (filter != null) 'filter': filter},
    );
    return (json as List)
        .map((v) => Vault.fromJson(v as Map<String, dynamic>))
        .toList();
  }

  /// Gets a vault by its [vaultId].
  Future<Vault> get(String vaultId) async {
    final json = await _http.getJson('/v1/vaults/$vaultId');
    return Vault.fromJson(json as Map<String, dynamic>);
  }

  /// Finds a single vault whose title equals [title].
  ///
  /// Throws [NotFoundException] when no vault matches.
  Future<Vault> getByTitle(String title) async {
    final matches = await list(filter: 'name eq "$title"');
    if (matches.isEmpty) {
      throw NotFoundException('No vault with title "$title"');
    }
    return matches.first;
  }
}
