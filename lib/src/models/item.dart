import 'package:meta/meta.dart';

import 'file.dart';

/// Item categories supported by the Connect API.
///
/// Note: items with the [custom] or [document] category cannot be *created*
/// through the Connect API, only read.
enum ItemCategory {
  login('LOGIN'),
  password('PASSWORD'),
  apiCredential('API_CREDENTIAL'),
  server('SERVER'),
  database('DATABASE'),
  creditCard('CREDIT_CARD'),
  membership('MEMBERSHIP'),
  passport('PASSPORT'),
  softwareLicense('SOFTWARE_LICENSE'),
  outdoorLicense('OUTDOOR_LICENSE'),
  secureNote('SECURE_NOTE'),
  wirelessRouter('WIRELESS_ROUTER'),
  bankAccount('BANK_ACCOUNT'),
  driverLicense('DRIVER_LICENSE'),
  identity('IDENTITY'),
  rewardProgram('REWARD_PROGRAM'),
  document('DOCUMENT'),
  emailAccount('EMAIL_ACCOUNT'),
  socialSecurityNumber('SOCIAL_SECURITY_NUMBER'),
  medicalRecord('MEDICAL_RECORD'),
  sshKey('SSH_KEY'),
  custom('CUSTOM');

  const ItemCategory(this.value);

  /// Wire value used by the API.
  final String value;

  /// Parses an API [value], falling back to [custom] for unknown categories.
  static ItemCategory fromValue(String? value) => ItemCategory.values
      .firstWhere((c) => c.value == value, orElse: () => ItemCategory.custom);
}

/// Field types supported by the Connect API.
enum FieldType {
  string('STRING'),
  email('EMAIL'),
  concealed('CONCEALED'),
  url('URL'),
  otp('OTP'),
  date('DATE'),
  monthYear('MONTH_YEAR'),
  menu('MENU'),
  phone('PHONE'),
  address('ADDRESS'),
  creditCardType('CREDIT_CARD_TYPE'),
  creditCardNumber('CREDIT_CARD_NUMBER'),
  reference('REFERENCE'),
  sshKey('SSHKEY'),
  gender('GENDER'),
  file('FILE'),
  unknown('UNKNOWN');

  const FieldType(this.value);

  /// Wire value used by the API.
  final String value;

  /// Parses an API [value], falling back to [unknown].
  static FieldType fromValue(String? value) => FieldType.values
      .firstWhere((t) => t.value == value, orElse: () => FieldType.unknown);
}

/// Special role a field plays on an item.
enum FieldPurpose {
  username('USERNAME'),
  password('PASSWORD'),
  notes('NOTES');

  const FieldPurpose(this.value);

  /// Wire value used by the API.
  final String value;

  /// Parses an API [value]; returns null for absent/unknown purposes.
  static FieldPurpose? fromValue(String? value) {
    for (final purpose in FieldPurpose.values) {
      if (purpose.value == value) return purpose;
    }
    return null;
  }
}

/// A reference to an [ItemSection] by ID.
@immutable
class SectionRef {
  /// Creates a section reference.
  const SectionRef(this.id);

  /// Decodes a section reference from JSON.
  factory SectionRef.fromJson(Map<String, dynamic> json) =>
      SectionRef(json['id'] as String);

  /// Section identifier.
  final String id;

  /// Encodes this reference as JSON.
  Map<String, dynamic> toJson() => {'id': id};
}

/// A named group of fields within an item.
@immutable
class ItemSection {
  /// Creates a section.
  const ItemSection({required this.id, this.label});

  /// Decodes a section from JSON.
  factory ItemSection.fromJson(Map<String, dynamic> json) =>
      ItemSection(id: json['id'] as String, label: json['label'] as String?);

  /// Section identifier, unique within the item.
  final String id;

  /// Human-readable section title.
  final String? label;

  /// Encodes this section as JSON.
  Map<String, dynamic> toJson() =>
      {'id': id, if (label != null) 'label': label};
}

/// Password generator recipe attached to a field with `generate: true`.
@immutable
class GeneratorRecipe {
  /// Creates a recipe.
  const GeneratorRecipe(
      {this.length, this.characterSets, this.excludeCharacters});

