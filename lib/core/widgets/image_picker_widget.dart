import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class ImagePickerWidget extends StatefulWidget {
  final List<String> initialImages;
  final Function(List<String>) onImagesChanged;
  final Function(List<File>)? onFilesChanged;
  final int maxImages;
  final double imageSize;

  const ImagePickerWidget({
    super.key,
    this.initialImages = const [],
    required this.onImagesChanged,
    this.onFilesChanged,
    this.maxImages = 5,
    this.imageSize = 100,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final List<File> _selectedFiles = [];
  final List<String> _imageUrls = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _imageUrls.addAll(widget.initialImages);
  }

  Future<void> _pickImages() async {
    if (_selectedFiles.length + _imageUrls.length >= widget.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum ${widget.maxImages} images allowed')),
      );
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          for (XFile image in images) {
            if (_selectedFiles.length + _imageUrls.length < widget.maxImages) {
              _selectedFiles.add(File(image.path));
            }
          }
        });
        _notifyParent();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking images: $e')));
    }
  }

  Future<void> _pickImagesFromFile() async {
    if (_selectedFiles.length + _imageUrls.length >= widget.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum ${widget.maxImages} images allowed')),
      );
      return;
    }

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        allowCompression: true,
      );

      if (result != null) {
        setState(() {
          for (var file in result.files) {
            if (file.path != null &&
                _selectedFiles.length + _imageUrls.length < widget.maxImages) {
              _selectedFiles.add(File(file.path!));
            }
          }
        });
        _notifyParent();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking files: $e')));
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
    _notifyParent();
  }

  void _removeUrl(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
    _notifyParent();
  }

  void _notifyParent() {
    widget.onImagesChanged(_imageUrls);
    if (widget.onFilesChanged != null) {
      widget.onFilesChanged!(_selectedFiles);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Court Images (${_selectedFiles.length + _imageUrls.length}/${widget.maxImages})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (_selectedFiles.length + _imageUrls.length <
                widget.maxImages) ...[
              IconButton(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_camera),
                tooltip: 'Pick from camera/gallery',
              ),
              IconButton(
                onPressed: _pickImagesFromFile,
                icon: const Icon(Icons.folder),
                tooltip: 'Pick from files',
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedFiles.isEmpty && _imageUrls.isEmpty)
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No images selected',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Display existing URLs
              ..._imageUrls.asMap().entries.map(
                (entry) => _buildImageWidget(
                  imageUrl: entry.value,
                  index: entry.key,
                  isUrl: true,
                ),
              ),
              // Display selected files
              ..._selectedFiles.asMap().entries.map(
                (entry) => _buildImageWidget(
                  imageFile: entry.value,
                  index: entry.key,
                  isUrl: false,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildImageWidget({
    File? imageFile,
    String? imageUrl,
    required int index,
    required bool isUrl,
  }) {
    return Stack(
      children: [
        Container(
          width: widget.imageSize,
          height: widget.imageSize,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isUrl
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.error, color: Colors.grey),
                      );
                    },
                  )
                : Image.file(imageFile!, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              if (isUrl) {
                _removeUrl(index);
              } else {
                _removeFile(index);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
