import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../Values/Colors/app_colors.dart';
import 'chat_common.dart';

enum ChatAttachment { camera, gallery, document }

class ChatInputBar extends StatefulWidget {
  final Future<void> Function(String text) onSendText;
  final Future<void> Function(String path, int durationMs) onSendVoice;
  final void Function(ChatAttachment type) onAttach;
  final bool busy;

  const ChatInputBar({
    super.key,
    required this.onSendText,
    required this.onSendVoice,
    required this.onAttach,
    this.busy = false,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  final _recorder = AudioRecorder();
  bool _hasText = false;
  bool _recording = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await widget.onSendText(text);
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is needed')),
        );
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/chat_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    _startedAt = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) {
        setState(() => _elapsed = DateTime.now().difference(_startedAt!));
      }
    });
    setState(() {
      _recording = true;
      _elapsed = Duration.zero;
    });
  }

  Future<void> _stopRecording({required bool send}) async {
    _timer?.cancel();
    final path = await _recorder.stop();
    final duration = _startedAt == null
        ? 0
        : DateTime.now().difference(_startedAt!).inMilliseconds;
    setState(() => _recording = false);
    if (path == null) return;
    if (!send || duration < 800) {
      try {
        File(path).deleteSync();
      } catch (_) {}
      return;
    }
    await widget.onSendVoice(path, duration);
  }

  void _showAttachSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _attachOption(ctx, Icons.camera_alt_rounded, 'Camera',
                  const Color(0xFFC0475A), ChatAttachment.camera),
              _attachOption(ctx, Icons.photo_rounded, 'Gallery',
                  const Color(0xFF7B5EA7), ChatAttachment.gallery),
              _attachOption(ctx, Icons.insert_drive_file_rounded, 'Document',
                  const Color(0xFF2C7DA0), ChatAttachment.document),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachOption(BuildContext ctx, IconData icon, String label,
      Color color, ChatAttachment type) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.pop(ctx);
        widget.onAttach(type);
      },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12.5)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          8, 8, 8, 8 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _recording ? _recordingStrip() : _textField()),
              const SizedBox(width: 8),
              _actionButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _textField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file_rounded, color: Colors.grey),
            onPressed: widget.busy ? null : _showAttachSheet,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Message',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _recordingStrip() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEF0),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Cancel',
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: () => _stopRecording(send: false),
          ),
          const Icon(Icons.fiber_manual_record, color: Colors.red, size: 12),
          const SizedBox(width: 8),
          Text(
            formatDuration(_elapsed),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Recording…',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton() {
    final IconData icon;
    final VoidCallback? onTap;
    if (_recording) {
      icon = Icons.send_rounded;
      onTap = () => _stopRecording(send: true);
    } else if (_hasText) {
      icon = Icons.send_rounded;
      onTap = _sendText;
    } else {
      icon = Icons.mic_rounded;
      onTap = widget.busy ? null : _startRecording;
    }
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}
