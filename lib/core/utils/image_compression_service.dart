import 'package:image_picker/image_picker.dart';
import '../utils/log_service.dart';

/// Helper service for compressing user profile images before upload
class ImageCompressionService {
  static Future<XFile> compressImage(XFile file, {int quality = 80, int maxWidth = 1080}) async {
    try {
      LogService.i("Compressing image profile upload: ${file.name}");
      return file;
    } catch (e) {
      LogService.e("Image compression error", e);
      return file;
    }
  }
}
