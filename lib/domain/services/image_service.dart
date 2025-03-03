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
  Future<Either<Failure, XFile?>> pickCameraImage() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.camera);
      return Right(image); // May be null if user cancels
    } on Exception {
      return Left(ImagePickFailure('Failed to capture image'));
    }
  }

  /// Picks multiple images from gallery
  Future<Either<Failure, PickedImages>> pickGalleryImages() async {
    try {
      final images = await _picker.pickMultiImage();

      // Check if too many images were selected
      final limitExceeded = images.length > maxImageSelection;

      // Limit to max images
      final limitedImages = images.take(maxImageSelection).toList();

      return Right(
        PickedImages(
          images: limitedImages,
          limitExceeded: limitExceeded,
          totalSelected: images.length,
        ),
      );
    } on Exception {
      return Left(ImagePickFailure('Failed to pick images'));
    }
  }

  /// Process a single image
  Future<Either<Failure, void>> processImage(XFile image) async {
    return _processImages([image.path]);
  }

  /// Process multiple images
  Future<Either<Failure, void>> processImages(List<XFile> images) async {
    final imagePaths = images.map((image) => image.path).toList();
    return _processImages(imagePaths);
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
class PickedImages {
  final List<XFile> images;
  final bool limitExceeded;
  final int totalSelected;

  const PickedImages({
    required this.images,
    required this.limitExceeded,
    this.totalSelected = 0,
  });

  bool get isEmpty => images.isEmpty;
  int get count => images.length;
}

/// Custom failures
class ImagePickFailure extends Failure {
  @override
  final String message;

  const ImagePickFailure(this.message) : super(message);
}
