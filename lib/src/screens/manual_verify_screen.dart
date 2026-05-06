import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';

// Warm earthy solid color palette
const Color kCream = Color(0xFFFAF7F2);
const Color kTerracotta = Color(0xFFC17A4A);
const Color kSage = Color(0xFF7A9E7E);
const Color kDeepBrown = Color(0xFF3D2914);
const Color kCardBg = Colors.white;
const Color kLightSage = Color(0xFFE8F0E8);
const Color kLightTerracotta = Color(0xFFF5E6DC);

class ManualVerifyScreen extends StatefulWidget {
  const ManualVerifyScreen({
    super.key,
    required this.appState,
    required this.predictedLabel,
    required this.confidence,
  });

  final AppState appState;
  final String predictedLabel;
  final double confidence;

  @override
  State<ManualVerifyScreen> createState() => _ManualVerifyScreenState();
}

class _ManualVerifyScreenState extends State<ManualVerifyScreen> {
  String? selectedLabel;

  @override
  void initState() {
    super.initState();
    selectedLabel = widget.predictedLabel;
  }

  void _save() {
    if (selectedLabel == null) return;
    HapticFeedback.mediumImpact();
    widget.appState.confirmManualClassification(
      selectedLabel!,
      confidence: widget.confidence,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final confidencePercent = (widget.confidence * 100).toInt();
    final isLowConfidence = widget.confidence < 0.7;

    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        backgroundColor: kCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kDeepBrown),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kDeepBrown.withAlpha(15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Text(
            'Verify Scrap',
            style: TextStyle(
              color: kDeepBrown,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isLowConfidence ? kLightTerracotta : kLightSage,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isLowConfidence
                        ? kTerracotta.withAlpha(80)
                        : kSage.withAlpha(80),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kDeepBrown.withAlpha(15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isLowConfidence
                                ? kTerracotta.withAlpha(30)
                                : kSage.withAlpha(30),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isLowConfidence
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_rounded,
                            color: isLowConfidence ? kTerracotta : kSage,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isLowConfidence
                                    ? 'Low Confidence'
                                    : 'Review Prediction',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: kDeepBrown,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$confidencePercent% match for ${widget.predictedLabel}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: kDeepBrown.withAlpha(140),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isLowConfidence
                          ? 'The model is unsure about this classification. Please review and select the correct scrap type below.'
                          : 'Please verify that the prediction is correct before saving.',
                      style: TextStyle(
                        fontSize: 14,
                        color: kDeepBrown.withAlpha(160),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Predicted label card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kCardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: kDeepBrown.withAlpha(15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Predicted Label',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kDeepBrown.withAlpha(140),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: kLightTerracotta,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kTerracotta.withAlpha(100)),
                      ),
                      child: Text(
                        widget.predictedLabel,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: kDeepBrown,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Label selector
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kCardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: kDeepBrown.withAlpha(15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Correct Type',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kDeepBrown,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: kSage.withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kSage.withAlpha(80)),
                          ),
                          child: Text(
                            '${widget.appState.supportedLabels.length} options',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kSage,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: widget.appState.supportedLabels.map((label) {
                        final isSelected = selectedLabel == label;
                        final isOriginal = label == widget.predictedLabel;

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => selectedLabel = label);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? kSage : kCream,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? kSage
                                    : isOriginal
                                        ? kTerracotta.withAlpha(100)
                                        : kDeepBrown.withAlpha(30),
                                width: isSelected || isOriginal ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: kSage.withAlpha(50),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isOriginal && !isSelected) ...[
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 16,
                                    color: kTerracotta.withAlpha(180),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : kDeepBrown.withAlpha(
                                            isOriginal ? 200 : 170),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Save button
              GestureDetector(
                onTap: selectedLabel == null ? null : _save,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: selectedLabel == null
                        ? kDeepBrown.withAlpha(40)
                        : kSage,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: selectedLabel == null
                        ? null
                        : [
                            BoxShadow(
                              color: kSage.withAlpha(60),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check,
                        color: selectedLabel == null
                            ? kDeepBrown.withAlpha(100)
                            : Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Confirm & Save',
                        style: TextStyle(
                          color: selectedLabel == null
                              ? kDeepBrown.withAlpha(100)
                              : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
