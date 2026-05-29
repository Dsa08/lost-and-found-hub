import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../core/constants/app_colors.dart';

/// **VideoPlayerScreen (Pemutar Video)**
/// Layar penuh untuk memutar video bukti yang diunggah pelapor.
/// Menggunakan kombinasi `video_player` (mesin pemutar) dan `chewie` (antarmuka kontrol UI).
class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await _videoController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          bufferedColor: AppColors.primaryLight,
          backgroundColor: AppColors.surfaceVariant,
        ),
        placeholder: Container(color: Colors.black),
        errorBuilder: (context, errorMessage) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 48),
              const SizedBox(height: 12),
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat video: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    // Kembalikan orientasi ke portrait saat keluar
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: _isLoading
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Memuat video...', style: TextStyle(color: Colors.white54)),
                ],
              )
            : _errorMessage != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 60),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white54),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Chewie(controller: _chewieController!),
      ),
    );
  }
}

/// **VideoThumbnailWidget**
/// Menampilkan pratinjau (thumbnail) dari video tanpa perlu mengunduh file video utuh.
/// Otomatis mengambil frame pertama dari Cloudinary dengan trik mengubah ekstensi `.mp4` jadi `.jpg`.
class VideoThumbnailWidget extends StatelessWidget {
  final String videoUrl;
  final String title;

  const VideoThumbnailWidget({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  /// Generate thumbnail URL dari Cloudinary video URL
  String get _thumbnailUrl {
    return videoUrl
        .replaceAll('/video/upload/', '/video/upload/so_0,w_600,h_400,c_fill/')
        .replaceAll('.mp4', '.jpg')
        .replaceAll('.mov', '.jpg')
        .replaceAll('.avi', '.jpg')
        .replaceAll('.mkv', '.jpg');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(videoUrl: videoUrl, title: title),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Thumbnail dari Cloudinary
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Image.network(
                _thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: Colors.black,
                  child: const Icon(Icons.videocam_rounded, size: 48, color: Colors.white24),
                ),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 180,
                    color: Colors.black,
                    child: const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                  );
                },
              ),
            ),

            // Overlay gelap
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),

            // Tombol Play
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
            ),

            // Label bawah
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.play_circle_outline, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Putar Video Bukti', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}