  /// Decodes a recipe from JSON.
  factory GeneratorRecipe.fromJson(Map<String, dynamic> json) =>
      GeneratorRecipe(
        length: json['length'] as int?,
        characterSets:
            (json['characterSets'] as List?)?.cast<String>().toList(),
        excludeCharacters: json['excludeCharacters'] as String?,
      );

  /// Desired password length (1–64).
  final int? length;

  /// Any of `LETTERS`, `DIGITS`, `SYMBOLS`.
  final List<String>? characterSets;

  /// Characters that must not appear in the generated value.
  final String? excludeCharacters;

  /// Encodes this recipe as JSON.
  Map<String, dynamic> toJson() => {
        if (length != null) 'length': length,
        if (characterSets != null) 'characterSets': characterSets,
        if (excludeCharacters != null) 'excludeCharacters': excludeCharacters,
      };
}

/// A single field on an item (username, password, OTP, custom field, …).
@immutable
class ItemField {
  /// Creates a field.
  const ItemField({
    this.id,
    this.type = FieldType.string,
    this.purpose,
    this.label,
    this.value,
    this.section,
    this.generate,
    this.recipe,
    this.entropy,
    this.totp,
  });

  /// Convenience constructor for a username field.
  const ItemField.username(String value)
      : this(purpose: FieldPurpose.username, value: value);

  /// Convenience constructor for a concealed password field.
  ///
  /// Pass a null [value] together with `generate: true` to have the server
  /// generate the password.
  const ItemField.password(String? value,
      {bool? generate, GeneratorRecipe? recipe})
      : this(
          type: FieldType.concealed,
          purpose: FieldPurpose.password,
          value: value,
          generate: generate,
          recipe: recipe,
        );

  /// Decodes a field from JSON.
  factory ItemField.fromJson(Map<String, dynamic> json) => ItemField(
        id: json['id'] as String?,
        type: FieldType.fromValue(json['type'] as String?),
        purpose: FieldPurpose.fromValue(json['purpose'] as String?),
        label: json['label'] as String?,
        value: json['value'] as String?,
        section: json['section'] == null
            ? null
            : SectionRef.fromJson(json['section'] as Map<String, dynamic>),
        generate: json['generate'] as bool?,
        recipe: json['recipe'] == null
            ? null
            : GeneratorRecipe.fromJson(json['recipe'] as Map<String, dynamic>),
        entropy: (json['entropy'] as num?)?.toDouble(),
        totp: json['totp'] as String?,
      );

  /// Field identifier, unique within the item.
  final String? id;

  /// Field type.
  final FieldType type;

  /// Special role of the field, if any.
  final FieldPurpose? purpose;

  /// Human-readable field label.
  final String? label;

  /// Field value. Null when the server generated it and it wasn't requested.
  final String? value;

  /// Section the field belongs to.
  final SectionRef? section;

  /// Whether the server should generate the value (create/replace only).
  final bool? generate;

  /// Recipe used when [generate] is true.
  final GeneratorRecipe? recipe;

  /// Entropy of a generated password.
  final double? entropy;

  /// Current one-time password, present on [FieldType.otp] fields.
  final String? totp;

  /// Encodes this field as JSON.
  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'type': type.value,
        if (purpose != null) 'purpose': purpose!.value,
        if (label != null) 'label': label,
        if (value != null) 'value': value,
        if (section != null) 'section': section!.toJson(),
        if (generate != null) 'generate': generate,
        if (recipe != null) 'recipe': recipe!.toJson(),
      };
}

/// A website URL attached to an item.
@immutable
class ItemUrl {
  /// Creates an item URL.
  const ItemUrl({required this.href, this.label, this.primary});

  /// Decodes an item URL from JSON.
  factory ItemUrl.fromJson(Map<String, dynamic> json) => ItemUrl(
        href: json['href'] as String,
        label: json['label'] as String?,
        primary: json['primary'] as bool?,
      );

  /// The address.
  final String href;

  /// Optional label shown in 1Password.
  final String? label;

  /// Whether this is the item's primary URL.
  final bool? primary;

  /// Encodes this URL as JSON.
  Map<String, dynamic> toJson() => {
        'href': href,
        if (label != null) 'label': label,
        if (primary != null) 'primary': primary,
      };
}

