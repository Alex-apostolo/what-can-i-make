import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:what_can_i_make/core/error/error_handler.dart';
import 'package:what_can_i_make/core/error/failures/failure.dart';
import 'package:what_can_i_make/features/image_analysis/domain/image_service.dart';
import 'package:what_can_i_make/features/inventory/domain/inventory_service.dart';
import 'package:what_can_i_make/features/user/domain/request_limit_service.dart';

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
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _errorHandler = Provider.of<ErrorHandler>(widget.parentContext);
    final inventoryService = Provider.of<InventoryService>(
      widget.parentContext,
    );
    final requestLimitService = Provider.of<RequestLimitService>(
      widget.parentContext,
    );

    _imageService = ImageService(
      inventoryService: inventoryService,
      requestLimitService: requestLimitService,
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
            onTap: () {
              Navigator.pop(context); // Close the bottom sheet
              _handleImageSelection(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from gallery'),
            onTap: () {
              Navigator.pop(context); // Close the bottom sheet
              _handleImageSelection(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleImageSelection(ImageSource source) async {
    // Create a loading dialog controller
    final loadingController = LoadingDialogController();

    // Show the loading dialog
    showDialog(
      context: widget.parentContext,
      builder: (context) => LoadingDialog(controller: loadingController),
    );

    try {
      if (source == ImageSource.camera) {
        // Set initial message
        loadingController.updateMessage('Capturing image...');

        // Pick image
        final imageResult = await _imageService.pickCameraImage();
        final image = _errorHandler.handleEither(imageResult);

        if (image == null) {
          _logger.i('Camera image selection cancelled');
          return;
        }

        // Update message for processing
        loadingController.updateMessage(
          'Analyzing your image...\nThis may take a moment.',
        );

        // Process image
        final result = await _imageService.processImage(image);
        _errorHandler.handleEither(result);

        // Notify parent
        widget.onImagesProcessed();
      } else {
        // Set initial message
        loadingController.updateMessage('Selecting images from gallery...');

        // Pick images
        final pickedImagesResult = await _imageService.pickGalleryImages();
        final pickedImages = _errorHandler.handleEither(pickedImagesResult);

        if (pickedImages.isEmpty) {
          _logger.i('No images were selected');
          return;
        }

        // Update message for processing
        loadingController.updateMessage(
          'Analyzing ${pickedImages.count} image(s)...\nThis may take a moment.',
        );

        // Process images
        final result = await _imageService.processImages(pickedImages.images);
        _errorHandler.handleEither(result);

        // Notify parent
        widget.onImagesProcessed();
      }
    } on Exception catch (e) {
      _logger.e('Error processing images: $e');
      _errorHandler.handleFailure(GenericFailure(error: e));
    } finally {
      // Close the loading dialog
      if (Navigator.of(widget.parentContext).canPop()) {
        Navigator.of(widget.parentContext, rootNavigator: true).pop();
      }
    }
  }
}

// Controller for the loading dialog
class LoadingDialogController {
  String _message = '';
  Function(String)? _onMessageChanged;

  String get message => _message;

  void updateMessage(String newMessage) {
    _message = newMessage;
    if (_onMessageChanged != null) {
      _onMessageChanged!(newMessage);
    }
  }

  void registerCallback(Function(String) callback) {
    _onMessageChanged = callback;
  }
}

// Stateful loading dialog
class LoadingDialog extends StatefulWidget {
  final LoadingDialogController controller;

  const LoadingDialog({super.key, required this.controller});

  @override
  State<LoadingDialog> createState() => _LoadingDialogState();
}

class _LoadingDialogState extends State<LoadingDialog> {
  late String _message;

  @override
  void initState() {
    super.initState();
    _message = widget.controller.message;
    widget.controller.registerCallback((newMessage) {
      if (mounted) {
        setState(() {
          _message = newMessage;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(_message),
        ],
      ),
    );
  }
}
