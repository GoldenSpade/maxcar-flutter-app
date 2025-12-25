/// Vehicle settings for fuel consumption calculation
class VehicleSettings {
  final double fuelConsumption; // L/100km
  final String fuelType; // e.g., "Petrol", "Diesel", "Gas"
  final double fuelPrice; // Price per liter
  final String currency; // e.g., "USD", "EUR", "UAH"

  VehicleSettings({
    required this.fuelConsumption,
    required this.fuelType,
    required this.fuelPrice,
    required this.currency,
  });

  /// Calculate fuel cost for a given distance
  /// distance in meters, returns cost in currency
  double calculateFuelCost(double distanceMeters) {
    if (distanceMeters <= 0) return 0.0;

    final distanceKm = distanceMeters / 1000;
    final fuelUsed = (distanceKm / 100) * fuelConsumption;
    final cost = fuelUsed * fuelPrice;

    return cost;
  }

  /// Calculate fuel used for a given distance
  /// distance in meters, returns liters
  double calculateFuelUsed(double distanceMeters) {
    if (distanceMeters <= 0) return 0.0;

    final distanceKm = distanceMeters / 1000;
    final fuelUsed = (distanceKm / 100) * fuelConsumption;

    return fuelUsed;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'fuel_consumption': fuelConsumption,
      'fuel_type': fuelType,
      'fuel_price': fuelPrice,
      'currency': currency,
    };
  }

  /// Create from JSON
  factory VehicleSettings.fromJson(Map<String, dynamic> json) {
    return VehicleSettings(
      fuelConsumption: (json['fuel_consumption'] as num).toDouble(),
      fuelType: json['fuel_type'] as String,
      fuelPrice: (json['fuel_price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
    );
  }

  VehicleSettings copyWith({
    double? fuelConsumption,
    String? fuelType,
    double? fuelPrice,
    String? currency,
  }) {
    return VehicleSettings(
      fuelConsumption: fuelConsumption ?? this.fuelConsumption,
      fuelType: fuelType ?? this.fuelType,
      fuelPrice: fuelPrice ?? this.fuelPrice,
      currency: currency ?? this.currency,
    );
  }

  /// Default settings
  static VehicleSettings get defaultSettings => VehicleSettings(
        fuelConsumption: 8.0, // 8L/100km
        fuelType: 'Petrol',
        fuelPrice: 1.5, // Default price per liter
        currency: 'USD',
      );
}
