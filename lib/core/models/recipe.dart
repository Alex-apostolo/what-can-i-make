class Recipe {
  final String id;
  final String name;
  final List<String> ingredients;
  final String instructions;
  final String? imageUrl;
  final int prepTime; // in minutes
  
  Recipe({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.instructions,
    this.imageUrl,
    required this.prepTime,
  });
  
  // Factory constructor to create a Recipe from JSON
  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      name: json['name'],
      ingredients: List<String>.from(json['ingredients']),
      instructions: json['instructions'],
      imageUrl: json['imageUrl'],
      prepTime: json['prepTime'],
    );
  }
  
  // Convert Recipe to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ingredients': ingredients,
      'instructions': instructions,
      'imageUrl': imageUrl,
      'prepTime': prepTime,
    };
  }
} 