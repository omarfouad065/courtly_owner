import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/image_picker_widget.dart';
import '../../../../core/services/supabase_service.dart';

class EditImagesView extends StatefulWidget {
  final String venueId;
  final Map<String, dynamic> venueData;

  const EditImagesView({
    super.key,
    required this.venueId,
    required this.venueData,
  });

  @override
  State<EditImagesView> createState() => _EditImagesViewState();
}

class _EditImagesViewState extends State<EditImagesView> {
  List<String> _currentImages = [];
  List<File> _selectedImageFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentImages();
  }

  void _loadCurrentImages() {
    final images = widget.venueData['images'] as List<dynamic>?;
    if (images != null) {
      _currentImages = images.cast<String>();
    }
  }

  Future<void> _saveImages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<String> finalImageUrls = List.from(_currentImages);

      // Upload new images to Supabase if any selected
      if (_selectedImageFiles.isNotEmpty) {
        final uploadedUrls = await SupabaseService.uploadImages(
          imageFiles: _selectedImageFiles,
          courtId: widget.venueId,
        );
        finalImageUrls.addAll(uploadedUrls);
      }

      // Save all image URLs to Firestore
      await FirebaseFirestore.instance
          .collection('venues')
          .doc(widget.venueId)
          .update({'images': finalImageUrls, 'updatedAt': DateTime.now()});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Images updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating images: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Edit Images'),
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Court Images',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add, remove, or reorder images for your court. The first image will be used as the main display image.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ImagePickerWidget(
              initialImages: _currentImages,
              onImagesChanged: (images) {
                setState(() {
                  _currentImages = images;
                });
              },
              onFilesChanged: (files) {
                setState(() {
                  _selectedImageFiles = files;
                });
              },
              maxImages: 8,
              imageSize: 120,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveImages,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Images'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
