import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/error/error_handler.dart';
import '../../../domain/services/image_service.dart';

class ImagePickerBottomSheet extends StatefulWidget {
  final ImageService imageService;
  final Function onImagesProcessed;

  const ImagePickerBottomSheet({
    Key? key,
    required this.imageService,
    required this.onImagesProcessed,
  }) : super(key: key);

  @override
  State<ImagePickerBottomSheet> createState() => _ImagePickerBottomSheetState();
}

class _ImagePickerBottomSheetState extends State<ImagePickerBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take a photo'),
            onTap: () async {
              await _pickAndProcessImage(ImageSource.camera);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from gallery'),
            onTap: () async {
              await _pickAndProcessImage(ImageSource.gallery);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndProcessImage(ImageSource source) async {
    bool imagesProcessed = false;

    if (source == ImageSource.camera) {
      imagesProcessed = await _handleCameraImage();
    } else {
      imagesProcessed = await _handleGalleryImages();
    }

    if (imagesProcessed) {
      widget.onImagesProcessed();
    }
  }

  void _showProcessingDialog(int processingCount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                processingCount > 0
                    ? 'Processing $processingCount image(s)...'
                    : 'Processing...',
              ),
            ],
          ),
        );
      },
    );
  }

  void _closeDialog() {
    Navigator.pop(context);
  }

  Future<bool> _handleCameraImage() async {
    final image = errorHandler.handleEither(
      await widget.imageService.pickCameraImage(),
    );

    // Exit if user cancelled
    if (image == null) return false;

    _showProcessingDialog(1);

    // Process the image
    await errorHandler.handleEither(
      await widget.imageService.processImage(image),
    );

    _closeDialog();

    return true;
  }

  Future<bool> _handleGalleryImages() async {
    final pickedImages = errorHandler.handleEither(
      await widget.imageService.pickGalleryImages(),
    );

    // Exit if no images were selected
    if (pickedImages.isEmpty) return false;

    _showProcessingDialog(pickedImages.count);

    // Process the images
    await errorHandler.handleEither(
      await widget.imageService.processImages(pickedImages.images),
    );

    _closeDialog();

    return true;
  }
}
