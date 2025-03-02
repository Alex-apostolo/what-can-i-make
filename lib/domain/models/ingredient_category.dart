/// Enum representing ingredient categories for organization
enum IngredientCategory {
  vegetables('Vegetables'),
  fruits('Fruits'),
  grainsAndLegumes('Grains & Legumes'),
  meatAndSeafood('Meat & Seafood'),
  dairyAndEggs('Dairy & Eggs'),
  oilsAndFats('Oils & Fats'),
  sweetenersAndBaking('Sweeteners & Baking Essentials'),
  condimentsHerbsAndSpices('Condiments, Herbs & Spices'),
  other('Other');

  final String displayName;
  const IngredientCategory(this.displayName);

  /// Convert a string category name to the corresponding enum value
  static IngredientCategory fromString(String categoryName) {
    switch (categoryName) {
      case 'Vegetables':
        return IngredientCategory.vegetables;
      case 'Fruits':
        return IngredientCategory.fruits;
      case 'Grains & Legumes':
        return IngredientCategory.grainsAndLegumes;
      case 'Meat & Seafood':
        return IngredientCategory.meatAndSeafood;
      case 'Dairy & Eggs':
        return IngredientCategory.dairyAndEggs;
      case 'Oils & Fats':
        return IngredientCategory.oilsAndFats;
      case 'Sweeteners & Baking Essentials':
        return IngredientCategory.sweetenersAndBaking;
      case 'Condiments, Herbs & Spices':
        return IngredientCategory.condimentsHerbsAndSpices;
      default:
        return IngredientCategory.other;
    }
  }
}
