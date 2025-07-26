import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }

  /// Upload a single image to Supabase Storage
  static Future<String?> uploadImage({
    required File imageFile,
    required String courtId,
    String? fileName,
  }) async {
    try {
      final String fileExtension = imageFile.path.split('.').last;
      final String uniqueFileName =
          fileName ?? '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final String filePath = '$courtId/$uniqueFileName';

      // Upload file to Supabase Storage
      await _supabase.storage
          .from(SupabaseConfig.courtImagesBucket)
          .upload(filePath, imageFile);

      // Get public URL
      final String publicUrl = _supabase.storage
          .from(SupabaseConfig.courtImagesBucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Upload multiple images to Supabase Storage
  static Future<List<String>> uploadImages({
    required List<File> imageFiles,
    required String courtId,
  }) async {
    List<String> uploadedUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      final String? url = await uploadImage(
        imageFile: imageFiles[i],
        courtId: courtId,
        fileName: 'image_$i',
      );

      if (url != null) {
        uploadedUrls.add(url);
      }
    }

    return uploadedUrls;
  }

  /// Upload image from bytes (useful for web)
  static Future<String?> uploadImageFromBytes({
    required Uint8List imageBytes,
    required String courtId,
    required String fileName,
  }) async {
    try {
      final String filePath = '$courtId/$fileName';

      // Upload bytes to Supabase Storage
      await _supabase.storage
          .from(SupabaseConfig.courtImagesBucket)
          .uploadBinary(filePath, imageBytes);

      // Get public URL
      final String publicUrl = _supabase.storage
          .from(SupabaseConfig.courtImagesBucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Error uploading image from bytes: $e');
      return null;
    }
  }

  /// Delete an image from Supabase Storage
  static Future<bool> deleteImage({
    required String imageUrl,
    required String courtId,
  }) async {
    try {
      // Extract file path from URL
      final Uri uri = Uri.parse(imageUrl);
      final String filePath = uri.pathSegments.last;
      final String fullPath = '$courtId/$filePath';

      await _supabase.storage.from(SupabaseConfig.courtImagesBucket).remove([
        fullPath,
      ]);

      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Get all images for a specific court
  static Future<List<String>> getCourtImages(String courtId) async {
    try {
      final List<FileObject> files = await _supabase.storage
          .from(SupabaseConfig.courtImagesBucket)
          .list(path: courtId);

      return files
          .map(
            (file) => _supabase.storage
                .from(SupabaseConfig.courtImagesBucket)
                .getPublicUrl('$courtId/${file.name}'),
          )
          .toList();
    } catch (e) {
      print('Error getting court images: $e');
      return [];
    }
  }

  /// Check if storage bucket exists, create if not
  static Future<void> ensureBucketExists() async {
    try {
      final List<Bucket> buckets = await _supabase.storage.listBuckets();
      final bool bucketExists = buckets.any(
        (bucket) => bucket.id == SupabaseConfig.courtImagesBucket,
      );

      if (!bucketExists) {
        await _supabase.storage.createBucket(SupabaseConfig.courtImagesBucket);
        print('Created storage bucket: ${SupabaseConfig.courtImagesBucket}');
      }
    } catch (e) {
      print('Error ensuring bucket exists: $e');
    }
  }
}
