import 'dart:convert';

import 'package:onepassword_connect/onepassword_connect.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  test('Vault decodes all documented properties', () {
    final vault = Vault.fromJson(vaultJson);
    expect(vault.id, 'ytrfte14kw1uex5txaore1emkz');
    expect(vault.name, 'App Secrets');
    expect(vault.attributeVersion, 1);
    expect(vault.contentVersion, 9);
    expect(vault.items, 2);
    expect(vault.type, 'USER_CREATED');
    expect(vault.createdAt, DateTime.utc(2023, 3, 22, 15, 54, 35));
  });

  test('full Item decodes sections, fields, and files', () {
    final item = Item.fromJson(fullItemJson);
    expect(item.id, '2fcbqwe9ndg175zg2dzwftvkpa');
    expect(item.category, ItemCategory.database);
    expect(item.sections.single.label, 'Credentials');
    expect(item.fields, hasLength(4));
    expect(item.username?.value, 'admin');
    expect(item.password?.value, 's3cr3t!');
    expect(item.password?.entropy, 130.5);
    expect(item.files.single.name, 'ca.pem');

    final otp = item.fields.firstWhere((f) => f.type == FieldType.otp);
    expect(otp.totp, '123456');
    expect(otp.section?.id, 'section1');
  });

  test('item summary decodes with empty collections', () {
    final item = Item.fromJson(itemSummaryJson);
    expect(item.fields, isEmpty);
    expect(item.sections, isEmpty);
    expect(item.files, isEmpty);
    expect(item.username, isNull);
  });

  test('unknown category and field type fall back safely', () {
    final item = Item.fromJson({
      ...itemSummaryJson,
      'category': 'SOMETHING_NEW',
      'fields': [
        {'id': 'f', 'type': 'HOLOGRAM', 'value': 'x'},
      ],
    });
    expect(item.category, ItemCategory.custom);
    expect(item.fields.single.type, FieldType.unknown);
  });

  test('Item.toJson emits only writable properties', () {
    final item = Item(
      title: 'GitHub',
      vault: const VaultRef('vault1'),
      category: ItemCategory.login,
      fields: const [
        ItemField.username('octocat'),
        ItemField.password(null, generate: true),
      ],
      tags: const ['ci'],
    );
    final json = item.toJson();
    expect(json, isNot(contains('id')));
    expect(json['category'], 'LOGIN');
    expect(json['tags'], ['ci']);
    final fields = json['fields'] as List;
    expect((fields[0] as Map)['purpose'], 'USERNAME');
    expect((fields[1] as Map)['generate'], true);
    expect((fields[1] as Map), isNot(contains('value')));
    // Whole thing must be JSON-encodable.
    expect(() => jsonEncode(json), returnsNormally);
  });

  test('ItemFile decodes inline content to bytes', () {
    final file = ItemFile.fromJson({
      'id': 'file1',
      'name': 'hello.txt',
      'size': 5,
      'content': base64.encode(utf8.encode('hello')),
    });
    expect(utf8.decode(file.contentBytes!), 'hello');
  });

  test('ApiRequest decodes actor and resource', () {
    final entry = ApiRequest.fromJson({
      'requestId': 'req1',
      'timestamp': '2023-03-22T15:54:35Z',
      'action': 'READ',
      'result': 'SUCCESS',
      'actor': {'id': 'token1', 'requestIp': '10.0.0.1'},
      'resource': {
        'type': 'ITEM',
        'vault': {'id': 'vault1'},
        'item': {'id': 'item1'},
        'itemVersion': 2,
      },
    });
    expect(entry.action, 'READ');
    expect(entry.actor?.requestIp, '10.0.0.1');
    expect(entry.resource?.itemId, 'item1');
    expect(entry.resource?.itemVersion, 2);
  });
}
