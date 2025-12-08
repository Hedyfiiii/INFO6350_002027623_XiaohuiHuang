// lib/utils/image_picker_helper.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class ImagePickerHelper {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Pick multiple images with platform-specific behavior
  static Future<List<File>> pickImages({
    int maxImages = 4,
    bool useCamera = false,
  }) async {
    List<File> images = [];

    try {
      if (useCamera) {
        // Camera is only available on mobile
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          final XFile? image = await _imagePicker.pickImage(
            source: ImageSource.camera,
            maxWidth: 1920,
            maxHeight: 1080,
            imageQuality: 85,
          );
          if (image != null) {
            return [File(image.path)];
          }
        }
      } else {
        // Gallery/File picker
        if (maxImages == 1) {
          final XFile? image = await _imagePicker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1920,
            maxHeight: 1080,
            imageQuality: 85,
          );
          if (image != null) {
            return [File(image.path)];
          }
        } else {
          // Multiple images
          final List<XFile> pickedImages = await _imagePicker.pickMultiImage(
            maxWidth: 1920,
            maxHeight: 1080,
            imageQuality: 85,
          );
          return pickedImages
              .take(maxImages)
              .map((xFile) => File(xFile.path))
              .toList();
        }
      }
    } catch (e) {
      print('Error picking images: $e');
    }

    return images;
  }

  /// Pick a single image
  static Future<File?> pickSingleImage({bool useCamera = false}) async {
    final images = await pickImages(maxImages: 1, useCamera: useCamera);
    return images.isNotEmpty ? images.first : null;
  }
}