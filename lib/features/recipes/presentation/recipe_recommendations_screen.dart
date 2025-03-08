import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:what_can_i_make/features/user/domain/request_limit_service.dart';
import 'package:what_can_i_make/features/inventory/domain/inventory_service.dart';
import 'package:what_can_i_make/features/recipes/domain/recipe_recommendation_service.dart';
import 'package:what_can_i_make/core/error/error_handler.dart';
import 'package:what_can_i_make/features/inventory/models/ingredient.dart';
import 'package:what_can_i_make/features/recipes/models/recipe.dart';

class RecipeRecommendationsScreen extends StatefulWidget {
  static const routeName = '/recipe_recommendations';

  const RecipeRecommendationsScreen({super.key});

  @override
  State<RecipeRecommendationsScreen> createState() =>
      _RecipeRecommendationsScreenState();
}

class _RecipeRecommendationsScreenState
    extends State<RecipeRecommendationsScreen> {
  late RecipeRecommendationService _recipeService;
  late InventoryService _inventoryService;
  late ErrorHandler _errorHandler;

  List<Ingredient> _availableIngredients = [];
  Set<String> _selectedIngredientIds = {};
  bool _strictMode = false;
  bool _isLoading = false;
  List<Recipe> _recommendedRecipes = [];

  @override
  void initState() {
    super.initState();

    // Initialize services from providers
    _errorHandler = context.read<ErrorHandler>();
    _inventoryService = context.read<InventoryService>();
    final requestLimitService = context.read<RequestLimitService>();
    _recipeService = RecipeRecommendationService(
      requestLimitService: requestLimitService,
    );
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    setState(() => _isLoading = true);
    final inventoryResult = await _inventoryService.getInventory();
    setState(() => _isLoading = false);

    final inventory = _errorHandler.handleFatalEither(
      inventoryResult,
      onRetry: _loadIngredients,
    );

    if (inventory != null) {
      inventory.forEach((e) {
        _selectedIngredientIds.add(e.id.toString());
      });

      setState(() {
        _availableIngredients = inventory;
      });
    }
  }

  Future<void> _generateRecommendations() async {
    setState(() => _isLoading = true);

    final selectedIngredients =
        _availableIngredients
            .where((i) => _selectedIngredientIds.contains(i.id))
            .toList();

    final recipes = _errorHandler.handleEither(
      await _recipeService.getRecommendedRecipes(
        availableIngredients: selectedIngredients,
        strictMode: _strictMode,
      ),
    );

    setState(() {
      _isLoading = false;
      if (recipes != null) {
        _recommendedRecipes = recipes;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Recommendations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateRecommendations,
            tooltip: 'Refresh recommendations',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ingredient selection section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select ingredients to use:',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  // Strict mode toggle
                  Row(
                    children: [
                      Checkbox(
                        value: _strictMode,
                        onChanged: (value) {
                          setState(() {
                            _strictMode = value ?? false;
                          });
                        },
                      ),
                      const Text('Only use selected ingredients'),
                    ],
                  ),

                  // Ingredient chips
                  SizedBox(
                    height: 160, // Fixed height for scrollable area
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _availableIngredients.map((ingredient) {
                              final isSelected = _selectedIngredientIds
                                  .contains(ingredient.id);
                              return FilterChip(
                                label: Text(ingredient.name),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedIngredientIds.add(ingredient.id);
                                    } else {
                                      _selectedIngredientIds.remove(
                                        ingredient.id,
                                      );
                                    }
                                  });
                                },
                                backgroundColor: colorScheme.surface,
                                selectedColor: colorScheme.primaryContainer,
                                checkmarkColor: colorScheme.primary,
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isLoading ? null : _generateRecommendations,
              child: Text('Find Recipes'),
            ),

            const SizedBox(height: 20),

            Expanded(
              child:
                  _isLoading
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Center(child: CircularProgressIndicator()),
                          const SizedBox(height: 16),
                          const Text('Loading recipes, please wait...'),
                        ],
                      )
                      : _recommendedRecipes.isEmpty
                      ? const Center(child: Text('No recipes to display'))
                      : ListView.builder(
                        itemCount: _recommendedRecipes.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final recipe = _recommendedRecipes[index];
                          return _RecipeCard(
                            recipe: recipe,
                            availableIngredients:
                                _availableIngredients
                                    .where(
                                      (i) =>
                                          _selectedIngredientIds.contains(i.id),
                                    )
                                    .map((i) => i.name.toLowerCase())
                                    .toSet(),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final Set<String> availableIngredients;

  const _RecipeCard({
    Key? key,
    required this.recipe,
    required this.availableIngredients,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recipe image
          if (recipe.imageUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                recipe.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: colorScheme.primaryContainer,
                    child: Center(
                      child: Icon(
                        Icons.restaurant,
                        size: 48,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recipe name and prep time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        recipe.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2, // Allow up to 2 lines
                        overflow:
                            TextOverflow.ellipsis, // Add ellipsis for overflow
                      ),
                    ),
                    Chip(
                      label: Text('${recipe.prepTime} min'),
                      avatar: const Icon(Icons.timer),
                      backgroundColor: colorScheme.surfaceVariant,
                      labelStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Ingredients
                Text(
                  'Ingredients:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      recipe.ingredients.map((ingredient) {
                        final isAvailable = availableIngredients.contains(
                          ingredient.toLowerCase(),
                        );
                        return Chip(
                          label: Text(ingredient),
                          backgroundColor:
                              isAvailable
                                  ? colorScheme.primaryContainer
                                  : colorScheme.errorContainer.withOpacity(0.3),
                          labelStyle: TextStyle(
                            color:
                                isAvailable
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onErrorContainer,
                          ),
                        );
                      }).toList(),
                ),

                const SizedBox(height: 16),

                // Instructions
                Text(
                  'Instructions:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(recipe.instructions),

                const SizedBox(height: 16),

                // View full recipe button
                Center(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('View Full Recipe'),
                    onPressed: () {
                      // Navigate to detailed recipe screen
                      // For now, just show a snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Viewing ${recipe.name} recipe'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
