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
  bool _isAnalyzing = false;
  List<KitchenItem> _kitchenItems = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    try {
      final items = await _openAIService.analyzeKitchenInventory(
        widget.imagePath,
      );
      setState(() {
        _kitchenItems = items;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to analyze image: ${e.toString()}';
        _isAnalyzing = false;
      });
    }
  }

  Widget _buildItemsList() {
    final ingredients =
        _kitchenItems.where((item) => item.category == 'ingredient').toList();
    final utensils =
        _kitchenItems.where((item) => item.category == 'utensil').toList();
    final equipment =
        _kitchenItems.where((item) => item.category == 'equipment').toList();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (ingredients.isNotEmpty) ...[
          _buildCategorySection('Ingredients', ingredients),
          const SizedBox(height: 16),
        ],
        if (utensils.isNotEmpty) ...[
          _buildCategorySection('Utensils', utensils),
          const SizedBox(height: 16),
        ],
        if (equipment.isNotEmpty) ...[
          _buildCategorySection('Equipment', equipment),
        ],
      ],
    );
  }

  Widget _buildCategorySection(String title, List<KitchenItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Card(
            child: ListTile(
              title: Text(item.name),
              subtitle:
                  item.quantity != null || item.notes != null
                      ? Text(
                        [
                          if (item.quantity != null)
                            'Quantity: ${item.quantity}',
                          if (item.notes != null) 'Notes: ${item.notes}',
                        ].join('\n'),
                      )
                      : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Inventory Analysis'),
        actions: [
          if (!_isAnalyzing)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _analyzeImage,
              tooltip: 'Reanalyze Image',
            ),
        ],
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
            ),
          ),
          Expanded(
            child:
                _isAnalyzing
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Analyzing kitchen inventory...'),
                        ],
                      ),
                    )
                    : _error != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    )
                    : _buildItemsList(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _openAIService.dispose();
    super.dispose();
  }
}
