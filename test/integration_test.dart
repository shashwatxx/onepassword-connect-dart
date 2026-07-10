@Tags(['integration'])
library;

/// Round-trip tests against a real Connect server.
///
/// Start one with `docker compose up` in `tool/dev/`, then:
///
///     OP_CONNECT_TOKEN=<token> OP_CONNECT_VAULT=<vault title> \
///         dart test -t integration
import 'dart:io';

import 'package:onepassword_connect/onepassword_connect.dart';
import 'package:test/test.dart';

void main() {
  final token = Platform.environment['OP_CONNECT_TOKEN'];
  final serverUrl =
      Platform.environment['OP_CONNECT_HOST'] ?? 'http://localhost:8080';
  final vaultTitle = Platform.environment['OP_CONNECT_VAULT'];

  late OnePasswordConnect op;
  late Vault vault;

  setUpAll(() async {
    if (token == null || vaultTitle == null) {
      fail(
          'Set OP_CONNECT_TOKEN and OP_CONNECT_VAULT to run integration tests');
    }
    op = OnePasswordConnect(serverUrl: Uri.parse(serverUrl), token: token);
    vault = await op.vaults.getByTitle(vaultTitle);
  });

  tearDownAll(() => op.close());

  test('server is healthy', () async {
    expect(await op.server.heartbeat(), isTrue);
    final health = await op.server.health();
    expect(health['name'], isNotEmpty);
  });

  test('item lifecycle: create → read → patch → delete', () async {
    final created = await op.items.create(
      vault.id,
      Item(
        title: 'onepassword_connect integration test',
        vault: VaultRef(vault.id),
        category: ItemCategory.login,
        tags: const ['onepassword_connect-test'],
        fields: const [
          ItemField.username('integration-user'),
          ItemField.password(null, generate: true),
        ],
      ),
    );
    addTearDown(() => op.items.delete(vault.id, created.id!));

    expect(created.id, isNotNull);
    expect(created.password?.value, isNotEmpty, reason: 'server generates one');

    final read = await op.items.get(vault.id, created.id!);
    expect(read.username?.value, 'integration-user');

    final resolved = await op.resolve(
        'op://${vault.name}/onepassword_connect integration test/username');
    expect(resolved, 'integration-user');

    final patched = await op.items.patch(vault.id, created.id!, const [
      PatchOperation.replace(
          '/title', 'onepassword_connect integration test (renamed)'),
    ]);
    expect(patched.title, endsWith('(renamed)'));
  });
}
