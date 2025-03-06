import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/error/error_handler.dart';
import '../../../domain/services/image_service.dart';
import '../../../domain/services/inventory_service.dart';

class ImagePickerBottomSheet extends StatefulWidget {
  final Function onImagesProcessed;
  final BuildContext parentContext;

  const ImagePickerBottomSheet({
    required this.onImagesProcessed,
    required this.parentContext,
  });

  @override
  State<ImagePickerBottomSheet> createState() => _ImagePickerBottomSheetState();
}

class _ImagePickerBottomSheetState extends State<ImagePickerBottomSheet> {
  late final ImageService _imageService;
  late final ErrorHandler _errorHandler;

  @override
  void initState() {
    super.initState();
    final inventoryService = widget.parentContext.read<InventoryService>();
    _errorHandler = widget.parentContext.read<ErrorHandler>();
    _imageService = ImageService(inventoryService: inventoryService);
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
    await _errorHandler.handleEither(await _imageService.processImage(image));

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
    await _errorHandler.handleEither(
      await _imageService.processImages(pickedImages.images),
    );

    _closeDialog();

    return true;
  }
}