/// Reference to the vault an item belongs to.
@immutable
class VaultRef {
  /// Creates a vault reference.
  const VaultRef(this.id);

  /// Decodes a vault reference from JSON.
  factory VaultRef.fromJson(Map<String, dynamic> json) =>
      VaultRef(json['id'] as String);

  /// Vault identifier.
  final String id;

  /// Encodes this reference as JSON.
  Map<String, dynamic> toJson() => {'id': id};
}

/// A 1Password item.
///
/// List endpoints return summaries (no [fields], [sections], or [files]);
/// get/create/replace return the full item.
@immutable
class Item {
  /// Creates an item.
  const Item({
    this.id,
    required this.title,
    required this.vault,
    required this.category,
    this.urls = const [],
    this.favorite,
    this.tags = const [],
    this.version,
    this.state,
    this.sections = const [],
    this.fields = const [],
    this.files = const [],
    this.lastEditedBy,
    this.createdAt,
    this.updatedAt,
  });

  /// Decodes an item from Connect API JSON.
  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json['id'] as String?,
        title: json['title'] as String? ?? '',
        vault: VaultRef.fromJson(json['vault'] as Map<String, dynamic>),
        category: ItemCategory.fromValue(json['category'] as String?),
        urls: _list(json['urls'], ItemUrl.fromJson),
        favorite: json['favorite'] as bool?,
        tags: (json['tags'] as List?)?.cast<String>().toList() ?? const [],
        version: json['version'] as int?,
        state: json['state'] as String?,
        sections: _list(json['sections'], ItemSection.fromJson),
        fields: _list(json['fields'], ItemField.fromJson),
        files: _list(json['files'], ItemFile.fromJson),
        lastEditedBy: json['lastEditedBy'] as String?,
        createdAt: _dateTime(json['createdAt']),
        updatedAt: _dateTime(json['updatedAt']),
      );

  /// Unique item identifier. Null for items not yet created.
  final String? id;

  /// Item title.
  final String title;

  /// Vault the item belongs to.
  final VaultRef vault;

  /// Item category.
  final ItemCategory category;

  /// Website URLs.
  final List<ItemUrl> urls;

  /// Whether the item is marked as favorite.
  final bool? favorite;

  /// Tags on the item.
  final List<String> tags;

  /// Item content version.
  final int? version;

  /// `ARCHIVED` or `DELETED` for non-active items.
  final String? state;

  /// Field sections (full item only).
  final List<ItemSection> sections;

  /// Fields (full item only).
  final List<ItemField> fields;

  /// File attachments (full item only).
  final List<ItemFile> files;

  /// ID of the user who last edited the item.
  final String? lastEditedBy;

  /// When the item was created.
  final DateTime? createdAt;

  /// When the item was last updated.
  final DateTime? updatedAt;

  /// The field with the `USERNAME` purpose, if any.
  ItemField? get username => _byPurpose(FieldPurpose.username);

  /// The field with the `PASSWORD` purpose, if any.
  ItemField? get password => _byPurpose(FieldPurpose.password);

  /// The notes field, if any.
  ItemField? get notes => _byPurpose(FieldPurpose.notes);

  ItemField? _byPurpose(FieldPurpose purpose) {
    for (final field in fields) {
      if (field.purpose == purpose) return field;
    }
    return null;
  }

  /// Encodes this item as Connect API JSON (for create/replace).
  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'title': title,
        'vault': vault.toJson(),
        'category': category.value,
        if (urls.isNotEmpty) 'urls': urls.map((u) => u.toJson()).toList(),
        if (favorite != null) 'favorite': favorite,
        if (tags.isNotEmpty) 'tags': tags,
        if (sections.isNotEmpty)
          'sections': sections.map((s) => s.toJson()).toList(),
        if (fields.isNotEmpty) 'fields': fields.map((f) => f.toJson()).toList(),
      };

  @override
  String toString() => 'Item($id, $title, ${category.value})';
}

List<T> _list<T>(Object? value, T Function(Map<String, dynamic>) decode) =>
    (value as List?)?.map((e) => decode(e as Map<String, dynamic>)).toList() ??
    const [];

DateTime? _dateTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
