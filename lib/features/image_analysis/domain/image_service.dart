import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:what_can_i_make/core/error/failures/failure.dart';
import 'package:what_can_i_make/features/inventory/domain/inventory_service.dart';
import 'ingredient_detection_service.dart';
import 'package:what_can_i_make/core/services/token_usage_service.dart';

/// Service to handle image selection and processing
class ImageService {
  // Constants
  static const int maxImageSelection = 15;

  // Services
  final ImagePicker _picker = ImagePicker();
  final IngredientDetectionService _ingredientDetectionService;
  final InventoryService _inventoryService;

  /// Constructor that initializes the service
  ImageService({
    required InventoryService inventoryService,
    TokenUsageService? tokenUsageService,
  }) : _inventoryService = inventoryService,
       _ingredientDetectionService = IngredientDetectionService(
         tokenUsageService: tokenUsageService,
       );

  /// Picks a single image from camera
  Future<Either<Failure, XFile?>> pickCameraImage() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.camera);
      return Right(image); // May be null if user cancels
    } on Exception catch (e) {
      return Left(ImagePickFailure('Failed to capture image', e));
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
    } on Exception catch (e) {
      return Left(ImagePickFailure('Failed to pick images', e));
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
    final ingredientsResult = await _ingredientDetectionService.analyzeImages(
      imagePaths,
    );

    return ingredientsResult.fold(
      (failure) => Left(failure),
      (ingredients) async =>
          await _inventoryService.addIngredients(ingredients),
    );
  }

  /// Disposes resources
  void dispose() {
    _ingredientDetectionService.dispose();
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

  const ImagePickFailure(this.message, Exception error) : super(message, error);
}
