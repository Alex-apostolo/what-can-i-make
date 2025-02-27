import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/openai_service.dart';
import '../services/storage_service.dart';

class ImagePickerScreen extends StatefulWidget {
  final StorageService storageService;

  const ImagePickerScreen({super.key, required this.storageService});

  @override
  State<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  late final OpenAIService _openAIService;

  @override
  void initState() {
    super.initState();
    _openAIService = OpenAIService();
  }

  @override
  void dispose() {
    _openAIService.dispose();
    super.dispose();
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(source: source);
      if (image == null || !context.mounted) return;

      _showLoadingDialog(context);

      final items = await _openAIService.analyzeKitchenInventory(image.path);
      await widget.storageService.addItems(items);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context, true); // Return to home screen with success
    } catch (e) {
      if (!context.mounted) return;

      // Close loading dialog if it's open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Dialog(
            backgroundColor: Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Analyzing Kitchen Items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please wait while we process your image...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
    );
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
}
