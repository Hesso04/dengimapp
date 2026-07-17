import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/log_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CloudinaryService {
  // Demo amaçlı kamuya açık bir preset kullanıyoruz
  static const String _cloudName = "dl0sbmno0";
  static const String _uploadPreset = "dengim_preset";


  static Future<String?> uploadImage(XFile file) async {
    return _uploadWithRetry(() async {
      try {
        final compressedFile = await _compressImage(file);
        final url = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/image/upload");
        
        // Web ve mobil için farklı yükleme stratejisi
        http.MultipartRequest request = http.MultipartRequest("POST", url)
          ..fields['upload_preset'] = _uploadPreset;
        
        if (kIsWeb) {
          // Web için bytes kullan
          final bytes = await compressedFile.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: compressedFile.name,
          ));
        } else {
          // Mobil için path kullan
          request.files.add(await http.MultipartFile.fromPath('file', compressedFile.path));
        }

        final response = await request.send();
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonResponse = jsonDecode(responseString);

        if (response.statusCode == 200) {
          LogService.i("Cloudinary upload success: ${jsonResponse['secure_url']}");
          return jsonResponse['secure_url'];
        } else {
          LogService.e("Cloudinary Upload Failed (Status: ${response.statusCode})");
          LogService.e("Response: $responseString");
          throw Exception("Upload failed with status ${response.statusCode}");
        }

      } catch (e) {
        LogService.e("Cloudinary upload attempt failed", e);
        rethrow;
      }
    });
  }

  static Future<String?> _uploadWithRetry(Future<String?> Function() uploadFn, {int maxAttempts = 3}) async {
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await uploadFn();
      } catch (e) {
        if (attempt == maxAttempts - 1) {
          LogService.e("Upload failed after $maxAttempts attempts", e);
          return null;
        }
        // Exponential backoff: 1s, 2s, 4s
        final delay = Duration(seconds: 1 << attempt);
        LogService.i("Retry upload in ${delay.inSeconds}s (attempt ${attempt + 1}/$maxAttempts)");
        await Future.delayed(delay);
      }
    }
    return null;
  }

  static Future<String?> uploadImageBytes(Uint8List bytes, {String filename = 'image.jpg'}) async {
    return _uploadWithRetry(() async {
      try {
        final compressedBytes = await _compressBytes(bytes);
        final url = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/image/upload");
        final request = http.MultipartRequest("POST", url);

        request.fields['upload_preset'] = _uploadPreset;
        
        // Upload raw bytes
        request.files.add(http.MultipartFile.fromBytes(
          'file', 
          compressedBytes, 
          filename: filename
        ));

        final response = await request.send();
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonResponse = jsonDecode(responseString);

        if (response.statusCode == 200) {
          LogService.i("Cloudinary bytes upload success: ${jsonResponse['secure_url']}");
          return jsonResponse['secure_url'];
        } else {
          LogService.e("Cloudinary Bytes Upload Failed (Status: ${response.statusCode})");
          throw Exception("Bytes upload failed with status ${response.statusCode}");
        }
      } catch (e) {
        LogService.e("Cloudinary bytes upload attempt failed", e);
        rethrow;
      }
    });
  }

  /// Ses dosyası yükle (m4a, mp3, wav vb.)
  static Future<String?> uploadAudioBytes(Uint8List bytes, {String filename = 'voice_message.m4a'}) async {
    return _uploadWithRetry(() async {
      try {
        // Ses dosyaları için 'video' veya 'raw' endpoint kullanılır
        final url = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/video/upload");
        final request = http.MultipartRequest("POST", url);

        request.fields['upload_preset'] = _uploadPreset;
        request.fields['resource_type'] = 'video'; // Ses için 'video' tipi
        
        request.files.add(http.MultipartFile.fromBytes(
          'file', 
          bytes, 
          filename: filename
        ));

        final response = await request.send();
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonResponse = jsonDecode(responseString);

        if (response.statusCode == 200) {
          LogService.i("Cloudinary audio upload success: ${jsonResponse['secure_url']}");
          return jsonResponse['secure_url'];
        } else {
          LogService.e("Cloudinary Audio Upload Failed (Status: ${response.statusCode})");
          LogService.e("Response: $responseString");
          throw Exception("Audio upload failed with status ${response.statusCode}");
        }
      } catch (e) {
        LogService.e("Cloudinary audio upload attempt failed", e);
        rethrow;
      }
    });
  }

  /// Video dosyası yükle
  static Future<String?> uploadVideo(XFile file) async {
    return _uploadWithRetry(() async {
      try {
        final url = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/video/upload");
        final request = http.MultipartRequest("POST", url);

        request.fields['upload_preset'] = _uploadPreset;
        request.fields['resource_type'] = 'video';
        
        if (kIsWeb) {
          final bytes = await file.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: file.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath('file', file.path));
        }

        final response = await request.send();
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonResponse = jsonDecode(responseString);

        if (response.statusCode == 200) {
          LogService.i("Cloudinary video upload success: ${jsonResponse['secure_url']}");
          return jsonResponse['secure_url'];
        } else {
          LogService.e("Cloudinary Video Upload Failed (Status: ${response.statusCode})");
          LogService.e("Response: $responseString");
          throw Exception("Video upload failed with status ${response.statusCode}");
        }
      } catch (e) {
        LogService.e("Cloudinary video upload attempt failed", e);
        rethrow;
      }
    });
  }

  static Future<XFile> _compressImage(XFile file) async {
    if (kIsWeb) return file;
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = "${dir.absolute.path}/temp_compress_${DateTime.now().millisecondsSinceEpoch}.jpg";
      
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: 80,
        minWidth: 1080,
        minHeight: 1080,
        format: CompressFormat.jpeg,
      );
      
      if (compressedFile != null) {
        final newFile = XFile(compressedFile.path);
        final originalSize = await File(file.path).length();
        final compressedSize = await File(newFile.path).length();
        LogService.i("Image compressed: from ${(originalSize / 1024).toStringAsFixed(1)} KB to ${(compressedSize / 1024).toStringAsFixed(1)} KB");
        return newFile;
      }
    } catch (e) {
      LogService.e("Failed to compress image, uploading original file: $e");
    }
    return file;
  }

  static Future<Uint8List> _compressBytes(Uint8List bytes) async {
    if (kIsWeb) return bytes;
    try {
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        quality: 80,
        minWidth: 1080,
        minHeight: 1080,
        format: CompressFormat.jpeg,
      );
      LogService.i("Image bytes compressed: from ${(bytes.length / 1024).toStringAsFixed(1)} KB to ${(compressedBytes.length / 1024).toStringAsFixed(1)} KB");
      return compressedBytes;
    } catch (e) {
      LogService.e("Failed to compress image bytes, uploading original bytes: $e");
    }
    return bytes;
  }
}


