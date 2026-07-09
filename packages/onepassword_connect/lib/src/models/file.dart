import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'item.dart';

/// A file attached to a 1Password item.
@immutable
class ItemFile {
  /// Creates a file.
  const ItemFile({
    required this.id,
    required this.name,
    this.size,
    this.contentPath,
    this.section,
    this.content,
  });

  /// Decodes a file from Connect API JSON.
  factory ItemFile.fromJson(Map<String, dynamic> json) => ItemFile(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        size: json['size'] as int?,
        contentPath: json['content_path'] as String?,
        section: json['section'] == null
            ? null
            : SectionRef.fromJson(json['section'] as Map<String, dynamic>),
        content: json['content'] as String?,
      );

  /// Unique file identifier.
  final String id;

  /// File name.
  final String name;

  /// File size in bytes.
  final int? size;

  /// API path to download the file's content.
  final String? contentPath;

  /// Section the file belongs to.
  final SectionRef? section;

  /// Base64-encoded content, present only when requested inline and the file
  /// is under the server's inline size threshold.
  final String? content;

  /// Decoded [content] bytes, or null when content was not returned inline.
  Uint8List? get contentBytes =>
      content == null ? null : base64.decode(content!);

  /// Encodes this file as JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (size != null) 'size': size,
        if (contentPath != null) 'content_path': contentPath,
        if (section != null) 'section': section!.toJson(),
        if (content != null) 'content': content,
      };

  @override
  String toString() => 'ItemFile($id, $name, ${size ?? '?'} bytes)';
}
