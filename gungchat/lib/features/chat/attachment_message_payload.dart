import 'dart:convert';
import 'dart:typed_data';

import '../../models/message.dart';

class TransportAttachment {
  const TransportAttachment({
    required this.id,
    required this.type,
    required this.displayName,
    this.mimeType,
    this.sizeBytes,
    this.metadata = const <String, Object?>{},
    this.bytes,
  });

  final String id;
  final AttachmentType type;
  final String displayName;
  final String? mimeType;
  final int? sizeBytes;
  final Map<String, Object?> metadata;
  final Uint8List? bytes;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'type': type.name,
      'displayName': displayName,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'metadata': metadata,
      'data': bytes == null ? null : base64Encode(bytes!),
    };
  }

  factory TransportAttachment.fromJson(Map<String, dynamic> json) {
    return TransportAttachment(
      id: json['id'] as String,
      type: AttachmentType.values.byName(json['type'] as String),
      displayName: json['displayName'] as String? ?? '',
      mimeType: json['mimeType'] as String?,
      sizeBytes: json['sizeBytes'] as int?,
      metadata: Map<String, Object?>.from(
        json['metadata'] as Map? ?? const <String, Object?>{},
      ),
      bytes: json['data'] == null
          ? null
          : Uint8List.fromList(base64Decode(json['data'] as String)),
    );
  }
}

class AttachmentMessagePayload {
  const AttachmentMessagePayload({
    required this.messageType,
    required this.attachments,
  });

  static const String _attachmentMarkerKey = '_gc_attachment_message';

  final MessageType messageType;
  final List<TransportAttachment> attachments;

  String encodeTransportString() {
    return jsonEncode(<String, Object?>{
      _attachmentMarkerKey: true,
      'messageType': messageType.name,
      'attachments': attachments
          .map((attachment) => attachment.toJson())
          .toList(growable: false),
    });
  }

  static AttachmentMessagePayload? tryDecodeTransportString(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic> ||
          decoded[_attachmentMarkerKey] != true) {
        return null;
      }

      final attachments = (decoded['attachments'] as List<dynamic>? ?? const [])
          .map(
            (entry) => TransportAttachment.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(growable: false);

      return AttachmentMessagePayload(
        messageType: MessageType.values.byName(
          decoded['messageType'] as String? ?? MessageType.multiAttachment.name,
        ),
        attachments: attachments,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}