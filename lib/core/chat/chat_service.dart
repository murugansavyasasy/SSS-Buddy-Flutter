import 'dart:async';
import 'dart:io';

import '../../auth/model/ChatModels.dart';

/// Chat backend — LOCAL DEMO MODE.
///
/// The real backend (company REST API + socket, or Firebase) is not decided
/// yet. Until then this keeps everything in memory with hard-coded sample
/// conversations so the chat design can be reviewed end to end:
///   * sending appends to the in-memory list (lost on app restart)
///   * direct chats with sample colleagues auto-reply after ~2 seconds
///   * photos / voice notes / documents stay as local file paths
///
/// To go live, replace the bodies of these methods with API / Firebase calls;
/// the screens and view models do not need to change.
/// userId is the backend login userId (same as Reportingmembersmodel.idmember).
class ChatService {
  ChatService._();

  static final ChatService instance = ChatService._();

  bool get isReady => true;

  ChatMe? _me;
  final Map<String, ChatThread> _threads = {};
  final Map<String, List<ChatMessage>> _messages = {};
  final _changes = StreamController<void>.broadcast();

  static const _sampleColleagues = [
    ChatContact(id: 'demo_ravi', name: 'Ravi Kumar', role: 'Sales Executive'),
    ChatContact(id: 'demo_priya', name: 'Priya Lakshmi', role: 'Sales Executive'),
    ChatContact(id: 'demo_arun', name: 'Arun Prakash', role: 'Regional Manager'),
    ChatContact(id: 'demo_divya', name: 'Divya S', role: 'Support'),
    ChatContact(id: 'demo_karthik', name: 'Karthik Raja', role: 'Accounts'),
  ];

  static const _autoReplies = [
    'Okay, noted 👍',
    'Sure, will update you by evening.',
    'Principal asked for the revised quote. Sending shortly.',
    'Reached the school, meeting in 10 mins.',
    'Thanks! 🙏',
  ];
  int _replyIndex = 0;

  void _notify() => _changes.add(null);

  // ----------------------------------------------------------------- session

  Future<void> connect(ChatMe me) async {
    if (_me?.id == me.id) return;
    _me = me;
    _threads.clear();
    _messages.clear();
    _seed(me);
    _notify();
  }

  // ---------------------------------------------------------------- threads

  Stream<List<ChatThread>> threads(String myId) async* {
    yield _threadList(myId);
    yield* _changes.stream.map((_) => _threadList(myId));
  }

  List<ChatThread> _threadList(String myId) {
    final list = _threads.values.where((t) => t.members.contains(myId)).toList()
      ..sort((a, b) => b.lastSentAt.compareTo(a.lastSentAt));
    return list;
  }

  Stream<ChatThread?> thread(String chatId) async* {
    yield _threads[chatId];
    yield* _changes.stream.map((_) => _threads[chatId]);
  }

  static String directChatId(String a, String b) {
    final ids = [a, b]..sort();
    return 'd_${ids[0]}_${ids[1]}';
  }

  Future<String> ensureDirectChat(ChatMe me, ChatContact other) async {
    final id = directChatId(me.id, other.id);
    _threads.putIfAbsent(
      id,
      () => _thread(
        id: id,
        type: ChatThreadType.direct,
        members: [me.id, other.id],
        names: {me.id: me.name, other.id: other.name},
      ),
    );
    _messages.putIfAbsent(id, () => []);
    _notify();
    return id;
  }

  /// One group per manager: the manager plus everyone reporting to them.
  Future<void> syncTeamGroup(ChatMe manager, List<ChatContact> team) async {
    if (team.isEmpty) return;
    final id = 'team_${manager.id}';
    final members = <String>{manager.id, ...team.map((c) => c.id)}.toList();
    final names = {manager.id: manager.name, for (final c in team) c.id: c.name};
    final existing = _threads[id];
    if (existing == null) {
      _threads[id] = _thread(
        id: id,
        type: ChatThreadType.group,
        title: "${manager.name.split(' ').first}'s Team",
        members: members,
        names: names,
      );
      _messages[id] = [];
      // A first message so the group isn't empty in the demo.
      final first = team.first;
      _append(
        _threads[id]!,
        ChatMessage(
          senderId: first.id,
          senderName: first.name,
          type: ChatMessageType.text,
          text: 'Good morning team! Sharing today\'s visit plan shortly.',
          sentAt: DateTime.now()
              .subtract(const Duration(minutes: 40))
              .millisecondsSinceEpoch,
        ),
        bumpUnread: true,
      );
    } else {
      _threads[id] = _copy(existing, members: members, names: names);
    }
    _notify();
  }

