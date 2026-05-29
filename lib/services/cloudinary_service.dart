import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// **CloudinaryService**
/// Layanan untuk meng-upload file media (Gambar dan Video) ke server Cloudinary.
/// Kita menggunakan Cloudinary alih-alih Firebase Storage untuk menghemat kuota Firebase,
/// karena Cloudinary menyediakan optimasi gambar otomatis dan gratis untuk skala kecil.
class CloudinaryService {
  // ── Konfigurasi Cloudinary ──────────────────────────────────────────────────
  static const String _cloudName = 'dop5bvqiv';
  static const String _uploadPreset = 'lost_found_hub';

  static const String _imageUploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';
  static const String _videoUploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/video/upload';

  /// **Fungsi uploadImage**
  /// Mengirim satu file gambar ke server Cloudinary menggunakan HTTP POST (Multipart).
  /// Mengembalikan `secure_url` (link HTTPS publik) gambar tersebut jika berhasil.
  static Future<String> uploadImage(File imageFile, String itemId) async {
    final request = http.MultipartRequest('POST', Uri.parse(_imageUploadUrl));

    request.fields['upload_preset'] = _uploadPreset;
    request.fields['folder'] = 'lost_found/$itemId';

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
    ));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = json.decode(body);
      return data['secure_url'] as String;
    } else {
      throw Exception('Gagal upload foto: ${response.statusCode} — $body');
    }
  }

  /// Upload banyak foto sekaligus, kembalikan list URL
  static Future<List<String>> uploadImages(
      List<File> imageFiles, String itemId) async {
    final urls = <String>[];
    for (int i = 0; i < imageFiles.length; i++) {
      final url = await uploadImage(imageFiles[i], itemId);
      urls.add(url);
    }
    return urls;
  }

  /// **Fungsi uploadVideo**
  /// Mengirim file video. Perlu diperhatikan bahwa resource_type diset ke 'video'.
  /// Mengembalikan `secure_url` video.
  static Future<String> uploadVideo(File videoFile, String itemId) async {
    final request = http.MultipartRequest('POST', Uri.parse(_videoUploadUrl));

    request.fields['upload_preset'] = _uploadPreset;
    request.fields['folder'] = 'lost_found/$itemId';
    request.fields['resource_type'] = 'video';

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      videoFile.path,
    ));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = json.decode(body);
      return data['secure_url'] as String;
    } else {
      throw Exception('Gagal upload video: ${response.statusCode} — $body');
    }
  }

  /// Generate thumbnail URL dari video URL Cloudinary
  /// (otomatis dihasilkan Cloudinary, tidak perlu upload terpisah)
  static String getVideoThumbnail(String videoUrl) {
    // Ganti ekstensi video dengan .jpg untuk dapat thumbnail
    return videoUrl
        .replaceAll('/video/upload/', '/video/upload/so_0/')
        .replaceAll('.mp4', '.jpg')
        .replaceAll('.mov', '.jpg')
        .replaceAll('.avi', '.jpg');
  }
}