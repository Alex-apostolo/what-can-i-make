import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/error/failures/failure.dart';
import 'food_image_analyzer.dart';
import 'inventory_service.dart';

/// Service to handle image selection and processing
class ImageService {
  // Constants
  static const int maxImageSelection = 15;

  // Services
  final ImagePicker _picker = ImagePicker();
  final FoodImageAnalyzer _foodImageAnalyzer = FoodImageAnalyzer();
  final InventoryService _inventoryService;

  /// Constructor that initializes the service
  ImageService({required InventoryService inventoryService})
    : _inventoryService = inventoryService;

  /// Picks a single image from camera
  Future<Either<Failure, void>> pickAndProcessCameraImage() async {
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) {
      return const Right(null); // User cancelled, not an error
    }

    return _processImages([image.path]);
  }

  /// Picks multiple images from gallery
  Future<Either<Failure, PickedImagesResult>>
  pickAndProcessGalleryImages() async {
    final images = await _picker.pickMultiImage();
    if (images.isEmpty) {
      return const Right(
        PickedImagesResult(processedCount: 0, limitExceeded: false),
      );
    }

    // Check if too many images were selected
    final limitExceeded = images.length > maxImageSelection;

    // Limit to max images
    final limitedImages = images.take(maxImageSelection).toList();

    // Process all images at once
    final imagePaths = limitedImages.map((image) => image.path).toList();
    final result = await _processImages(imagePaths);

    return result.fold(
      (failure) => Left(failure),
      (_) => Right(
        PickedImagesResult(
          processedCount: limitedImages.length,
          limitExceeded: limitExceeded,
          totalSelected: images.length,
        ),
      ),
    );
  }

  /// Processes images through OpenAI and saves results
  Future<Either<Failure, void>> _processImages(List<String> imagePaths) async {
    final ingredientsResult = await _foodImageAnalyzer.run(imagePaths);

    return ingredientsResult.fold((failure) => Left(failure), (
      ingredients,
    ) async {
      // Add each ingredient to inventory
      for (final ingredient in ingredients) {
        final result = await _inventoryService.addIngredient(ingredient);

        // If any ingredient fails to save, return the failure
        if (result.isLeft()) {
          return result;
        }
      }

      return const Right(null);
    });
  }

  /// Disposes resources
  void dispose() {
    _foodImageAnalyzer.dispose();
  }
}

/// Result class for gallery image picking
class PickedImagesResult {
  final int processedCount;
  final bool limitExceeded;
  final int totalSelected;

  const PickedImagesResult({
    required this.processedCount,
    required this.limitExceeded,
    this.totalSelected = 0,
  });
}
