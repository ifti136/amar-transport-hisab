import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Service for handling receipt photos
/// Compresses images to max 1920px, 80% JPEG quality
class PhotoService {
  static final ImagePicker _picker = ImagePicker();
  static const int _maxDimension = 1920;
  static const int _jpegQuality = 80;

  /// Pick an image from camera or gallery
  static Future<File?> pickImage({required ImageSource source}) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: _maxDimension.toDouble(),
      maxHeight: _maxDimension.toDouble(),
      imageQuality: _jpegQuality,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Save image to app documents directory with unique name
  static Future<String> saveImage(File image) async {
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'receipts'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = p.extension(image.path).isNotEmpty ? p.extension(image.path) : '.jpg';
    final fileName = 'receipt_$timestamp$extension';
    final savedPath = p.join(photosDir.path, fileName);

    return image.copy(savedPath).then((file) => file.path);
  }

  /// Delete an image file
  static Future<void> deleteImage(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Get the receipts directory path
  static Future<String> getReceiptsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'receipts'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    return photosDir.path;
  }

  /// Clean up orphaned photos (not referenced in DB)
  /// This should be called periodically or on app start
  static Future<void> cleanupOrphanedPhotos(Set<String> referencedPaths) async {
    final dir = await getReceiptsDir();
    final photosDir = Directory(dir);
    if (!await photosDir.exists()) return;

    final files = await photosDir.list().toList();
    for (final file in files) {
      if (file is File && !referencedPaths.contains(file.path)) {
        await file.delete();
      }
    }
  }
}