import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/vehicle_settings.dart';

const String _settingsKey = 'vehicle_settings';

/// Vehicle settings provider
class VehicleSettingsNotifier extends StateNotifier<VehicleSettings> {
  VehicleSettingsNotifier() : super(VehicleSettings.defaultSettings) {
    loadSettings();
  }

  /// Load settings from SharedPreferences
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        final Map<String, dynamic> json = jsonDecode(settingsJson);
        state = VehicleSettings.fromJson(json);
      }
    } catch (e) {
      // If error, keep default settings
      state = VehicleSettings.defaultSettings;
    }
  }

  /// Save settings to SharedPreferences
  Future<void> saveSettings(VehicleSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings.toJson());
      await prefs.setString(_settingsKey, settingsJson);

      state = settings;
    } catch (e) {
      // Handle error
      throw Exception('Failed to save settings: ${e.toString()}');
    }
  }

  /// Update fuel consumption
  Future<void> updateFuelConsumption(double consumption) async {
    final newSettings = state.copyWith(fuelConsumption: consumption);
    await saveSettings(newSettings);
  }

  /// Update fuel type
  Future<void> updateFuelType(String type) async {
    final newSettings = state.copyWith(fuelType: type);
    await saveSettings(newSettings);
  }

  /// Update fuel price
  Future<void> updateFuelPrice(double price) async {
    final newSettings = state.copyWith(fuelPrice: price);
    await saveSettings(newSettings);
  }

  /// Reset to default settings
  Future<void> resetToDefault() async {
    await saveSettings(VehicleSettings.defaultSettings);
  }
}

/// Vehicle settings provider
final vehicleSettingsProvider =
    StateNotifierProvider<VehicleSettingsNotifier, VehicleSettings>((ref) {
  return VehicleSettingsNotifier();
});
