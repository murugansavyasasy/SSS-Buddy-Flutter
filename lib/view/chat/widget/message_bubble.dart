import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../Values/Colors/app_colors.dart';
import '../../../auth/model/ChatModels.dart';
import 'chat_common.dart';
import 'voice_message_bubble.dart';

/// Local demo mode keeps media as on-device paths instead of URLs.
bool isLocalMedia(String url) => url.startsWith('/') || url.startsWith('file:');

Widget chatImage(String url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  Widget error() => Container(
        width: width,
        height: 120,
        color: Colors.black12,
        child: const Icon(Icons.broken_image_outlined),
      );
  if (isLocalMedia(url)) {
    return Image.file(
      File(url.replaceFirst('file://', '')),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => error(),
    );
  }
  return CachedNetworkImage(
    imageUrl: url,
    width: width,
    height: height,
    fit: fit,
    placeholder: (_, __) => Container(
      width: width,
      height: height,
      color: Colors.black12,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(strokeWidth: 2),
    ),
    errorWidget: (_, __, ___) => error(),
  );
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final bool showSender;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showSender = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isMine ? AppColors.primary : Colors.white;
    final fg = isMine ? Colors.white : const Color(0xFF1C2340);
    final isImage = message.type == ChatMessageType.image;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: isImage
              ? const EdgeInsets.all(4)
              : const EdgeInsets.fromLTRB(12, 8, 12, 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSender && !isMine)
                Padding(
                  padding: EdgeInsets.fromLTRB(isImage ? 6 : 0, isImage ? 2 : 0, 0, 3),
                  child: Text(
                    message.senderName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              _content(context, fg),
              const SizedBox(height: 3),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.only(right: isImage ? 6 : 0, bottom: isImage ? 2 : 0),
                  child: Text(
                    DateFormat('h:mm a').format(message.time),
                    style: TextStyle(fontSize: 10, color: fg.withOpacity(0.65)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, Color fg) {
    switch (message.type) {
      case ChatMessageType.text:
        return Text(
          message.text,
          style: TextStyle(color: fg, fontSize: 14.5, height: 1.3),
        );
      case ChatMessageType.image:
        final url = message.mediaUrl ?? '';
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => _ImageViewer(url: url)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: chatImage(url, width: 220, height: 220),
          ),
        );
      case ChatMessageType.voice:
        return VoiceMessageBubble(
          url: message.mediaUrl ?? '',
          durationMs: message.durationMs,
          isMine: isMine,
        );
      case ChatMessageType.file:
        return InkWell(
          onTap: () async {
            final url = message.mediaUrl ?? '';
            final uri = isLocalMedia(url)
                ? Uri.file(url.replaceFirst('file://', ''))
                : Uri.tryParse(url);
            if (uri != null) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: fg.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.insert_drive_file_rounded, color: fg),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.fileName ?? 'Document',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    if (formatFileSize(message.fileSize).isNotEmpty)
                      Text(
                        formatFileSize(message.fileSize),
                        style: TextStyle(color: fg.withOpacity(0.7), fontSize: 11),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _ImageViewer extends StatelessWidget {
  final String url;

  const _ImageViewer({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: chatImage(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
