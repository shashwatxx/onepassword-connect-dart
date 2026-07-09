import 'package:meta/meta.dart';

/// A 1Password vault as returned by the Connect API.
@immutable
class Vault {
  /// Creates a vault.
  const Vault({
    required this.id,
    required this.name,
    this.description,
    this.attributeVersion,
    this.contentVersion,
    this.items,
    this.type,
    this.createdAt,
    this.updatedAt,
  });

  /// Decodes a vault from Connect API JSON.
  factory Vault.fromJson(Map<String, dynamic> json) => Vault(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        attributeVersion: json['attributeVersion'] as int?,
        contentVersion: json['contentVersion'] as int?,
        items: json['items'] as int?,
        type: json['type'] as String?,
        createdAt: _dateTime(json['createdAt']),
        updatedAt: _dateTime(json['updatedAt']),
      );

  /// Unique vault identifier (26-character ID).
  final String id;

  /// Vault title.
  final String name;

  /// Optional vault description.
  final String? description;

  /// Version of the vault metadata.
  final int? attributeVersion;

  /// Version of the vault contents.
  final int? contentVersion;

  /// Number of active items in the vault.
  final int? items;

  /// Vault type: `USER_CREATED`, `PERSONAL`, `EVERYONE`, or `TRANSFER`.
  final String? type;

  /// When the vault was created.
  final DateTime? createdAt;

  /// When the vault was last updated.
  final DateTime? updatedAt;

  /// Encodes this vault as Connect API JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        if (attributeVersion != null) 'attributeVersion': attributeVersion,
        if (contentVersion != null) 'contentVersion': contentVersion,
        if (items != null) 'items': items,
        if (type != null) 'type': type,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  @override
  String toString() => 'Vault($id, $name)';
}

DateTime? _dateTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
