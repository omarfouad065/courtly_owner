import 'dart:io';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

/// Example usage of Supabase service for image uploads
class SupabaseUsageExample extends StatefulWidget {
  const SupabaseUsageExample({super.key});

  @override
  State<SupabaseUsageExample> createState() => _SupabaseUsageExampleState();
}

class _SupabaseUsageExampleState extends State<SupabaseUsageExample> {
  List<String> uploadedImageUrls = [];
  bool isUploading = false;

  /// Example: Upload a single image
  Future<void> uploadSingleImage() async {
    // This would typically be called from an image picker
    // For demonstration, we'll show the structure

    setState(() {
      isUploading = true;
    });

    try {
      // Example file path (in real app, this would come from image picker)
      // File imageFile = File('path/to/image.jpg');

      // String? imageUrl = await SupabaseService.uploadImage(
      //   imageFile: imageFile,
      //   courtId: 'court_123',
      //   fileName: 'court_image.jpg',
      // );

      // if (imageUrl != null) {
      //   setState(() {
      //     uploadedImageUrls.add(imageUrl);
      //   });
      // }

      // For now, just simulate success
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        uploadedImageUrls.add('https://example.com/image.jpg');
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  /// Example: Upload multiple images
  Future<void> uploadMultipleImages() async {
    setState(() {
      isUploading = true;
    });

    try {
      // Example file list (in real app, this would come from image picker)
      // List<File> imageFiles = [File('path1.jpg'), File('path2.jpg')];

      // List<String> urls = await SupabaseService.uploadImages(
      //   imageFiles: imageFiles,
      //   courtId: 'court_123',
      // );

      // setState(() {
      //   uploadedImageUrls.addAll(urls);
      // });

      // For now, just simulate success
      await Future.delayed(const Duration(seconds: 3));
      setState(() {
        uploadedImageUrls.addAll([
          'https://example.com/image1.jpg',
          'https://example.com/image2.jpg',
        ]);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  /// Example: Delete an image
  Future<void> deleteImage(String imageUrl) async {
    try {
      bool success = await SupabaseService.deleteImage(
        imageUrl: imageUrl,
        courtId: 'court_123',
      );

      if (success) {
        setState(() {
          uploadedImageUrls.remove(imageUrl);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image deleted successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  /// Example: Get all images for a court
  Future<void> getCourtImages() async {
    try {
      List<String> images = await SupabaseService.getCourtImages('court_123');
      setState(() {
        uploadedImageUrls = images;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to get images: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supabase Usage Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Supabase Image Upload Examples',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Upload buttons
            Row(
              children: [
                ElevatedButton(
                  onPressed: isUploading ? null : uploadSingleImage,
                  child: const Text('Upload Single Image'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: isUploading ? null : uploadMultipleImages,
                  child: const Text('Upload Multiple Images'),
                ),
              ],
            ),

            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: getCourtImages,
              child: const Text('Get Court Images'),
            ),

            const SizedBox(height: 20),

            // Loading indicator
            if (isUploading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Uploading images...'),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Display uploaded images
            if (uploadedImageUrls.isNotEmpty) ...[
              const Text(
                'Uploaded Images:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: uploadedImageUrls.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.image),
                        title: Text('Image ${index + 1}'),
                        subtitle: Text(uploadedImageUrls[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () =>
                              deleteImage(uploadedImageUrls[index]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              const Expanded(
                child: Center(
                  child: Text(
                    'No images uploaded yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Example of how to use the Supabase service in your court management
class CourtImageManager {
  final String courtId;

  CourtImageManager(this.courtId);

  /// Upload court images
  Future<List<String>> uploadCourtImages(List<File> imageFiles) async {
    return await SupabaseService.uploadImages(
      imageFiles: imageFiles,
      courtId: courtId,
    );
  }

  /// Get all images for this court
  Future<List<String>> getCourtImages() async {
    return await SupabaseService.getCourtImages(courtId);
  }

  /// Delete a specific image
  Future<bool> deleteCourtImage(String imageUrl) async {
    return await SupabaseService.deleteImage(
      imageUrl: imageUrl,
      courtId: courtId,
    );
  }
}
