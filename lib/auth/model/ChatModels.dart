/// The logged-in user as seen by the chat module.
/// [id] is the backend userId (same value as Reportingmembersmodel.idmember).
class ChatMe {
  final String id;
  final String name;
  final String role;

  const ChatMe({required this.id, required this.name, required this.role});
}

class ChatContact {
  final String id;
  final String name;
  final String role;
  final bool isTeamMember;

  const ChatContact({
    required this.id,
    required this.name,
    this.role = '',
    this.isTeamMember = false,
  });
}

enum ChatThreadType { direct, group }

enum ChatMessageType { text, image, voice, file }

ChatMessageType chatMessageTypeFrom(String? v) => ChatMessageType.values
    .firstWhere((t) => t.name == v, orElse: () => ChatMessageType.text);

class ChatThread {
  final String id;
  final ChatThreadType type;
  final String title;
  final List<String> members;
  final Map<String, String> names;
  final String lastText;
  final ChatMessageType lastType;
  final String lastSenderId;
  final String lastSenderName;
  final int lastSentAt;
  final Map<String, int> unread;

  const ChatThread({
    required this.id,
    required this.type,
    required this.title,
    required this.members,
    required this.names,
    required this.lastText,
    required this.lastType,
    required this.lastSenderId,
    required this.lastSenderName,
    required this.lastSentAt,
    required this.unread,
  });

  bool get isGroup => type == ChatThreadType.group;

  String displayTitle(String myId) {
    if (isGroup) return title.isNotEmpty ? title : 'Group';
    final other = members.firstWhere((m) => m != myId, orElse: () => myId);
    return names[other] ?? 'Unknown';
  }

  int unreadFor(String myId) => unread[myId] ?? 0;

  String previewFor(String myId) {
    if (lastSentAt == 0) return 'No messages yet';
    final body = switch (lastType) {
      ChatMessageType.text => lastText,
      ChatMessageType.image => 'Photo',
      ChatMessageType.voice => 'Voice message',
      ChatMessageType.file => lastText.isNotEmpty ? lastText : 'Document',
    };
    if (lastSenderId == myId) return 'You: $body';
    if (isGroup && lastSenderName.isNotEmpty) {
      return '${lastSenderName.split(' ').first}: $body';
    }
    return body;
  }

  factory ChatThread.fromJson(String id, Map<String, dynamic> d) {
    final last = (d['lastMessage'] as Map?)?.cast<String, dynamic>() ?? {};
    return ChatThread(
      id: id,
      type: d['type'] == 'group' ? ChatThreadType.group : ChatThreadType.direct,
      title: d['title']?.toString() ?? '',
      members: List<String>.from(d['members'] ?? const []),
      names: (d['names'] as Map? ?? {})
          .map((k, v) => MapEntry(k.toString(), v.toString())),
      lastText: last['text']?.toString() ?? '',
      lastType: chatMessageTypeFrom(last['type']?.toString()),
      lastSenderId: last['senderId']?.toString() ?? '',
      lastSenderName: last['senderName']?.toString() ?? '',
      lastSentAt: (d['lastSentAt'] as num?)?.toInt() ?? 0,
      unread: (d['unread'] as Map? ?? {})
          .map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0)),
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final ChatMessageType type;
  final String text;
  final String? mediaUrl;
  final String? fileName;
  final int? fileSize;
  final int? durationMs;

  /// Client clock in ms. Used for ordering/display so a message shows
  /// immediately, before the server timestamp round-trips.
  final int sentAt;

  const ChatMessage({
    this.id = '',
    required this.senderId,
    required this.senderName,
    required this.type,
    this.text = '',
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.durationMs,
    required this.sentAt,
  });

  DateTime get time => DateTime.fromMillisecondsSinceEpoch(sentAt);

  factory ChatMessage.fromJson(String id, Map<String, dynamic> d) {
    return ChatMessage(
      id: id,
      senderId: d['senderId']?.toString() ?? '',
      senderName: d['senderName']?.toString() ?? '',
      type: chatMessageTypeFrom(d['type']?.toString()),
      text: d['text']?.toString() ?? '',
      mediaUrl: d['mediaUrl']?.toString(),
      fileName: d['fileName']?.toString(),
      fileSize: (d['fileSize'] as num?)?.toInt(),
      durationMs: (d['durationMs'] as num?)?.toInt(),
      sentAt: (d['sentAt'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'senderId': senderId,
        'senderName': senderName,
        'type': type.name,
        'text': text,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        if (fileName != null) 'fileName': fileName,
        if (fileSize != null) 'fileSize': fileSize,
        if (durationMs != null) 'durationMs': durationMs,
        'sentAt': sentAt,
      };
}
