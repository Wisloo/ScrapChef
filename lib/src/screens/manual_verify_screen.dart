import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';

// Earthy color palette for food scrap theme
const Color kPrimary = Color(0xFF8B7355); // Warm earth brown
const Color kPrimaryLight = Color(0xFFA89070); // Light earth brown
const Color kSecondary = Color(0xFF6B8E23); // Olive green
const Color kAccent = Color(0xFFD2691E); // Chocolate orange
const Color kBackground = Color(0xFFF5F0E6); // Creamy beige
const Color kSurface = Color(0xFFFFFFFF); // White
const Color kText = Color(0xFF4A3F35); // Dark earth brown
const Color kTextLight = Color(0xFF6B5D52); // Medium earth brown
const Color kDivider = Color(0xFFE0D5C5); // Light beige

// Dark theme colors (earthy dark mode)
const Color kDarkBackground = Color(0xFF2A2520); // Dark earth brown
const Color kDarkSurface = Color(0xFF3A3530); // Dark brown surface
const Color kDarkText = Color(0xFFE8E0D8); // Light cream text
const Color kDarkTextLight = Color(0xFFB8B0A8); // Medium cream text
const Color kDarkDivider = Color(0xFF4A4540); // Dark divider

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? kDarkBackground : kBackground;
    final cardColor = isDark ? kDarkSurface : kSurface;
    final textColor = isDark ? kDarkText : kText;

    final confidencePercent = (widget.confidence * 100).toInt();
    final isLowConfidence = widget.confidence < 0.7;

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
            'Verify Scrap',
            style: TextStyle(
              color: textColor,
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
                  gradient: isLowConfidence
                      ? LinearGradient(colors: [kAccent.withAlpha(20), kAccent.withAlpha(10)])
                      : LinearGradient(colors: [kSecondary.withAlpha(20), kSecondary.withAlpha(10)]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isLowConfidence
                        ? kAccent.withAlpha(50)
                        : kSecondary.withAlpha(50),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: textColor.withAlpha(15),
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
                                ? kAccent.withAlpha(30)
                                : kSecondary.withAlpha(30),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isLowConfidence
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_rounded,
                            color: isLowConfidence ? kAccent : kSecondary,
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
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$confidencePercent% match for ${widget.predictedLabel}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textColor.withAlpha(140),
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
                        color: textColor.withAlpha(160),
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
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: textColor.withAlpha(15),
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
                        color: textColor.withAlpha(140),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [kPrimary.withAlpha(15), kPrimaryLight.withAlpha(8)]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kPrimary.withAlpha(30)),
                      ),
                      child: Text(
                        widget.predictedLabel,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textColor,
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
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: textColor.withAlpha(15),
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
                        Text(
                          'Select Correct Type',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [kSecondary.withAlpha(30), kSecondary.withAlpha(15)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kSecondary.withAlpha(50)),
                          ),
                          child: Text(
                            '${widget.appState.supportedLabels.length} options',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kSecondary,
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
                              gradient: isSelected
                                  ? LinearGradient(colors: [kSecondary, kSecondary.withAlpha(200)])
                                  : null,
                              color: isSelected ? null : textColor.withAlpha(10),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? kSecondary
                                    : isOriginal
                                        ? kPrimary.withAlpha(50)
                                        : textColor.withAlpha(20),
                                width: isSelected || isOriginal ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: kSecondary.withAlpha(50),
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
                                    Icons.auto_awesome_rounded,
                                    size: 16,
                                    color: kPrimary.withAlpha(180),
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
                                        : textColor.withAlpha(
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
                    gradient: selectedLabel == null
                        ? null
                        : LinearGradient(colors: [kSecondary, kSecondary.withAlpha(200)]),
                    color: selectedLabel == null ? textColor.withAlpha(20) : null,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: selectedLabel == null
                        ? null
                        : [
                            BoxShadow(
                              color: kSecondary.withAlpha(60),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: selectedLabel == null
                            ? textColor.withAlpha(100)
                            : Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Confirm & Save',
                        style: TextStyle(
                          color: selectedLabel == null
                              ? textColor.withAlpha(100)
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
