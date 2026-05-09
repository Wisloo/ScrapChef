import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'food_classifier.dart';

/// Example widget showing how to use the food classifier
class FoodRecognitionScreen extends StatefulWidget {
  const FoodRecognitionScreen({super.key});

  @override
  State<FoodRecognitionScreen> createState() => _FoodRecognitionScreenState();
}

class _FoodRecognitionScreenState extends State<FoodRecognitionScreen> {
  final FoodClassifier _classifier = FoodClassifier();
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = true;
  File? _selectedImage;
  ClassificationResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeClassifier();
  }

  Future<void> _initializeClassifier() async {
    try {
      await _classifier.initialize();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load model: $e';
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    setState(() {
      _selectedImage = File(picked.path);
      _result = null;
      _isLoading = true;
    });

    try {
      final result = await _classifier.classifyImage(_selectedImage!);
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Classification failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food Recognition')),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _selectedImage == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_selectedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_selectedImage!, height: 250, fit: BoxFit.cover),
            ),
          const SizedBox(height: 24),
          if (_isLoading)
            const CircularProgressIndicator()
          else if (_result != null)
            _buildResultCard(),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final top = _result!.topPrediction;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              top.label,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Confidence: ${top.displayConfidence}',
              style: TextStyle(
                color: _result!.isConfident ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!_result!.isConfident)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Low confidence - try a clearer photo',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
            const Divider(height: 24),
            const Text(
              'Other possibilities:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._result!.allPredictions.skip(1).map(
              (p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(p.label),
                    Text(p.displayConfidence, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _classifier.dispose();
    super.dispose();
  }
}
