import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import 'recipe_detail_screen.dart';

// Food-inspired warm palette
const Color kRecipeWarmBrown = Color(0xFF8B7355);
const Color kCookingTerracotta = Color(0xFFC17A4A);
const Color kSketchCharcoal = Color(0xFF6B5D4F);
const Color kPaperCream = Color(0xFFFAF8F5);
const Color kHerbSage = Color(0xFFD4E5D0);
const Color kCaptionGray = Color(0xFF9A8B7E);

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({
    super.key,
    required this.appState,
    required this.labels,
    this.ragRecipes,
  });

  final AppState appState;
  final List<String> labels;
  final List<RecipeSuggestion>? ragRecipes;

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  List<RecipeSuggestion> recipes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    // Use RAG recipes if provided, otherwise fall back to label-based suggestions
    if (widget.ragRecipes != null) {
      if (mounted) {
        setState(() {
          recipes = widget.ragRecipes!;
          isLoading = false;
        });
      }
    } else {
      final loadedRecipes = await widget.appState.suggestForLabels(widget.labels);
      if (mounted) {
        setState(() {
          recipes = loadedRecipes;
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPaperCream,
      appBar: AppBar(
        backgroundColor: kPaperCream,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: kSketchCharcoal),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Recipe Ideas',
          style: TextStyle(
            color: kRecipeWarmBrown,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : recipes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu_outlined,
                          size: 64,
                          color: kCaptionGray,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No recipes found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: kSketchCharcoal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adding more scraps to your bin',
                          style: TextStyle(
                            fontSize: 14,
                            color: kCaptionGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: recipes
                      .map(
                        (recipe) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => RecipeDetailScreen(
                                    recipe: recipe,
                                    appState: widget.appState,
                                  ),
                                ),
                              );
                            },
                            child: _RecipeCard(recipe: recipe),
                          ),
                        ),
                      )
                      .toList(),
                ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe});

  final RecipeSuggestion recipe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color.fromRGBO(139, 115, 85, 0.15),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.06),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  recipe.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kRecipeWarmBrown,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(193, 122, 74, 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.restaurant_menu, size: 16, color: kCookingTerracotta),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recipe.summary,
            style: TextStyle(
              fontSize: 13,
              color: kSketchCharcoal,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
