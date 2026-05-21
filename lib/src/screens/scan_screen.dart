import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../constants/ui_constants.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isAnalyzing = false;

  Future<void> _pickFromCamera() async {
    HapticFeedback.mediumImpact();
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (image != null && mounted) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _pickFromGallery() async {
    HapticFeedback.lightImpact();
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (image != null && mounted) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _showAnalyzingDialog() {
      return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: UIConstants.kSecondary),
                const SizedBox(height: 20),
                Text(
                  'Analyzing scrap…',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

  String? _parseDetectedLabel(String result) {
    if (result.startsWith('Error:')) {
      return null;
    }
    if (result.contains('overloaded') || result.contains('not available')) {
      return null;
    }

    try {
      final jsonResult = jsonDecode(result) as Map<String, dynamic>;
      final foodScraps = jsonResult['food_scraps'];
      if (foodScraps is! List || foodScraps.isEmpty) {
        return null;
      }
      final first = foodScraps.first;
      if (first is! Map) {
        return null;
      }
      final item = first['item'];
      if (item is! String || item.trim().isEmpty) {
        return null;
      }
      return item.trim();
    } catch (_) {
      return null;
    }
  }

  Future<void> _showDetectionResultDialog(String predictedLabel) async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Food Scrap Detected',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Icon(Icons.eco_rounded, size: 48, color: UIConstants.kSecondary),
              const SizedBox(height: 16),
              Text(
                'Detected: $predictedLabel',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: UIConstants.kSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      widget.appState.handleAutoClassification(
        predictedLabel,
        confidence: 1.0,
      );
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(widget.appState.lastOutcome);
    }
  }

  Future<void> _offerManualFallback({String? errorMessage}) async {
    if (!mounted) return;

    final label = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManualLabelSheet(
        labels: widget.appState.supportedLabels,
        errorMessage: errorMessage ??
            'AI is currently unavailable. Please select manually.',
      ),
    );

    if (label != null && label.isNotEmpty && mounted) {
      widget.appState.handleAutoClassification(label, confidence: 1.0);
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(widget.appState.lastOutcome);
    }
  }

  Future<void> _showLabelSelector() async {
    if (_isAnalyzing || _selectedImage == null) {
      return;
    }

    _isAnalyzing = true;
    final imagePath = _selectedImage!.path;
    var loadingShown = false;

    if (mounted) {
      loadingShown = true;
      unawaited(_showAnalyzingDialog());
    }

    try {
      final result = await widget.appState.classifierService.analyzeFoodScraps(
        imagePath,
      );

      if (mounted && loadingShown) {
        Navigator.of(context, rootNavigator: true).pop();
        loadingShown = false;
      }

      if (!mounted) return;

      if (result.startsWith('Error:')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.replaceFirst('Error: ', ''))),
        );
        await _offerManualFallback(errorMessage: result.replaceFirst('Error: ', ''));
        return;
      }

      final predictedLabel = _parseDetectedLabel(result);
      if (predictedLabel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No food scraps detected. Try another photo.')),
        );
        setState(() => _selectedImage = null);
        return;
      }

      setState(() => _selectedImage = null);
      await _showDetectionResultDialog(predictedLabel);
    } catch (e) {
      if (mounted && loadingShown) {
        Navigator.of(context, rootNavigator: true).pop();
        loadingShown = false;
      }
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan failed: $e')),
      );
      await _offerManualFallback();
    } finally {
      _isAnalyzing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? UIConstants.kDarkBackground : UIConstants.kBackground;
    final cardColor = isDark ? UIConstants.kDarkSurface : UIConstants.kSurface;
    final textColor = isDark ? UIConstants.kDarkText : UIConstants.kText;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: UIConstants.kPrimary),
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
            'Scan Scrap',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _selectedImage != null
            ? _ImagePreview(
                image: _selectedImage!,
                onRetake: () => setState(() => _selectedImage = null),
                onConfirm: _isAnalyzing ? () {} : _showLabelSelector,
              )
            : _CameraOptions(
                onCamera: _pickFromCamera,
                onGallery: _pickFromGallery,
              ),
      ),
    );
  }
}

class _CameraOptions extends StatelessWidget {
  const _CameraOptions({
    required this.onCamera,
    required this.onGallery,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? UIConstants.kDarkBackground : UIConstants.kBackground;
    final cardColor = isDark ? UIConstants.kDarkSurface : UIConstants.kSurface;
    final textColor = isDark ? UIConstants.kDarkText : UIConstants.kText;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            bgColor,
            UIConstants.kPrimary.withAlpha(10),
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
                    colors: [UIConstants.kPrimary.withAlpha(20), UIConstants.kPrimaryLight.withAlpha(10)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: UIConstants.kPrimary.withAlpha(30), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: UIConstants.kPrimary.withAlpha(40),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 60,
                  color: UIConstants.kPrimary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Capture Scrap',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Take a photo or pick from gallery to identify your food scrap',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: textColor.withAlpha(140),
                  height: 1.4,
                ),
              ),
              const Spacer(),
              // Primary camera button
              GestureDetector(
                onTap: onCamera,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [UIConstants.kPrimary, UIConstants.kPrimaryLight]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: UIConstants.kPrimary.withAlpha(50),
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
                    const Icon(Icons.info_outline_rounded, size: 18, color: UIConstants.kSecondary),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Photos are analyzed securely with AI',
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
    final cardColor = isDark ? UIConstants.kDarkSurface : UIConstants.kSurface;
    final textColor = isDark ? UIConstants.kDarkText : UIConstants.kText;

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
                color: UIConstants.kPrimary.withAlpha(150),
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
                        const Icon(Icons.auto_awesome_rounded, size: 18, color: UIConstants.kPrimary),
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
                              gradient: LinearGradient(colors: [UIConstants.kSecondary, UIConstants.kSecondary.withAlpha(200)]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: UIConstants.kSecondary.withAlpha(60),
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
    const Color color = UIConstants.kPrimary;

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

class _ManualLabelSheet extends StatefulWidget {
  const _ManualLabelSheet({
    required this.labels,
    this.errorMessage,
  });

  final List<String> labels;
  final String? errorMessage;

  @override
  State<_ManualLabelSheet> createState() => _ManualLabelSheetState();
}

class _ManualLabelSheetState extends State<_ManualLabelSheet> {
  String? selectedLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? UIConstants.kDarkSurface : UIConstants.kSurface;
    final textColor = isDark ? UIConstants.kDarkText : UIConstants.kText;

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
              if (widget.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [UIConstants.kAccent.withAlpha(20), UIConstants.kAccent.withAlpha(10)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: UIConstants.kAccent.withAlpha(30)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_rounded, color: UIConstants.kAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.errorMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            color: textColor,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Select Food Scrap Type',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose from the list below',
                style: TextStyle(
                  fontSize: 14,
                  color: textColor.withAlpha(140),
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
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
                              ? LinearGradient(colors: [UIConstants.kSecondary, UIConstants.kSecondary.withAlpha(200)])
                              : null,
                          color: isSelected ? null : textColor.withAlpha(10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? UIConstants.kSecondary : textColor.withAlpha(30),
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
                              ? LinearGradient(colors: [UIConstants.kSecondary, UIConstants.kSecondary.withAlpha(200)])
                              : null,
                          color: selectedLabel != null ? null : cardColor.withAlpha(230),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selectedLabel != null ? UIConstants.kSecondary : textColor.withAlpha(20),
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
