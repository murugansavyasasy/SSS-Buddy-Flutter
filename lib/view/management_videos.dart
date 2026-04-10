import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Values/Colors/app_colors.dart';
import '../auth/model/ManagementVideosModel.dart';
import '../components/toolbar_layout.dart';
import '../utils/VimeoPlayerScreen.dart';
import '../viewModel/management_videos_viewmodel.dart';
import 'dashboard.dart';


class ManagementVideos extends ConsumerWidget {
  final String userId;
  const ManagementVideos({super.key, required this.userId});

  void _launchYoutube(BuildContext context, String url) async {
    final uri = Uri.parse(url);

    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open YouTube")),
      );
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(managementVideosProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            const ToolbarLayout(
              title: "Management Videos",
              navigateTo: Dashboard(),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: videosAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text("Error: $e")),
                  data: (videos) => ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: videos.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final video = videos[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        leading: _buildThumbnail(video),
                        title: Text(
                          video.videoName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✅ Share button
                            IconButton(
                              icon: Icon(
                                // ✅ Use platform-specific share icon
                                Theme.of(context).platform == TargetPlatform.iOS
                                    ? CupertinoIcons.share
                                    : Icons.share,
                                color: AppColors.primary,
                                size: 22,
                              ),
                              onPressed: () => _shareVideo(video),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () {
                          if (video.videoType == "youtube") {
                            _launchYoutube(context, video.videoURL);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VimeoPlayerScreen(
                                  videoUrl: video.videoURL,
                                  videoName: video.videoName,
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareVideo(Managementvideosmodel video) {
    final title = video.videoName?.trim() ?? "Video";
    final url = video.videoURL?.trim() ?? "";

    if (url.isEmpty) {
      debugPrint("❌ No video URL to share");
      return;
    }

    SharePlus.instance.share(
      ShareParams(
        text: '🎬 $title\n\nWatch here:\n$url',
        subject: title,
      ),
    );
  }

  Widget _buildThumbnail(Managementvideosmodel video) {
    final String thumbnailUrl = _getThumbnailUrl(video);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CachedNetworkImage(
            imageUrl: thumbnailUrl,
            width: 90,
            height: 60,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 90,
              height: 60,
              color: Colors.grey.shade200,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              width: 90,
              height: 60,
              color: Colors.grey.shade300,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
          Container(
            width: 90,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          const Icon(
            Icons.play_circle_fill,
            color: Colors.white,
            size: 28,
          ),
        ],
      ),
    );
  }

  String _getThumbnailUrl(Managementvideosmodel video) {
    if (video.videoType == "youtube") {
      final Uri uri = Uri.parse(video.videoURL);
      String videoId = "";

      if (uri.host.contains("youtu.be")) {
        videoId = uri.pathSegments.first;
      } else if (uri.host.contains("youtube.com")) {
        videoId = uri.queryParameters["v"] ?? "";
      }

      return "https://img.youtube.com/vi/$videoId/mqdefault.jpg";
    } else {
      final Uri uri = Uri.parse(video.videoURL);
      String videoId = uri.pathSegments.last;
      if (videoId.contains("?")) {
        videoId = videoId.split("?").first;
      }
      return "https://vumbnail.com/$videoId.jpg";
    }
  }
}