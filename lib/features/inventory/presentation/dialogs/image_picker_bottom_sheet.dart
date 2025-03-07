import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:what_can_i_make/core/error/error_handler.dart';
import 'package:what_can_i_make/features/image_analysis/domain/image_service.dart';
import 'package:what_can_i_make/features/inventory/domain/inventory_service.dart';
import 'package:what_can_i_make/core/services/token_usage_service.dart';

class ImagePickerBottomSheet extends StatefulWidget {
  final VoidCallback onImagesProcessed;
  final BuildContext parentContext;

  const ImagePickerBottomSheet({
    super.key,
    required this.onImagesProcessed,
    required this.parentContext,
  });

  @override
  State<ImagePickerBottomSheet> createState() => _ImagePickerBottomSheetState();
}

class _ImagePickerBottomSheetState extends State<ImagePickerBottomSheet> {
  late ErrorHandler _errorHandler;
  late ImageService _imageService;

  @override
  void initState() {
    super.initState();
    _errorHandler = Provider.of<ErrorHandler>(widget.parentContext);
    final inventoryService = Provider.of<InventoryService>(
      widget.parentContext,
    );
    final tokenUsageService = Provider.of<TokenUsageService>(
      widget.parentContext,
    );

    _imageService = ImageService(
      inventoryService: inventoryService,
      tokenUsageService: tokenUsageService,
    );
  }

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
    if (!mounted) return;
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
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<bool> _handleCameraImage() async {
    final image = _errorHandler.handleEither(
      await _imageService.pickCameraImage(),
    );

    // Exit if user cancelled
    if (image == null) return false;

    _showProcessingDialog(1);

    // Process the image
    _errorHandler.handleEither(await _imageService.processImage(image));

    _closeDialog();

    return true;
  }

  Future<bool> _handleGalleryImages() async {
    final pickedImages = _errorHandler.handleEither(
      await _imageService.pickGalleryImages(),
    );

    // Exit if no images were selected
    if (pickedImages.isEmpty) return false;

    _showProcessingDialog(pickedImages.count);

    // Process the images
    _errorHandler.handleEither(
      await _imageService.processImages(pickedImages.images),
    );

    _closeDialog();

    return true;
  }
}
