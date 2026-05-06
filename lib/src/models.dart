class ScanOutcome {
  const ScanOutcome({
    required this.predictedLabel,
    required this.confidence,
    required this.recommendedAction,
    required this.requiresReview,
    this.note,
  });

  final String predictedLabel;
  final double confidence;
  final String recommendedAction;
  final bool requiresReview;
  final String? note;
}

class ScrapItem {
  const ScrapItem({
    required this.label,
    this.weightGrams,
    required this.loggedAt,
    required this.source,
    required this.confidence,
    this.manualCorrection = false,
  });

  final String label;
  final double? weightGrams;  // Optional: user can add weight manually
  final DateTime loggedAt;
  final String source;  // 'camera', 'manual-entry', or 'manual-verification'
  final double confidence;
  final bool manualCorrection;
}

class RecipeSuggestion {
  const RecipeSuggestion({
    required this.title,
    required this.summary,
    required this.ingredients,
    required this.matchReason,
    this.chefNote,
  });

  final String title;
  final String summary;
  final List<String> ingredients;
  final String matchReason;
  final String? chefNote;  // Personal note from the app about this recipe
}
