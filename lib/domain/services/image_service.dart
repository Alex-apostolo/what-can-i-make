import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'openai_service.dart';
import '../../data/repositories/storage_repository.dart';
import '../../core/error/error_handler.dart';

/// Service to handle image selection and processing
class ImageService {
  // Constants
  static const int maxImageSelection = 15;
  
  // Services
  final ImagePicker _picker = ImagePicker();
  final OpenAIService _openAIService = OpenAIService();
  final StorageRepository _storageRepository;
  
  // Callback for when inventory changes
  final VoidCallback onInventoryChanged;
  
  ImageService({
    required this.onInventoryChanged,
    required StorageRepository storageRepository,
  }) : _storageRepository = storageRepository;
  
  /// Handles image selection from camera or gallery
  Future<void> pickImages(
    BuildContext context,
    ImageSource source,
    Function(bool) setLoading,
    Function(bool, int) setProcessingImages,
  ) async {
    if (source == ImageSource.camera) {
      await _handleCameraSelection(setLoading, setProcessingImages);
    } else {
      await _handleGallerySelection(context, setLoading, setProcessingImages);
    }
  }
  
  /// Handles camera image selection
  Future<void> _handleCameraSelection(
    Function(bool) setLoading,
    Function(bool, int) setProcessingImages,
  ) async {
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    setLoading(true);
    setProcessingImages(true, 1);
    
    await _processImages([image.path]);
    
    setLoading(false);
    setProcessingImages(false, 0);
  }
  
  /// Handles gallery image selection with limit checking
  Future<void> _handleGallerySelection(
    BuildContext context,
    Function(bool) setLoading,
    Function(bool, int) setProcessingImages,
  ) async {
    final images = await _picker.pickMultiImage();
    if (images.isEmpty) return;
    
    // Check if too many images were selected
    if (images.length > maxImageSelection) {
      _showTooManyImagesWarning(context, images.length);
    }
    
    // Limit to max images
    final limitedImages = images.take(maxImageSelection).toList();

    setLoading(true);
    setProcessingImages(true, limitedImages.length);
    
    // Process all images at once
    final imagePaths = limitedImages.map((image) => image.path).toList();
    await _processImages(imagePaths);
    
    setLoading(false);
    setProcessingImages(false, 0);
  }
  
  /// Shows warning when too many images are selected
  void _showTooManyImagesWarning(BuildContext context, int selectedCount) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'You selected $selectedCount images. Only the first $maxImageSelection will be processed.',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange.shade800,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  /// Processes images through OpenAI and saves results
  Future<void> _processImages(List<String> imagePaths) async {
    final result = await _openAIService.analyzeKitchenInventory(imagePaths);

    errorHandler.handleEither(
      result,
      onSuccess: (items) async {
        final saveResult = await _storageRepository.addItems(items);
        errorHandler.handleEither(
          saveResult,
          onSuccess: (_) => onInventoryChanged(),
        );
      },
    );
  }
  
  /// Disposes resources
  void dispose() {
    _openAIService.dispose();
  }
} 