  // --------------------------------------------------------------- messages

  Stream<List<ChatMessage>> messages(String chatId, {int limit = 200}) async* {
    List<ChatMessage> current() {
      final list = [...(_messages[chatId] ?? const <ChatMessage>[])]
        ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
      return list.take(limit).toList();
    }

    yield current();
    yield* _changes.stream.map((_) => current());
  }

  Future<void> send(ChatThread thread, ChatMessage msg) async {
    final t = _threads[thread.id] ?? thread;
    _append(t, msg, bumpUnread: true);
    _notify();
    _maybeAutoReply(t, msg);
  }

  Future<void> markRead(String chatId, String myId) async {
    final t = _threads[chatId];
    if (t == null || t.unreadFor(myId) == 0) return;
    _threads[chatId] = _copy(t, unread: {...t.unread, myId: 0});
    _notify();
  }

  /// Local demo: no upload, the message keeps the on-device path.
  Future<String> uploadMedia({
    required String chatId,
    required File file,
    required String fileName,
    String? contentType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return file.path;
  }

  Future<List<ChatContact>> registeredUsers() async => _sampleColleagues;

  // ---------------------------------------------------------------- helpers

  void _append(ChatThread t, ChatMessage msg, {required bool bumpUnread}) {
    final stored = ChatMessage(
      id: '${msg.sentAt}_${_messages[t.id]?.length ?? 0}',
      senderId: msg.senderId,
      senderName: msg.senderName,
      type: msg.type,
      text: msg.text,
      mediaUrl: msg.mediaUrl,
      fileName: msg.fileName,
      fileSize: msg.fileSize,
      durationMs: msg.durationMs,
      sentAt: msg.sentAt,
    );
    (_messages[t.id] ??= []).add(stored);
    final unread = {...t.unread};
    if (bumpUnread) {
      for (final m in t.members) {
        if (m != msg.senderId) unread[m] = (unread[m] ?? 0) + 1;
      }
    }
    _threads[t.id] = ChatThread(
      id: t.id,
      type: t.type,
      title: t.title,
      members: t.members,
      names: t.names,
      lastText: msg.type == ChatMessageType.file ? (msg.fileName ?? '') : msg.text,
      lastType: msg.type,
      lastSenderId: msg.senderId,
      lastSenderName: msg.senderName,
      lastSentAt: msg.sentAt,
      unread: unread,
    );
  }

  void _maybeAutoReply(ChatThread t, ChatMessage sent) {
    final me = _me;
    if (me == null || t.isGroup || sent.senderId != me.id) return;
    final otherId = t.members.firstWhere((m) => m != me.id, orElse: () => '');
    if (!otherId.startsWith('demo_')) return;
    final text = _autoReplies[_replyIndex++ % _autoReplies.length];
    Timer(const Duration(seconds: 2), () {
      final current = _threads[t.id];
      if (current == null) return;
      _append(
        current,
        ChatMessage(
          senderId: otherId,
          senderName: t.names[otherId] ?? '',
          type: ChatMessageType.text,
          text: text,
          sentAt: DateTime.now().millisecondsSinceEpoch,
        ),
        bumpUnread: true,
      );
      _notify();
    });
  }

  ChatThread _thread({
    required String id,
    required ChatThreadType type,
    String title = '',
    required List<String> members,
    required Map<String, String> names,
  }) =>
      ChatThread(
        id: id,
        type: type,
        title: title,
        members: members,
        names: names,
        lastText: '',
        lastType: ChatMessageType.text,
        lastSenderId: '',
        lastSenderName: '',
        lastSentAt: 0,
        unread: {for (final m in members) m: 0},
      );

  ChatThread _copy(
    ChatThread t, {
    List<String>? members,
    Map<String, String>? names,
    Map<String, int>? unread,
  }) =>
      ChatThread(
        id: t.id,
        type: t.type,
        title: t.title,
        members: members ?? t.members,
        names: names ?? t.names,
        lastText: t.lastText,
        lastType: t.lastType,
        lastSenderId: t.lastSenderId,
        lastSenderName: t.lastSenderName,
        lastSentAt: t.lastSentAt,
        unread: unread ?? t.unread,
      );

  /// Hard-coded sample conversations for the design review.
  void _seed(ChatMe me) {
    final now = DateTime.now();
    int ago({int days = 0, int hours = 0, int minutes = 0}) => now
        .subtract(Duration(days: days, hours: hours, minutes: minutes))
        .millisecondsSinceEpoch;

    ChatContact c(String id) => _sampleColleagues.firstWhere((x) => x.id == id);

    void conversation(ChatContact other, List<(bool, ChatMessage Function(String, String))> msgs,
        {int unread = 0}) {
      final id = directChatId(me.id, other.id);
      _threads[id] = _thread(
        id: id,
        type: ChatThreadType.direct,
        members: [me.id, other.id],
        names: {me.id: me.name, other.id: other.name},
      );
      _messages[id] = [];
      for (final (mine, build) in msgs) {
        final m = mine ? build(me.id, me.name) : build(other.id, other.name);
        _append(_threads[id]!, m, bumpUnread: false);
      }
      _threads[id] = _copy(_threads[id]!, unread: {me.id: unread, other.id: 0});
    }

    // Builders take (senderId, senderName) so each side is filled in per message.
    ChatMessage Function(String, String) t(String s, int at) =>
        (id, name) => ChatMessage(
              senderId: id,
              senderName: name,
              type: ChatMessageType.text,
              text: s,
              sentAt: at,
            );
    ChatMessage Function(String, String) img(String url, int at) =>
        (id, name) => ChatMessage(
              senderId: id,
              senderName: name,
              type: ChatMessageType.image,
              mediaUrl: url,
              fileName: 'photo.jpg',
              sentAt: at,
            );
    ChatMessage Function(String, String) doc(String name, String url, int size, int at) =>
        (id, sender) => ChatMessage(
              senderId: id,
              senderName: sender,
              type: ChatMessageType.file,
              mediaUrl: url,
              fileName: name,
              fileSize: size,
              sentAt: at,
            );
    conversation(c('demo_arun'), [
      (false, t('Hi, how was the demo at Green Valley School?', ago(days: 1, hours: 3))),
      (true, t('Went well sir. Principal liked the attendance + SMS module.', ago(days: 1, hours: 2, minutes: 50))),
      (true, t('They want a quote for 1,200 students.', ago(days: 1, hours: 2, minutes: 49))),
      (false, t('Good. Send the quote today and set a follow-up for Friday.', ago(days: 1, hours: 2, minutes: 30))),
      (false, t('Also update the status report before 6 PM.', ago(hours: 1, minutes: 5))),
    ], unread: 1);

    conversation(c('demo_ravi'), [
      (false, t('Bro, do you have the latest brochure PDF?', ago(hours: 5))),
      (true, doc('SSS_Brochure_2026.pdf',
          'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          245000, ago(hours: 4, minutes: 55))),
      (false, t('Got it, thanks!', ago(hours: 4, minutes: 50))),
      (false, img('https://picsum.photos/id/1068/800/600', ago(minutes: 25))),
      (false, t('St. Mary\'s school entrance — reached for the visit 😊', ago(minutes: 24))),
    ], unread: 2);

    conversation(c('demo_priya'), [
      (true, t('Priya, payment from Sunrise Matric came?', ago(days: 3, hours: 2))),
      (false, t('Yes, ₹45,000 received via NEFT. Recorded in collection.', ago(days: 3, hours: 1))),
      (true, t('Super 👍', ago(days: 3))),
    ]);

    conversation(c('demo_divya'), [
      (false, t('Login issue at Bharathi Vidyalaya fixed. Please inform the admin.', ago(days: 8))),
      (true, t('Done, informed. Thanks Divya.', ago(days: 8))),
    ]);
  }
}
