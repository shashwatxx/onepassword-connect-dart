import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:onepassword_connect/onepassword_connect.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('VaultsApi', () {
    test('list hits GET /v1/vaults with bearer token', () async {
      final log = <RecordedRequest>[];
      final op = clientWith(log: log, (_) => jsonResponse([vaultJson]));
      final vaults = await op.vaults.list();

      expect(vaults.single.name, 'App Secrets');
      expect(log.single.method, 'GET');
      expect(log.single.url.path, '/v1/vaults');
      expect(log.single.request.headers['Authorization'], 'Bearer test-token');
    });

    test('list passes SCIM filter', () async {
      final log = <RecordedRequest>[];
      final op = clientWith(log: log, (_) => jsonResponse([vaultJson]));
      await op.vaults.list(filter: 'name eq "App Secrets"');
      expect(log.single.url.queryParameters['filter'], 'name eq "App Secrets"');
    });

    test('getByTitle throws NotFoundException on empty result', () async {
      final op = clientWith((_) => jsonResponse([]));
      expect(
          op.vaults.getByTitle('missing'), throwsA(isA<NotFoundException>()));
    });
  });

  group('ItemsApi', () {
    test('get hits the item path', () async {
      final log = <RecordedRequest>[];
      final op = clientWith(log: log, (_) => jsonResponse(fullItemJson));
      final item = await op.items.get('vault1', 'item1');
      expect(item.title, 'Postgres');
      expect(log.single.url.path, '/v1/vaults/vault1/items/item1');
    });

    test('create POSTs the item body', () async {
      final log = <RecordedRequest>[];
      final op = clientWith(log: log, (_) => jsonResponse(fullItemJson));
      await op.items.create(
        'vault1',
        Item(
          title: 'Postgres',
          vault: const VaultRef('vault1'),
          category: ItemCategory.database,
        ),
      );
      expect(log.single.method, 'POST');
      final sent = jsonDecode(log.single.body) as Map<String, dynamic>;
      expect(sent['title'], 'Postgres');
      expect(sent['category'], 'DATABASE');
    });

    test('create rejects CUSTOM and DOCUMENT categories locally', () {
      final op = clientWith((_) => fail('must not reach the network'));
      for (final category in [ItemCategory.custom, ItemCategory.document]) {
        expect(
          () => op.items.create(
            'vault1',
            Item(
                title: 'x',
                vault: const VaultRef('vault1'),
                category: category),
          ),
          throwsArgumentError,
        );
      }
    });

    test('patch sends an RFC 6902 array', () async {
      final log = <RecordedRequest>[];
      final op = clientWith(log: log, (_) => jsonResponse(fullItemJson));
      await op.items.patch('vault1', 'item1', const [
        PatchOperation.replace('/title', 'Postgres (prod)'),
        PatchOperation.remove('/fields/host-field'),
      ]);
      expect(log.single.method, 'PATCH');
      final sent = jsonDecode(log.single.body) as List;
      expect(sent[0], {
        'op': 'replace',
        'path': '/title',
        'value': 'Postgres (prod)',
      });
      expect(sent[1], {'op': 'remove', 'path': '/fields/host-field'});
    });

    test('delete tolerates 204 with empty body', () async {
      final op = clientWith((_) => http.Response('', 204));
      await op.items.delete('vault1', 'item1');
    });
  });

  group('FilesApi', () {
    test('list requests inline content when asked', () async {
      final log = <RecordedRequest>[];
      final op = clientWith(log: log, (_) => jsonResponse([]));
      await op.files.list('vault1', 'item1', inline: true);
      expect(log.single.url.queryParameters['inline_files'], 'true');
    });

    test('content returns raw bytes', () async {
      final op = clientWith((_) => http.Response('raw-bytes', 200));
      final bytes = await op.files.content('vault1', 'item1', 'file1');
      expect(utf8.decode(bytes), 'raw-bytes');
    });
  });

  group('ServerApi', () {
    test('health decodes the JSON report', () async {
      final op = clientWith((_) =>
          jsonResponse({'name': '1Password Connect API', 'version': '1.7.3'}));
      final health = await op.server.health();
      expect(health['version'], '1.7.3');
    });

    test('activity passes paging parameters', () async {
      final log = <RecordedRequest>[];
      final op = clientWith(log: log, (_) => jsonResponse([]));
      await op.server.activity(limit: 10, offset: 20);
      expect(log.single.url.queryParameters, {'limit': '10', 'offset': '20'});
    });
  });

  group('error mapping', () {
    for (final (status, matcher) in [
      (401, isA<AuthenticationException>()),
      (403, isA<AuthorizationException>()),
      (404, isA<NotFoundException>()),
      (429, isA<RateLimitException>()),
      (500, isA<ServerException>()),
    ]) {
      test('HTTP $status becomes a typed exception', () {
        final op = clientWith((_) => errorResponse(status, 'nope'));
        expect(op.vaults.list(), throwsA(matcher));
      });
    }

    test('non-JSON error body still throws with generic message', () async {
      final op =
          clientWith((_) => http.Response('<html>bad gateway</html>', 502));
      await expectLater(
        op.vaults.list(),
        throwsA(isA<ServerException>()
            .having((e) => e.message, 'message', 'HTTP 502')),
      );
    });

    test('server message is surfaced', () async {
      final op = clientWith((_) => errorResponse(401, 'Invalid bearer token'));
      await expectLater(
        op.vaults.list(),
        throwsA(isA<AuthenticationException>()
            .having((e) => e.message, 'message', 'Invalid bearer token')),
      );
    });
  });

  group('base URL handling', () {
    test('path prefix on the server URL is preserved', () async {
      final log = <RecordedRequest>[];
      final op = clientWith(
        log: log,
        serverUrl: 'https://intranet.example.com/op-connect/',
        (_) => jsonResponse([]),
      );
      await op.vaults.list();
      expect(log.single.url.path, '/op-connect/v1/vaults');
    });
  });
}
