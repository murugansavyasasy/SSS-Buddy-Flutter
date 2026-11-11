import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../Values/Colors/app_colors.dart';
import '../../auth/model/ChatModels.dart';
import '../../core/chat/chat_notification_service.dart';
import '../../core/chat/chat_service.dart';
import '../../viewModel/chat_viewmodel.dart';
import 'widget/chat_common.dart';
import 'widget/chat_input_bar.dart';
import 'widget/message_bubble.dart';

class ChatRoomView extends ConsumerStatefulWidget {
  final String chatId;

  const ChatRoomView({super.key, required this.chatId});

  @override
  ConsumerState<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends ConsumerState<ChatRoomView> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ChatNotificationService.instance.activeChatId = widget.chatId;
  }

  @override
  void dispose() {
    final n = ChatNotificationService.instance;
    if (n.activeChatId == widget.chatId) n.activeChatId = null;
    super.dispose();
  }

  ChatMe? get _me => ref.read(chatSessionProvider).value;

  ChatThread? get _thread => ref.read(chatThreadProvider(widget.chatId)).value;

  Future<void> _send(ChatMessage Function(ChatMe me) build) async {
    final me = _me;
    final thread = _thread;
    if (me == null || thread == null) return;
    try {
      await ChatService.instance.send(thread, build(me));
    } catch (e) {
      _toast('Message not sent. Check your connection.');
    }
  }

  Future<void> _sendText(String text) => _send((me) => ChatMessage(
        senderId: me.id,
        senderName: me.name,
        type: ChatMessageType.text,
        text: text,
        sentAt: DateTime.now().millisecondsSinceEpoch,
      ));

  Future<void> _uploadAndSend({
    required File file,
    required String fileName,
    required ChatMessageType type,
    String? contentType,
    int? durationMs,
  }) async {
    setState(() => _busy = true);
    try {
      final size = await file.length();
      if (size > 20 * 1024 * 1024) {
        _toast('File is larger than 20 MB');
        return;
      }
      final url = await ChatService.instance.uploadMedia(
        chatId: widget.chatId,
        file: file,
        fileName: fileName,
        contentType: contentType,
      );
      await _send((me) => ChatMessage(
            senderId: me.id,
            senderName: me.name,
            type: type,
            mediaUrl: url,
            fileName: fileName,
            fileSize: size,
            durationMs: durationMs,
            sentAt: DateTime.now().millisecondsSinceEpoch,
          ));
    } catch (e) {
      _toast('Upload failed. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendVoice(String path, int durationMs) => _uploadAndSend(
        file: File(path),
        fileName: path.split('/').last,
        type: ChatMessageType.voice,
        contentType: 'audio/mp4',
        durationMs: durationMs,
      );

  Future<void> _attach(ChatAttachment type) async {
    if (type == ChatAttachment.document) {
      final result = await FilePicker.pickFiles();
      if (result.isEmpty || result.first.path == null) return;
      final f = result.first;
      await _uploadAndSend(
        file: File(f.path!),
        fileName: f.name,
        type: ChatMessageType.file,
      );
      return;
    }
    final picked = await ImagePicker().pickImage(
      source: type == ChatAttachment.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (picked == null) return;
    await _uploadAndSend(
      file: File(picked.path),
      fileName: picked.name,
      type: ChatMessageType.image,
      contentType: 'image/jpeg',
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(chatSessionProvider).value;
    final threadAsync = ref.watch(chatThreadProvider(widget.chatId));
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));

    // Clear my unread count whenever it goes up while this screen is open.
    ref.listen(chatThreadProvider(widget.chatId), (_, next) {
      final t = next.value;
      if (me != null && t != null && t.unreadFor(me.id) > 0) {
        ChatService.instance.markRead(t.id, me.id);
      }
    });

    final thread = threadAsync.value;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            _header(context, me, thread),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F3F8),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: messagesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (messages) => _messageList(messages, me, thread),
                ),
              ),
            ),
            ChatInputBar(
              busy: _busy,
              onSendText: _sendText,
              onSendVoice: _sendVoice,
              onAttach: _attach,
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, ChatMe? me, ChatThread? thread) {
    final title = (me != null && thread != null) ? thread.displayTitle(me.id) : '';
    final subtitle = thread == null
        ? ''
        : thread.isGroup
            ? '${thread.members.length} members'
            : 'Direct message';
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 16, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 42,
              width: 42,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ChatAvatar(
              name: title,
              isGroup: thread?.isGroup ?? false,
              size: 40,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (thread?.isGroup ?? false)
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: () => _showMembers(thread!),
            ),
        ],
      ),
    );
  }

  void _showMembers(ChatThread thread) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                '${thread.members.length} members',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            for (final id in thread.members)
              ListTile(
                leading: ChatAvatar(name: thread.names[id] ?? '', size: 38),
                title: Text(thread.names[id] ?? id),
              ),
          ],
        ),
      ),
    );
  }

  Widget _messageList(List<ChatMessage> messages, ChatMe? me, ChatThread? thread) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              'Say hello 👋',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ],
        ),
      );
    }

    // messages are newest first; list is reversed so newest sits at bottom.
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final m = messages[i];
        final older = i + 1 < messages.length ? messages[i + 1] : null;
        final newDay = older == null || !chatIsSameDay(older.time, m.time);
        final senderChanged = older == null || older.senderId != m.senderId || newDay;
        final isMine = m.senderId == me?.id;

        return Column(
          children: [
            if (newDay) _dayChip(m.time),
            Padding(
              padding: EdgeInsets.only(top: senderChanged ? 6 : 0),
              child: MessageBubble(
                message: m,
                isMine: isMine,
                showSender: (thread?.isGroup ?? false) && senderChanged,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _dayChip(DateTime t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          chatDayLabel(t),
          style: const TextStyle(fontSize: 11.5, color: Colors.black54),
        ),
      ),
    );
  }
}
