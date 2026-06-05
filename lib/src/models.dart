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
    this.id,
    required this.label,
    this.weightGrams,
    required this.loggedAt,
    required this.source,
    required this.confidence,
    this.manualCorrection = false,
  });

  final String? id;
  final String label;
  final double? weightGrams;  // Optional: user can add weight manually
  final DateTime loggedAt;
  final String source;  // 'camera', 'manual-entry', or 'manual-verification'
  final double confidence;
  final bool manualCorrection;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'weightGrams': weightGrams,
      'loggedAt': loggedAt.toIso8601String(),
      'source': source,
      'confidence': confidence,
      'manualCorrection': manualCorrection,
    };
  }

  factory ScrapItem.fromJson(Map<String, dynamic> json, {String? id}) {
    return ScrapItem(
      id: id ?? json['id'] as String?,
      label: json['label'] as String? ?? '',
      weightGrams: json['weightGrams'] as double?,
      loggedAt: DateTime.tryParse(json['loggedAt'] as String? ?? '') ?? DateTime.now(),
      source: json['source'] as String? ?? '',
      confidence: json['confidence'] as double? ?? 0.0,
      manualCorrection: json['manualCorrection'] as bool? ?? false,
    );
  }
}

class RecipeSuggestion {
  const RecipeSuggestion({
    this.id,
    required this.title,
    required this.summary,
    required this.ingredients,
    required this.matchReason,
    this.chefNote,
    this.imageUrl,
  });

  final String? id;
  final String title;
  final String summary;
  final List<String> ingredients;
  final String matchReason;
  final String? chefNote;  // Personal note from the app about this recipe
  final String? imageUrl;  // URL to recipe image

  String get stableId {
    final raw = (id ?? title).toLowerCase().trim();
    return raw.replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
  }
}

class SavedRecipeRecord {
  const SavedRecipeRecord({
    required this.recipeId,
    required this.title,
    required this.summary,
    required this.ingredients,
    required this.matchReason,
    required this.savedAt,
    this.chefNote,
    this.userNotes,
  });

  final String recipeId;
  final String title;
  final String summary;
  final List<String> ingredients;
  final String matchReason;
  final DateTime savedAt;
  final String? chefNote;
  final String? userNotes;

  SavedRecipeRecord copyWith({
    String? title,
    String? summary,
    List<String>? ingredients,
    String? matchReason,
    DateTime? savedAt,
    String? chefNote,
    String? userNotes,
  }) {
    return SavedRecipeRecord(
      recipeId: recipeId,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      ingredients: ingredients ?? this.ingredients,
      matchReason: matchReason ?? this.matchReason,
      savedAt: savedAt ?? this.savedAt,
      chefNote: chefNote ?? this.chefNote,
      userNotes: userNotes ?? this.userNotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipeId': recipeId,
      'title': title,
      'summary': summary,
      'ingredients': ingredients,
      'matchReason': matchReason,
      'savedAt': savedAt.toIso8601String(),
      'chefNote': chefNote,
      'userNotes': userNotes,
    };
  }

  factory SavedRecipeRecord.fromJson(Map<String, dynamic> json) {
    return SavedRecipeRecord(
      recipeId: json['recipeId'] as String,
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      ingredients: (json['ingredients'] as List<dynamic>? ?? const []).map((value) => value.toString()).toList(),
      matchReason: json['matchReason'] as String? ?? '',
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
      chefNote: json['chefNote'] as String?,
      userNotes: json['userNotes'] as String?,
    );
  }
}
