/// Enum representing standardized measurement units for ingredients
enum MeasurementUnit {
  // Volume (Metric)
  ml('ml'),
  liter('L'),

  // Volume (Imperial)
  teaspoon('tsp'),
  tablespoon('tbsp'),
  fluidOunce('fl oz'),
  cup('cup'),
  pint('pt'),
  quart('qt'),
  gallon('gal'),

  // Weight (Metric)
  gram('g'),
  kilogram('kg'),

  // Weight (Imperial)
  ounce('oz'),
  pound('lb'),

  // Count/Whole
  piece('piece'),
  dozen('dozen'),
  pair('pair'),

  // Packaging
  can('can'),
  bottle('bottle'),
  box('box'),
  package('package'),
  bag('bag'),
  carton('carton'),
  container('container'),
  jar('jar'),
  tube('tube'),
  tin('tin'),
  bowl('bowl'),

  // Produce
  bunch('bunch'),
  head('head'),
  clove('clove'),
  sprig('sprig'),
  stalk('stalk'),
  slice('slice'),
  wedge('wedge'),

  // Default/Unknown
  unknown('Unknown');

  final String label;
  const MeasurementUnit(this.label);

  /// Get the display name of the unit (for UI)
  String get displayName => label;

  /// Get the plural form of the unit
  String get plural {
    switch (this) {
      case MeasurementUnit.liter:
        return 'L';
      case MeasurementUnit.teaspoon:
        return 'tsp';
      case MeasurementUnit.tablespoon:
        return 'tbsp';
      case MeasurementUnit.fluidOunce:
        return 'fl oz';
      case MeasurementUnit.pint:
        return 'pt';
      case MeasurementUnit.quart:
        return 'qt';
      case MeasurementUnit.gallon:
        return 'gal';
      case MeasurementUnit.gram:
        return 'g';
      case MeasurementUnit.kilogram:
        return 'kg';
      case MeasurementUnit.ounce:
        return 'oz';
      case MeasurementUnit.pound:
        return 'lb';
      case MeasurementUnit.ml:
        return 'ml';
      case MeasurementUnit.unknown:
        return 'Unknown';
      default:
        // Add 's' for regular plurals
        return '${label}s';
    }
  }

  /// Convert a string to a Unit enum value
  static MeasurementUnit fromString(String value) {
    // Normalize the input by trimming and converting to lowercase
    final normalized = value.trim().toLowerCase();

    // Check for exact matches with labels
    for (final unit in MeasurementUnit.values) {
      if (unit.label.toLowerCase() == normalized) {
        return unit;
      }
    }

    // Check for plural forms
    for (final unit in MeasurementUnit.values) {
      if (unit.plural.toLowerCase() == normalized) {
        return unit;
      }
    }

    // Handle special cases and common variations
    switch (normalized) {
      case 'milliliter':
      case 'milliliters':
      case 'millilitre':
      case 'millilitres':
        return MeasurementUnit.ml;
      case 'liter':
      case 'liters':
      case 'litre':
      case 'litres':
        return MeasurementUnit.liter;
      case 'teaspoon':
      case 'teaspoons':
        return MeasurementUnit.teaspoon;
      case 'tablespoon':
      case 'tablespoons':
        return MeasurementUnit.tablespoon;
      case 'fluid ounce':
      case 'fluid ounces':
      case 'fluid oz':
        return MeasurementUnit.fluidOunce;
      case 'cups':
        return MeasurementUnit.cup;
      case 'pint':
      case 'pints':
        return MeasurementUnit.pint;
      case 'quart':
      case 'quarts':
        return MeasurementUnit.quart;
      case 'gallon':
      case 'gallons':
        return MeasurementUnit.gallon;
      case 'gram':
      case 'grams':
        return MeasurementUnit.gram;
      case 'kilogram':
      case 'kilograms':
        return MeasurementUnit.kilogram;
      case 'ounce':
      case 'ounces':
        return MeasurementUnit.ounce;
      case 'pound':
      case 'pounds':
        return MeasurementUnit.pound;
      case 'pieces':
      case 'pcs':
      case 'pc':
        return MeasurementUnit.piece;
      case 'dozens':
        return MeasurementUnit.dozen;
      case 'pairs':
        return MeasurementUnit.pair;
      case 'cans':
        return MeasurementUnit.can;
      case 'bottles':
        return MeasurementUnit.bottle;
      case 'boxes':
        return MeasurementUnit.box;
      case 'packages':
      case 'pkg':
      case 'pkgs':
        return MeasurementUnit.package;
      case 'bags':
        return MeasurementUnit.bag;
      case 'cartons':
        return MeasurementUnit.carton;
      case 'containers':
        return MeasurementUnit.container;
      case 'jars':
        return MeasurementUnit.jar;
      case 'tubes':
        return MeasurementUnit.tube;
      case 'tins':
        return MeasurementUnit.tin;
      case 'bowls':
        return MeasurementUnit.bowl;
      case 'bunches':
        return MeasurementUnit.bunch;
      case 'heads':
        return MeasurementUnit.head;
      case 'cloves':
        return MeasurementUnit.clove;
      case 'sprigs':
        return MeasurementUnit.sprig;
      case 'stalks':
        return MeasurementUnit.stalk;
      case 'slices':
        return MeasurementUnit.slice;
      case 'wedges':
        return MeasurementUnit.wedge;
      default:
        return MeasurementUnit.unknown;
    }
  }
}
