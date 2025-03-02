import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  /// Get the icon for this category
  IconData get icon {
    switch (this) {
      case IngredientCategory.vegetables:
        return FontAwesomeIcons.carrot;
      case IngredientCategory.fruits:
        return FontAwesomeIcons.appleWhole;
      case IngredientCategory.grainsAndLegumes:
        return FontAwesomeIcons.wheatAwn;
      case IngredientCategory.meatAndSeafood:
        return FontAwesomeIcons.fish;
      case IngredientCategory.dairyAndEggs:
        return FontAwesomeIcons.cheese;
      case IngredientCategory.oilsAndFats:
        return FontAwesomeIcons.oilWell;
      case IngredientCategory.nutsAndSeeds:
        return FontAwesomeIcons.seedling;
      case IngredientCategory.condimentsHerbsAndSpices:
        return FontAwesomeIcons.pepperHot;
      case IngredientCategory.sweetenersAndBaking:
        return FontAwesomeIcons.cakeCandles;
      case IngredientCategory.beverages:
        return FontAwesomeIcons.wineGlass;
      case IngredientCategory.snacksAndDesserts:
        return FontAwesomeIcons.cookie;
      case IngredientCategory.preparedFoods:
        return FontAwesomeIcons.bowlFood;
      case IngredientCategory.frozen:
        return FontAwesomeIcons.snowflake;
      case IngredientCategory.canned:
        return FontAwesomeIcons.jarWheat;
      case IngredientCategory.international:
        return FontAwesomeIcons.earthAmericas;
      case IngredientCategory.other:
        return FontAwesomeIcons.ellipsis;
    }
  }

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
