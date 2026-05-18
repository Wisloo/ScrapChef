import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/mock_real_classifier.dart';

class TestClassifierScreen extends StatefulWidget {
  const TestClassifierScreen({super.key});

  @override
  State<TestClassifierScreen> createState() => _TestClassifierScreenState();
}

class _TestClassifierScreenState extends State<TestClassifierScreen> {
  final MockRealClassifier _classifier = MockRealClassifier();
  bool _isInitializing = false;
  String? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeClassifier();
  }

  Future<void> _initializeClassifier() async {
    setState(() => _isInitializing = true);
    try {
      await _classifier.initialize();
      setState(() {
        _isInitializing = false;
        _result = 'Classifier initialized successfully!';
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _result = null;
        _error = 'Failed to initialize: $e';
      });
    }
  }

  Future<void> _testClassifier() async {
    try {
      // Test with a simple text file containing class names
      final result = await _classifier.classifyImage(File('assets/models/class_names_binary.txt'));
      setState(() {
        _result = 'Test completed: ${result.topPrediction.label} (${(result.topPrediction.confidence * 100).toStringAsFixed(1)}%)';
        _error = null;
      });
    } catch (e) {
      setState(() {
        _result = null;
        _error = 'Test failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Classifier Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isInitializing) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Initializing classifier...'),
              ] else ...[
                Text(
                  _result ?? _error ?? 'Ready to test',
                  style: TextStyle(
                    fontSize: 18,
                    color: _error != null ? Colors.red : Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _testClassifier,
                  child: const Text('Test Classification'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
