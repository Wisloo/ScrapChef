import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:convert'; // Import for jsonDecode
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../state/app_state.dart';

// Modern color palette
const Color kPrimary = Color(0xFF6C5CE7);
const Color kPrimaryLight = Color(0xFFA29BFE);
const Color kSecondary = Color(0xFF00CEC9);
const Color kAccent = Color(0xFFFD79A8);
const Color kBackground = Color(0xFFF8F9FA);
const Color kSurface = Color(0xFFFFFFFF);
const Color kText = Color(0xFF2D3436);
const Color kTextLight = Color(0xFF636E72);
const Color kDivider = Color(0xFFDFE6E9);

// Dark theme colors
const Color kDarkBackground = Color(0xFF121212);
const Color kDarkSurface = Color(0xFF1E1E1E);
const Color kDarkText = Color(0xFFE0E0E0);
const Color kDarkTextLight = Color(0xFFB0B0B0);
const Color kDarkDivider = Color(0xFF2C2C2C);

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _batchMode = false;
  final List<String> _batchLabels = <String>[];

  Future<void> _pickFromCamera() async {
    HapticFeedback.mediumImpact();
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null && mounted) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _pickFromGallery() async {
    HapticFeedback.lightImpact();
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _showLabelSelector() async {
    if (_selectedImage == null) {
      return;
    }

    try {
      // Use the GeminiService to analyze the image
      final result = await widget.appState.classifierService.analyzeFoodScraps(
        _selectedImage!.path,
      );

      // Parse the JSON result from Gemini API (assuming it's always valid JSON)
      // This is a simplified approach; in a real app, you'd add robust error handling
      final Map<String, dynamic> jsonResult = jsonDecode(result);
      final List<dynamic> foodScraps = jsonResult["food_scraps"];

      if (foodScraps.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No food scraps detected.')),
          );
        }
        setState(() => _selectedImage = null);
        return;
      }

      // For simplicity, we'll take the first detected scrap as the main one
      // In a real app, you might present all options or let the user choose
      final String predictedLabel = foodScraps[0]["item"];
      final double confidence = 1.0; // Assuming Gemini provides high confidence

      if (_batchMode) {
        setState(() {
          _batchLabels.add(predictedLabel);
          _selectedImage = null;
        });
        HapticFeedback.mediumImpact();
      } else {
        // Show popup with classified result
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Food Scrap Detected'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.eco_rounded, size: 48, color: kSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'Detected: $predictedLabel',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.appState.handleAutoClassification(
                      predictedLabel,
                      confidence: confidence,
                    );
                    HapticFeedback.mediumImpact();
                    if (mounted) {
                      Navigator.of(context).pop(widget.appState.lastOutcome);
                    }
                  },
                  child: const Text('Continue'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Classification failed: $e')),
        );
      }
    }
  }

  Future<void> _showBatchPreview() async {
    final suggestions = widget.appState.suggestForLabels(_batchLabels);

    final commit = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BatchPreviewSheet(
        batchLabels: _batchLabels,
        suggestions: suggestions,
      ),
    );

    if (commit == true) {
      widget.appState.addBatchItems(List<String>.from(_batchLabels));
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop(widget.appState.lastOutcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? kDarkBackground : kBackground;
    final cardColor = isDark ? kDarkSurface : kSurface;
    final textColor = isDark ? kDarkText : kText;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: textColor.withAlpha(15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            _batchMode ? 'Batch Mode' : 'Scan Scrap',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: _batchMode
                  ? LinearGradient(colors: [kPrimary.withAlpha(30), kPrimaryLight.withAlpha(15)])
                  : null,
              color: _batchMode ? null : cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: textColor.withAlpha(15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _batchMode ? Icons.layers_rounded : Icons.layers_outlined,
                  key: ValueKey<bool>(_batchMode),
                  color: _batchMode ? kPrimary : textColor,
                ),
              ),
              tooltip: _batchMode ? 'Batch mode on' : 'Enable batch mode',
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _batchMode = !_batchMode);
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _selectedImage != null
            ? _ImagePreview(
                image: _selectedImage!,
                onRetake: () => setState(() => _selectedImage = null),
                onConfirm: _showLabelSelector,
              )
            : _CameraOptions(
                onCamera: _pickFromCamera,
                onGallery: _pickFromGallery,
                batchMode: _batchMode,
                batchCount: _batchLabels.length,
              ),
      ),
      floatingActionButton: _batchMode && _batchLabels.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [kSecondary, kSecondary.withAlpha(200)]),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: kSecondary.withAlpha(60),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: _showBatchPreview,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Done (${_batchLabels.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _CameraOptions extends StatelessWidget {
  const _CameraOptions({
    required this.onCamera,
    required this.onGallery,
    required this.batchMode,
    required this.batchCount,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final bool batchMode;
  final int batchCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? kDarkBackground : kBackground;
    final cardColor = isDark ? kDarkSurface : kSurface;
    final textColor = isDark ? kDarkText : kText;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            bgColor,
            kPrimary.withAlpha(10),
            bgColor,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Animated camera icon
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimary.withAlpha(20), kPrimaryLight.withAlpha(10)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: kPrimary.withAlpha(30), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withAlpha(40),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 60,
                  color: kPrimary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                batchMode ? 'Batch Scan Mode' : 'Capture Scrap',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                batchMode
                    ? 'Scan multiple items, then finish when done'
                    : 'Take a photo or pick from gallery to identify your food scrap',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: textColor.withAlpha(140),
                  height: 1.4,
                ),
              ),
              if (batchCount > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kSecondary.withAlpha(30), kSecondary.withAlpha(15)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kSecondary.withAlpha(50)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.layers_rounded, size: 16, color: kSecondary),
                      const SizedBox(width: 6),
                      Text(
                        '$batchCount items queued',
                        style: const TextStyle(
                          color: kSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              // Primary camera button
              GestureDetector(
                onTap: onCamera,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [kPrimary, kPrimaryLight]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withAlpha(50),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_rounded, color: Colors.white, size: 26),
                      SizedBox(width: 12),
                      Text(
                        'Take Photo',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Gallery button
              GestureDetector(
                onTap: onGallery,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: textColor.withAlpha(20)),
                    boxShadow: [
                      BoxShadow(
                        color: textColor.withAlpha(15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_rounded, color: textColor.withAlpha(180), size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Choose from Gallery',
                        style: TextStyle(
                          color: textColor.withAlpha(180),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Help text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: textColor.withAlpha(10),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: kSecondary),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Photos are processed locally on your device',
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor.withAlpha(140),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.image,
    required this.onRetake,
    required this.onConfirm,
  });

  final XFile image;
  final VoidCallback onRetake;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? kDarkSurface : kSurface;
    final textColor = isDark ? kDarkText : kText;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          File(image.path),
          fit: BoxFit.cover,
        ),
        // Guide overlay - corner brackets
        Center(
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              border: Border.all(
                color: kPrimary.withAlpha(150),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        // Corner brackets
        Positioned(
          top: MediaQuery.of(context).size.height / 2 - 150,
          left: MediaQuery.of(context).size.width / 2 - 150,
          child: _CornerBracket(position: CornerPosition.topLeft),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height / 2 - 150,
          right: MediaQuery.of(context).size.width / 2 - 150,
          child: _CornerBracket(position: CornerPosition.topRight),
        ),
        Positioned(
          bottom: MediaQuery.of(context).size.height / 2 - 150,
          left: MediaQuery.of(context).size.width / 2 - 150,
          child: _CornerBracket(position: CornerPosition.bottomLeft),
        ),
        Positioned(
          bottom: MediaQuery.of(context).size.height / 2 - 150,
          right: MediaQuery.of(context).size.width / 2 - 150,
          child: _CornerBracket(position: CornerPosition.bottomRight),
        ),
        // Center focus dot
        Center(
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withAlpha(200),
                width: 2,
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Top instruction
        Positioned(
          top: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: textColor.withAlpha(180),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.center_focus_strong_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Position scrap in center',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Gradient overlay at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 250,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  textColor.withAlpha(200),
                ],
              ),
            ),
          ),
        ),
        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardColor.withAlpha(240),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 18, color: kPrimary),
                        const SizedBox(width: 8),
                        Text(
                          'Confirm the scrap type',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onRetake,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: cardColor.withAlpha(230),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.refresh_rounded,
                                  color: textColor.withAlpha(200),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Retake',
                                  style: TextStyle(
                                    color: textColor.withAlpha(200),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: onConfirm,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [kSecondary, kSecondary.withAlpha(200)]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: kSecondary.withAlpha(60),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Use Photo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum CornerPosition { topLeft, topRight, bottomLeft, bottomRight }

class _CornerBracket extends StatelessWidget {
  const _CornerBracket({required this.position});

  final CornerPosition position;

  @override
  Widget build(BuildContext context) {
    const double size = 40;
    const double thickness = 4;
    const Color color = kPrimary;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerBracketPainter(
          position: position,
          color: color,
          thickness: thickness,
        ),
      ),
    );
  }
}

class _CornerBracketPainter extends CustomPainter {
  const _CornerBracketPainter({
    required this.position,
    required this.color,
    required this.thickness,
  });

  final CornerPosition position;
  final Color color;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    const double length = 30;

    switch (position) {
      case CornerPosition.topLeft:
        path.moveTo(0, length);
        path.lineTo(0, 0);
        path.lineTo(length, 0);
        break;
      case CornerPosition.topRight:
        path.moveTo(size.width - length, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, length);
        break;
      case CornerPosition.bottomLeft:
        path.moveTo(0, size.height - length);
        path.lineTo(0, size.height);
        path.lineTo(length, size.height);
        break;
      case CornerPosition.bottomRight:
        path.moveTo(size.width - length, size.height);
        path.lineTo(size.width, size.height);
        path.lineTo(size.width, size.height - length);
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LabelSelectorSheet extends StatefulWidget {
  const _LabelSelectorSheet({required this.labels});

  final List<String> labels;

  @override
  State<_LabelSelectorSheet> createState() => _LabelSelectorSheetState();
}

class _LabelSelectorSheetState extends State<_LabelSelectorSheet> {
  String? selectedLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? kDarkSurface : kSurface;
    final textColor = isDark ? kDarkText : kText;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: textColor.withAlpha(30),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textColor.withAlpha(60),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'What did you capture?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select the food scrap type',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: textColor.withAlpha(140),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: widget.labels.length,
                  itemBuilder: (context, index) {
                    final label = widget.labels[index];
                    final isSelected = selectedLabel == label;

                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedLabel = label);
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(colors: [kSecondary, kSecondary.withAlpha(200)])
                              : null,
                          color: isSelected ? null : textColor.withAlpha(10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? kSecondary : textColor.withAlpha(30),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : textColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: cardColor.withAlpha(230),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: textColor.withAlpha(20)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.close_rounded,
                              color: textColor.withAlpha(200),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Cancel',
                              style: TextStyle(
                                color: textColor.withAlpha(200),
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: selectedLabel != null
                          ? () {
                              Navigator.of(context).pop(selectedLabel);
                              HapticFeedback.mediumImpact();
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: selectedLabel != null
                              ? LinearGradient(colors: [kSecondary, kSecondary.withAlpha(200)])
                              : null,
                          color: selectedLabel != null ? null : cardColor.withAlpha(230),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selectedLabel != null ? kSecondary : textColor.withAlpha(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Confirm',
                              style: TextStyle(
                                color: selectedLabel != null ? Colors.white : textColor.withAlpha(200),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BatchPreviewSheet extends StatelessWidget {
  const _BatchPreviewSheet({
    required this.batchLabels,
    required this.suggestions,
  });

  final List<String> batchLabels;
  final List<dynamic> suggestions;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? kDarkSurface : kSurface;
    final textColor = isDark ? kDarkText : kText;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: textColor.withAlpha(30),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textColor.withAlpha(60),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kSecondary.withAlpha(30), kSecondary.withAlpha(15)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.layers_rounded, color: kSecondary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Batch Preview',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        Text(
                          '${batchLabels.length} items ready to save',
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor.withAlpha(140),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: batchLabels.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: textColor.withAlpha(10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: textColor.withAlpha(20)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: kSecondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              batchLabels[index],
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimary.withAlpha(15), kPrimaryLight.withAlpha(8)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kPrimary.withAlpha(30)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.restaurant_rounded,
                        size: 20,
                        color: kPrimary.withAlpha(200),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${suggestions.length} recipe ideas found!',
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor.withAlpha(160),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: textColor.withAlpha(10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: textColor.withAlpha(20)),
                        ),
                        child: Text(
                          'Continue',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor.withAlpha(180),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).pop(true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [kSecondary, kSecondary.withAlpha(200)]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: kSecondary.withAlpha(50),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Save All',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
