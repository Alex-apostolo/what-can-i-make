import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/openai_service.dart';
import '../services/storage_service.dart';

class ImagePickerScreen extends StatelessWidget {
  final StorageService storageService;
  final OpenAIService _openAIService = OpenAIService();

  ImagePickerScreen({super.key, required this.storageService});

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null && context.mounted) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Analyzing kitchen items...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
        );

        try {
          // Analyze image and save items
          final items = await _openAIService.analyzeKitchenInventory(
            image.path,
          );
          await storageService.addItems(items);

          if (context.mounted) {
            Navigator.pop(context); // Close loading dialog
            Navigator.pop(context, true); // Return to home screen with success
          }
        } catch (e) {
          if (context.mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error analyzing image: ${e.toString()}')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Kitchen Items')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImage(context, ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take a Photo'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _pickImage(context, ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose from Gallery'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _openAIService.dispose();
  }
}
