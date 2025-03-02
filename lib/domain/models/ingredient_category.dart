/// Enum representing ingredient categories for organization
enum IngredientCategory {
  vegetables('Vegetables', 1),
  fruits('Fruits', 2),
  grainsAndLegumes('Grains & Legumes', 3),
  meatAndSeafood('Meat & Seafood', 4),
  dairyAndEggs('Dairy & Eggs', 5),
  oilsAndFats('Oils & Fats', 6),
  nutsAndSeeds('Nuts & Seeds', 7),
  condimentsHerbsAndSpices('Condiments, Herbs & Spices', 8),
  sweetenersAndBaking('Sweeteners & Baking Essentials', 9),
  beverages('Beverages', 10),
  snacksAndDesserts('Snacks & Desserts', 11),
  preparedFoods('Prepared Foods', 12),
  frozen('Frozen Foods', 13),
  canned('Canned & Jarred Goods', 14),
  international('International Ingredients', 15),
  other('Other', 99);

  final String displayName;
  final int sortOrder;

  const IngredientCategory(this.displayName, this.sortOrder);

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
      case 'Nuts & Seeds':
        return IngredientCategory.nutsAndSeeds;
      case 'Sweeteners & Baking Essentials':
        return IngredientCategory.sweetenersAndBaking;
      case 'Condiments, Herbs & Spices':
        return IngredientCategory.condimentsHerbsAndSpices;
      case 'Beverages':
        return IngredientCategory.beverages;
      case 'Snacks & Desserts':
        return IngredientCategory.snacksAndDesserts;
      case 'Prepared Foods':
        return IngredientCategory.preparedFoods;
      case 'Frozen Foods':
        return IngredientCategory.frozen;
      case 'Canned & Jarred Goods':
        return IngredientCategory.canned;
      case 'International Ingredients':
        return IngredientCategory.international;
      default:
        return IngredientCategory.other;
    }
  }
}
