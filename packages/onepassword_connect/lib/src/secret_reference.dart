import 'package:meta/meta.dart';

import 'errors.dart';

/// A parsed `op://` secret reference.
///
/// Format: `op://<vault>/<item>/[<section>/]<field>[?attribute=otp]`, where
/// each segment is a title or ID and may be percent-encoded.
@immutable
class SecretReference {
  /// Creates a reference from its parts.
  const SecretReference({
    required this.vault,
    required this.item,
    this.section,
    required this.field,
    this.attribute,
  });

  /// Parses [reference], throwing [SecretReferenceException] when malformed.
  factory SecretReference.parse(String reference) {
    if (!reference.startsWith(_scheme)) {
      throw SecretReferenceException(
          'Secret reference must start with "$_scheme": $reference');
    }
    final withoutScheme = reference.substring(_scheme.length);
    final queryStart = withoutScheme.indexOf('?');
    final path = queryStart == -1
        ? withoutScheme
        : withoutScheme.substring(0, queryStart);
    final query =
        queryStart == -1 ? '' : withoutScheme.substring(queryStart + 1);

    final segments =
        path.split('/').map(Uri.decodeComponent).map((s) => s.trim()).toList();
    if (segments.length < 3 ||
        segments.length > 4 ||
        segments.any((s) => s.isEmpty)) {
      throw SecretReferenceException(
          'Expected op://<vault>/<item>/[<section>/]<field>, got: $reference');
    }

    String? attribute;
    if (query.isNotEmpty) {
      final params = Uri.splitQueryString(query);
      attribute = params['attribute'];
    }

    return SecretReference(
      vault: segments[0],
      item: segments[1],
      section: segments.length == 4 ? segments[2] : null,
      field: segments.last,
      attribute: attribute,
    );
  }

  static const _scheme = 'op://';

  /// Vault title or ID.
  final String vault;

  /// Item title or ID.
  final String item;

  /// Optional section label or ID scoping the field lookup.
  final String? section;

  /// Field label or ID.
  final String field;

  /// Optional attribute selector (e.g. `otp` to read the current TOTP).
  final String? attribute;

  @override
  String toString() {
    final sectionPart =
        section == null ? '' : '${Uri.encodeComponent(section!)}/';
    final attributePart = attribute == null ? '' : '?attribute=$attribute';
    return '$_scheme${Uri.encodeComponent(vault)}/${Uri.encodeComponent(item)}/'
        '$sectionPart${Uri.encodeComponent(field)}$attributePart';
  }
}
