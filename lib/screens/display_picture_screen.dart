import 'dart:io';
import 'package:flutter/material.dart';
import '../services/openai_service.dart';

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;

  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  final OpenAIService _openAIService = OpenAIService();
  String? _ingredients;
  bool _isLoading = false;

  Future<void> _analyzeImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _openAIService.analyzeImageIngredients(
        widget.imagePath,
      );
      setState(() {
        _ingredients = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _ingredients = 'Error analyzing image: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.file(File(widget.imagePath)),
            const SizedBox(height: 16),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_ingredients != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(_ingredients!),
              ),
            ElevatedButton(
              onPressed: _isLoading ? null : _analyzeImage,
              child: Text(
                _ingredients == null ? 'Analyze Ingredients' : 'Analyze Again',
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
