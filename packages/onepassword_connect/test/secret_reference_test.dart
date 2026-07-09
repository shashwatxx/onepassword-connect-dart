import 'package:onepassword_connect/onepassword_connect.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('SecretReference.parse', () {
    test('parses vault/item/field', () {
      final ref = SecretReference.parse('op://App Secrets/Postgres/password');
      expect(ref.vault, 'App Secrets');
      expect(ref.item, 'Postgres');
      expect(ref.section, isNull);
      expect(ref.field, 'password');
    });

    test('parses vault/item/section/field', () {
      final ref =
          SecretReference.parse('op://App Secrets/Postgres/Credentials/host');
      expect(ref.section, 'Credentials');
      expect(ref.field, 'host');
    });

    test('decodes percent-encoded segments', () {
      final ref = SecretReference.parse('op://My%20Vault/it%2Fem/field');
      expect(ref.vault, 'My Vault');
      expect(ref.item, 'it/em');
    });

    test('parses the attribute query', () {
      final ref = SecretReference.parse(
          'op://vault/item/one-time password?attribute=otp');
      expect(ref.field, 'one-time password');
      expect(ref.attribute, 'otp');
    });

    for (final bad in [
      'op://vault/item', // too few segments
      'op://vault/item/a/b/c', // too many segments
      'op://vault//field', // empty segment
      'https://vault/item/field', // wrong scheme
      'op://', // nothing at all
    ]) {
      test('rejects "$bad"', () {
        expect(() => SecretReference.parse(bad),
            throwsA(isA<SecretReferenceException>()));
      });
    }

    test('round-trips through toString', () {
      final ref = SecretReference.parse('op://My Vault/Postgres/password');
      expect(SecretReference.parse(ref.toString()).vault, 'My Vault');
    });
  });

  group('OnePasswordConnect.resolve', () {
    OnePasswordConnect fakeServer({List<RecordedRequest>? log}) =>
        clientWith(log: log, (request) {
          final path = request.url.path;
          if (path == '/v1/vaults') return jsonResponse([vaultJson]);
          if (path == '/v1/vaults/ytrfte14kw1uex5txaore1emkz/items') {
            final filter = request.url.queryParameters['filter'];
            return jsonResponse(
                filter == 'title eq "Postgres"' ? [itemSummaryJson] : []);
          }
          if (path ==
              '/v1/vaults/ytrfte14kw1uex5txaore1emkz/items/2fcbqwe9ndg175zg2dzwftvkpa') {
            return jsonResponse(fullItemJson);
          }
          return errorResponse(404, 'not found: $path');
        });

    test('resolves by titles', () async {
      final op = fakeServer();
      expect(await op.resolve('op://App Secrets/Postgres/password'), 's3cr3t!');
    });

    test('vault title matching is case-insensitive', () async {
      final op = fakeServer();
      expect(await op.resolve('op://app secrets/Postgres/username'), 'admin');
    });

    test('resolves section-scoped fields', () async {
      final op = fakeServer();
      expect(
        await op.resolve('op://App Secrets/Postgres/Credentials/host'),
        'db.internal',
      );
    });

    test('field lookup outside the named section fails', () async {
      final op = fakeServer();
      expect(
        op.resolve('op://App Secrets/Postgres/Credentials/password'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('attribute=otp returns the current TOTP', () async {
      final op = fakeServer();
      expect(
        await op.resolve(
            'op://App Secrets/Postgres/one-time password?attribute=otp'),
        '123456',
      );
    });

    test('resolves by IDs', () async {
      final op = fakeServer();
      expect(
        await op.resolve(
            'op://ytrfte14kw1uex5txaore1emkz/2fcbqwe9ndg175zg2dzwftvkpa/password-field'),
        's3cr3t!',
      );
    });

    test('unknown vault throws NotFoundException', () async {
      final op = fakeServer();
      expect(op.resolve('op://Nope/Postgres/password'),
          throwsA(isA<NotFoundException>()));
    });

    test('unknown field names the item in the error', () async {
      final op = fakeServer();
      await expectLater(
        op.resolve('op://App Secrets/Postgres/nonexistent'),
        throwsA(isA<NotFoundException>()
            .having((e) => e.message, 'message', contains('Postgres'))),
      );
    });
  });
}
